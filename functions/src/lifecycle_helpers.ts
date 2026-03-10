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
