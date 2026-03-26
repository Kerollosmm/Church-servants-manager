import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { randomBytes } from 'node:crypto';
import { adminAuth, adminDb } from './admin';
import {
  buildArchivedUserPatch,
  buildProvisionedUserProfile,
  buildRestoredUserPatch,
  parseCreateRequest,
  parseManagedUserRequest,
  parseRollbackRequest,
  type CreatePrivilegedUserRequest,
  type ManagedUserLifecycleRequest,
  type RollbackPrivilegedUserRequest,
  type UserRole,
} from './lifecycle_helpers';
const USERS_COLLECTION = 'users'; // FIX [009]: align Firestore path casing

async function requireAdmin(
  auth: { token?: Record<string, unknown>; uid?: string } | null | undefined,
): Promise<string> {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }

  if (auth?.token?.['role'] === 'admin') {
    return uid;
  }

  const userDoc = await adminDb.collection(USERS_COLLECTION).doc(uid).get();
  const role = userDoc.data()?.role;
  if (role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can provision users.');
  }
  return uid;
}

export const createPrivilegedUser = onCall<CreatePrivilegedUserRequest>(async (request) => {
  const createdBy = await requireAdmin(request.auth);
  const payload = parseCreateRequest(request.data);
  let createdUid: string | null = null;

  try {
    const userRecord = await adminAuth.createUser({
      email: payload.email,
      password: payload.password,
      displayName: payload.name,
      emailVerified: false,
    });
    createdUid = userRecord.uid;

    await adminAuth.setCustomUserClaims(userRecord.uid, { role: payload.role });

    await adminDb.collection(USERS_COLLECTION).doc(userRecord.uid).set(
      buildProvisionedUserProfile({
        uid: userRecord.uid,
        email: payload.email,
        name: payload.name,
        role: payload.role,
        createdBy,
      }),
      { merge: true },
    );

    return { uid: userRecord.uid };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('email address is already in use')) {
      throw new HttpsError('already-exists', 'The account already exists for that email.');
    }
    if (createdUid != null) {
      try {
        await adminAuth.deleteUser(createdUid);
      } catch (_) {
        // Best-effort rollback. The caller still receives the provisioning error.
      }
      try {
        await adminDb.collection(USERS_COLLECTION).doc(createdUid).delete();
      } catch (_) {
        // Best-effort rollback.
      }
    }
    throw new HttpsError('internal', 'Failed to provision privileged user.');
  }
});

export const rollbackPrivilegedUser = onCall<RollbackPrivilegedUserRequest>(async (request) => {
  await requireAdmin(request.auth);
  const payload = parseRollbackRequest(request.data);

  try {
    await adminAuth.deleteUser(payload.uid);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!message.includes('no user record')) {
      throw new HttpsError('internal', 'Failed to rollback privileged user.');
    }
  }

  await adminDb.collection(USERS_COLLECTION).doc(payload.uid).delete();
  return { uid: payload.uid };
});

export const archiveManagedUser = onCall<ManagedUserLifecycleRequest>(async (request) => {
  await requireAdmin(request.auth);
  const payload = parseManagedUserRequest(request.data);

  try {
    await adminAuth.updateUser(payload.uid, { disabled: true });
    await adminAuth.revokeRefreshTokens(payload.uid);
    await adminDb.collection(USERS_COLLECTION).doc(payload.uid).set(
      buildArchivedUserPatch(),
      { merge: true },
    );
    return { uid: payload.uid };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('no user record')) {
      throw new HttpsError('not-found', 'The user account could not be found.');
    }
    throw new HttpsError('internal', 'Failed to archive managed user.');
  }
});

export const restoreManagedUser = onCall<ManagedUserLifecycleRequest>(async (request) => {
  await requireAdmin(request.auth);
  const payload = parseManagedUserRequest(request.data);

  try {
    const temporaryPassword = randomBytes(24).toString('base64url');
    await adminAuth.updateUser(payload.uid, {
      disabled: false,
      password: temporaryPassword,
    });
    await adminAuth.revokeRefreshTokens(payload.uid);
    await adminDb.collection(USERS_COLLECTION).doc(payload.uid).set(
      buildRestoredUserPatch(),
      { merge: true },
    );
    return { uid: payload.uid };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('no user record')) {
      throw new HttpsError('not-found', 'The user account could not be found.');
    }
    throw new HttpsError('internal', 'Failed to restore managed user.');
  }
});
