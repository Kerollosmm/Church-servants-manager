import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { adminAuth, adminDb } from './admin';

type UserRole = 'admin' | 'servant' | 'student';

type CreatePrivilegedUserRequest = {
  email?: string;
  password?: string;
  name?: string;
  role?: UserRole;
};

type RollbackPrivilegedUserRequest = {
  uid?: string;
};

const allowedRoles = new Set<UserRole>(['admin', 'servant', 'student']);

function requireAdmin(auth: { token?: Record<string, unknown>; uid?: string } | null): string {
  const uid = auth?.uid;
  const role = auth?.token?.['role'];
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  if (role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can provision users.');
  }
  return uid;
}

function parseCreateRequest(data: CreatePrivilegedUserRequest) {
  const email = data.email?.trim().toLowerCase();
  const password = data.password?.trim();
  const name = data.name?.trim();
  const role = data.role;

  if (!email || !password || !name || !role) {
    throw new HttpsError('invalid-argument', 'Missing provisioning fields.');
  }
  if (!allowedRoles.has(role)) {
    throw new HttpsError('invalid-argument', 'Invalid role for provisioning.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  return { email, password, name, role };
}

function parseRollbackRequest(data: RollbackPrivilegedUserRequest) {
  const uid = data.uid?.trim();
  if (!uid) {
    throw new HttpsError('invalid-argument', 'Missing uid for rollback.');
  }
  return { uid };
}

export const createPrivilegedUser = onCall<CreatePrivilegedUserRequest>(async (request) => {
  const createdBy = requireAdmin(request.auth);
  const payload = parseCreateRequest(request.data);

  try {
    const userRecord = await adminAuth.createUser({
      email: payload.email,
      password: payload.password,
      displayName: payload.name,
      emailVerified: false,
    });

    await adminDb.collection('users').doc(userRecord.uid).set(
      {
        uid: userRecord.uid,
        email: payload.email,
        name: payload.name,
        role: payload.role,
        isEmailVerified: false,
        provisionedBy: createdBy,
        updatedAt: new Date(),
      },
      { merge: true },
    );

    return { uid: userRecord.uid };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('email address is already in use')) {
      throw new HttpsError('already-exists', 'The account already exists for that email.');
    }
    throw new HttpsError('internal', 'Failed to provision privileged user.');
  }
});

export const rollbackPrivilegedUser = onCall<RollbackPrivilegedUserRequest>(async (request) => {
  requireAdmin(request.auth);
  const payload = parseRollbackRequest(request.data);

  try {
    await adminAuth.deleteUser(payload.uid);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!message.includes('no user record')) {
      throw new HttpsError('internal', 'Failed to rollback privileged user.');
    }
  }

  await adminDb.collection('users').doc(payload.uid).delete();
  return { uid: payload.uid };
});
