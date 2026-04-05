import { HttpsError } from 'firebase-functions/v2/https';

export type UserRole = 'admin' | 'servant' | 'student';

export type CreatePrivilegedUserRequest = {
  email?: string;
  password?: string;
  name?: string;
  role?: UserRole;
};

export type RollbackPrivilegedUserRequest = {
  uid?: string;
};

export type ManagedUserLifecycleRequest = {
  uid?: string;
};

const allowedRoles = new Set<UserRole>(['admin', 'servant', 'student']);

export function parseCreateRequest(data: CreatePrivilegedUserRequest) {
  const email = data.email?.trim().toLowerCase();
  const password = data.password?.trim();
  const name = data.name?.trim();
  const role = data.role;

  if (!email || !password || !name || !role) {
    throw new HttpsError('invalid-argument', 'Missing provisioning fields.');
  }
  if (!email.includes('@') || !email.includes('.')) {
    throw new HttpsError('invalid-argument', 'Invalid email format.');
  }
  if (!allowedRoles.has(role)) {
    throw new HttpsError('invalid-argument', 'Invalid role for provisioning.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  return { email, password, name, role };
}

export function parseRollbackRequest(data: RollbackPrivilegedUserRequest) {
  const uid = data.uid?.trim();
  if (!uid) {
    throw new HttpsError('invalid-argument', 'Missing uid for rollback.');
  }
  return { uid };
}

export function parseManagedUserRequest(data: ManagedUserLifecycleRequest) {
  const uid = data.uid?.trim();
  if (!uid) {
    throw new HttpsError('invalid-argument', 'Missing managed user uid.');
  }
  return { uid };
}

export function buildProvisionedUserProfile(params: {
  uid: string;
  email: string;
  name: string;
  role: UserRole;
  createdBy: string;
}) {
  return {
    uid: params.uid,
    email: params.email,
    name: params.name,
    role: params.role,
    isEmailVerified: false,
    isArchived: false,
    restorePendingPasswordReset: false,
    provisionedBy: params.createdBy,
    updatedAt: new Date(),
  };
}

export function buildArchivedUserPatch() {
  return {
    isArchived: true,
    restorePendingPasswordReset: false,
    updatedAt: new Date(),
  };
}

export function buildRestoredUserPatch() {
  return {
    isArchived: false,
    restorePendingPasswordReset: true,
    updatedAt: new Date(),
  };
}

// ─── Student Provisioning ────────────────────────────────────────

export type CreateStudentUserRequest = {
  email?: string;
  password?: string;
  name?: string;
  group?: string;
  classId?: string;
  phone?: string;
};

const allowedGroups = new Set(['year1', 'year2', 'year3']);

export function parseStudentCreateRequest(data: CreateStudentUserRequest) {
  const email = data.email?.trim().toLowerCase();
  const password = data.password?.trim();
  const name = data.name?.trim();
  const group = data.group?.trim();
  const classId = data.classId?.trim();
  const phone = data.phone?.trim();

  if (!email || !password || !name) {
    throw new HttpsError('invalid-argument', 'Missing required fields: email, password, and name are required.');
  }
  if (!email.includes('@') || !email.includes('.')) {
    throw new HttpsError('invalid-argument', 'Invalid email format.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  if (group && !allowedGroups.has(group)) {
    throw new HttpsError('invalid-argument', `Invalid group. Allowed: ${[...allowedGroups].join(', ')}`);
  }

  return { email, password, name, group: group || null, classId: classId || null, phone: phone || null };
}

export function buildStudentProfile(params: {
  uid: string;
  name: string;
  email: string;
  group: string | null;
  classId: string | null;
  phone: string | null;
}) {
  const doc: Record<string, unknown> = {
    uid: params.uid,
    name: params.name,
    email: params.email,
    group: params.group ?? null,
    classId: params.classId ?? null,
    phone: params.phone ?? null,
    isArchived: false,
    role: 'student',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  return doc;
}

// ─── Safe Delete Helpers ─────────────────────────────────────────

export async function deleteAuthUserIfExists(
  adminAuth: { deleteUser: (uid: string) => Promise<void> },
  uid: string,
): Promise<{ success: boolean; error: string | null }> {
  try {
    await adminAuth.deleteUser(uid);
    return { success: true, error: null };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('no user record')) {
      return { success: true, error: null };
    }
    return { success: false, error: message };
  }
}

export async function deleteDocIfExists(
  adminDb: { collection: (name: string) => { doc: (id: string) => { delete: () => Promise<unknown> } } },
  collection: string,
  docId: string,
): Promise<{ success: boolean; error: string | null }> {
  try {
    await adminDb.collection(collection).doc(docId).delete();
    return { success: true, error: null };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, error: message };
  }
}
