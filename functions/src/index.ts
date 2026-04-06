import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { randomBytes } from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { adminAuth, adminDb } from './admin';
import {
  buildArchivedUserPatch,
  buildProvisionedUserProfile,
  buildRestoredUserPatch,
  buildStudentProfile,
  deleteAuthUserIfExists,
  deleteDocIfExists,
  parseCreateRequest,
  parseManagedUserRequest,
  parseRollbackRequest,
  parseStudentCreateRequest,
  type CreatePrivilegedUserRequest,
  type ManagedUserLifecycleRequest,
  type RollbackPrivilegedUserRequest,
  type UserRole,
} from './lifecycle_helpers';
import { writeAuditLog } from './audit';

const USERS_COLLECTION = 'Users';
const STUDENTS_COLLECTION = 'Students';
const ROLLBACK_LOGS_COLLECTION = 'RollbackLogs';

async function requireAdmin(
  auth: { token?: Record<string, unknown>; uid?: string } | null | undefined,
): Promise<string> {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }

  // Fast path: use custom claim (no Firestore read)
  if (auth?.token?.role === 'admin' && auth?.token?.isArchived !== true) {
    return uid;
  }

  // Slow path: verify from Firestore only when claim missing/stale
  const userDoc = await adminDb.collection(USERS_COLLECTION).doc(uid).get();
  const userData = userDoc.data();
  if (userData?.isArchived === true) {
    throw new HttpsError('permission-denied', 'This account has been archived.');
  }
  if (userData?.role !== 'admin') {
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

    await writeAuditLog({
      action: 'createPrivilegedUser',
      actorUid: createdBy,
      targetUid: userRecord.uid,
      details: { role: payload.role, email: payload.email },
    });

    return { uid: userRecord.uid };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('email address is already in use')) {
      throw new HttpsError('already-exists', 'The account already exists for that email.');
    }

    // Idempotent multi-step rollback using safe-delete helpers
    const rollbackErrors: { step: string; error: string }[] = [];

    if (createdUid != null) {
      const authResult = await deleteAuthUserIfExists(adminAuth, createdUid);
      if (!authResult.success) {
        rollbackErrors.push({ step: 'deleteAuthUser', error: authResult.error! });
      }

      const usersResult = await deleteDocIfExists(adminDb, USERS_COLLECTION, createdUid);
      if (!usersResult.success) {
        rollbackErrors.push({ step: 'deleteUsersDoc', error: usersResult.error! });
      }
    }

    await adminDb.collection(ROLLBACK_LOGS_COLLECTION).add({
      originalAction: 'createPrivilegedUser',
      actorUid: createdBy,
      targetUid: createdUid,
      originalError: message,
      rollbackSteps: rollbackErrors.length === 0
        ? [{ step: 'all', status: 'success' }]
        : rollbackErrors.map((e) => ({ step: e.step, status: 'failed', error: e.error })),
      timestamp: new Date(),
    });

    if (rollbackErrors.length > 0) {
      throw new HttpsError(
        'internal',
        `Failed to provision privileged user and rollback was incomplete: ${rollbackErrors.map((e) => `${e.step}: ${e.error}`).join('; ')}`,
      );
    }

    throw new HttpsError('internal', 'Failed to provision privileged user. Rollback completed successfully.');
  }
});

export const rollbackPrivilegedUser = onCall<RollbackPrivilegedUserRequest>(async (request) => {
  const actorUid = await requireAdmin(request.auth);
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

  await writeAuditLog({
    action: 'rollbackPrivilegedUser',
    actorUid,
    targetUid: payload.uid,
  });

  return { uid: payload.uid };
});

export const archiveManagedUser = onCall<ManagedUserLifecycleRequest>(async (request) => {
  const actorUid = await requireAdmin(request.auth);
  const payload = parseManagedUserRequest(request.data);

  try {
    // Read target user to check role
    const targetDoc = await adminDb.collection(USERS_COLLECTION).doc(payload.uid).get();
    if (!targetDoc.exists) {
      throw new HttpsError('not-found', 'The user account could not be found.');
    }
    const targetData = targetDoc.data()!;
    const role = targetData['role'] as string;

    await adminDb.runTransaction(async (tx) => {
      const userRef = adminDb.collection(USERS_COLLECTION).doc(payload.uid);

      if (role === 'servant') {
        const teamsSnapshot = await tx.get(
          adminDb.collection('Classes').where('assignedServantId', '==', payload.uid),
        );

        for (const teamDoc of teamsSnapshot.docs) {
          tx.update(teamDoc.ref, {
            assignedServantId: FieldValue.delete(),
            assignedServantName: FieldValue.delete(),
            updatedAt: new Date(),
          });
        }

        tx.update(userRef, {
          ...buildArchivedUserPatch(),
          assignedTeamIds: FieldValue.delete(),
          assignedTeamId: FieldValue.delete(),
        });
      } else {
        tx.set(userRef, buildArchivedUserPatch(), { merge: true });
      }

      if (role === 'student' || role === 'servant') {
        const studentSnap = await tx.get(
          adminDb.collection(STUDENTS_COLLECTION).where('uid', '==', payload.uid).limit(1),
        );

        if (!studentSnap.empty) {
          tx.update(studentSnap.docs[0].ref, {
            isArchived: true,
            updatedAt: new Date(),
          });
        }
      }
    });

    // 2. Auth updates AFTER Firestore succeeds
    await adminAuth.updateUser(payload.uid, { disabled: true });
    await adminAuth.revokeRefreshTokens(payload.uid);

    await writeAuditLog({
      action: 'archiveManagedUser',
      actorUid,
      targetUid: payload.uid,
      details: { role },
    });

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
  const actorUid = await requireAdmin(request.auth);
  const payload = parseManagedUserRequest(request.data);

  try {
    // Read target user to get email
    const targetDoc = await adminDb.collection(USERS_COLLECTION).doc(payload.uid).get();
    if (!targetDoc.exists) {
      throw new HttpsError('not-found', 'The user account could not be found.');
    }
    const targetData = targetDoc.data()!;
    const email = targetData['email'] as string;

    const temporaryPassword = randomBytes(24).toString('base64url');
    await adminAuth.updateUser(payload.uid, {
      disabled: false,
      password: temporaryPassword,
    });
    await adminAuth.revokeRefreshTokens(payload.uid);

    // Generate password reset link for the restored user
    const resetLink = await adminAuth.generatePasswordResetLink(email);

    const userRef = adminDb.collection(USERS_COLLECTION).doc(payload.uid);
    const batch = adminDb.batch();

    batch.set(userRef, buildRestoredUserPatch(), { merge: true });

    const studentSnap = await adminDb.collection(STUDENTS_COLLECTION)
      .where('uid', '==', payload.uid)
      .limit(1)
      .get();

    if (!studentSnap.empty) {
      batch.update(studentSnap.docs[0].ref, {
        isArchived: false,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await writeAuditLog({
      action: 'restoreManagedUser',
      actorUid,
      targetUid: payload.uid,
      details: { email, resetLinkGenerated: true },
    });

    return { uid: payload.uid, resetLink };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('no user record')) {
      throw new HttpsError('not-found', 'The user account could not be found.');
    }
    throw new HttpsError('internal', 'Failed to restore managed user.');
  }
});

// ─── Student Provisioning ────────────────────────────────────────

export const createStudentUser = onCall(async (request) => {
  const createdBy = await requireAdmin(request.auth);
  const payload = parseStudentCreateRequest(request.data);
  let createdUid: string | null = null;
  let createdStudentDocId: string | null = null;

  try {
    const userRecord = await adminAuth.createUser({
      email: payload.email,
      password: payload.password,
      displayName: payload.name,
      emailVerified: false,
    });
    createdUid = userRecord.uid;

    await adminAuth.setCustomUserClaims(userRecord.uid, { role: 'student' });

    await adminDb.collection(USERS_COLLECTION).doc(userRecord.uid).set(
      buildProvisionedUserProfile({
        uid: userRecord.uid,
        email: payload.email,
        name: payload.name,
        role: 'student',
        createdBy,
      }),
      { merge: true },
    );

    const studentDoc = adminDb.collection(STUDENTS_COLLECTION).doc();
    createdStudentDocId = studentDoc.id;

    await studentDoc.set(
      buildStudentProfile({
        uid: userRecord.uid,
        name: payload.name,
        email: payload.email,
        group: payload.group,
        classId: payload.classId,
        phone: payload.phone,
      }),
    );

    await writeAuditLog({
      action: 'createStudentUser',
      actorUid: createdBy,
      targetUid: userRecord.uid,
      details: { studentDocId: createdStudentDocId, group: payload.group, classId: payload.classId },
    });

    return { uid: userRecord.uid, studentDocId: createdStudentDocId };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes('email address is already in use')) {
      throw new HttpsError('already-exists', 'The account already exists for that email.');
    }

    // Idempotent multi-step rollback
    const rollbackErrors: { step: string; error: string }[] = [];

    if (createdUid != null) {
      const authResult = await deleteAuthUserIfExists(adminAuth, createdUid);
      if (!authResult.success) {
        rollbackErrors.push({ step: 'deleteAuthUser', error: authResult.error! });
      }
    }

    if (createdUid != null) {
      const usersResult = await deleteDocIfExists(adminDb, USERS_COLLECTION, createdUid);
      if (!usersResult.success) {
        rollbackErrors.push({ step: 'deleteUsersDoc', error: usersResult.error! });
      }
    }

    if (createdStudentDocId != null) {
      const studentsResult = await deleteDocIfExists(adminDb, STUDENTS_COLLECTION, createdStudentDocId);
      if (!studentsResult.success) {
        rollbackErrors.push({ step: 'deleteStudentsDoc', error: studentsResult.error! });
      }
    }

    // Write rollback log
    await adminDb.collection(ROLLBACK_LOGS_COLLECTION).add({
      originalAction: 'createStudentUser',
      actorUid: createdBy,
      targetUid: createdUid,
      studentDocId: createdStudentDocId,
      originalError: message,
      rollbackSteps: rollbackErrors.length === 0
        ? [{ step: 'all', status: 'success' }]
        : rollbackErrors.map((e) => ({ step: e.step, status: 'failed', error: e.error })),
      timestamp: new Date(),
    });

    if (rollbackErrors.length > 0) {
      throw new HttpsError(
        'internal',
        `Failed to create student user and rollback was incomplete: ${rollbackErrors.map((e) => `${e.step}: ${e.error}`).join('; ')}`,
      );
    }

    throw new HttpsError('internal', 'Failed to create student user. Rollback completed successfully.');
  }
});

// ─── Role Change ─────────────────────────────────────────────────

type ChangeUserRoleRequest = {
  targetUid?: string;
  newRole?: UserRole;
};

function parseChangeRoleRequest(data: ChangeUserRoleRequest) {
  const targetUid = data.targetUid?.trim();
  const newRole = data.newRole;

  if (!targetUid) {
    throw new HttpsError('invalid-argument', 'Missing targetUid.');
  }
  if (!newRole) {
    throw new HttpsError('invalid-argument', 'Missing newRole.');
  }

  const allowedRoles = new Set<UserRole>(['admin', 'servant', 'student']);
  if (!allowedRoles.has(newRole)) {
    throw new HttpsError('invalid-argument', `Invalid role. Allowed: admin, servant, student.`);
  }

  return { targetUid, newRole };
}

export const changeUserRole = onCall<ChangeUserRoleRequest>(async (request) => {
  const actorUid = await requireAdmin(request.auth);
  const { targetUid, newRole } = parseChangeRoleRequest(request.data);

  if (targetUid === actorUid) {
    throw new HttpsError('invalid-argument', 'Cannot change your own role.');
  }

  // Use a transaction so reads and writes are atomic (fixes TOCTOU race).
  const result = await adminDb.runTransaction(async (tx) => {
    const targetDoc = await tx.get(adminDb.collection(USERS_COLLECTION).doc(targetUid));
    if (!targetDoc.exists) {
      throw new HttpsError('not-found', 'Target user not found.');
    }
    const targetData = targetDoc.data()!;
    if (targetData.isArchived === true) {
      throw new HttpsError('permission-denied', 'Cannot change role of an archived user.');
    }

    const oldRole = targetData.role as UserRole;
    const targetRef = adminDb.collection(USERS_COLLECTION).doc(targetUid);

    tx.update(targetRef, {
      role: newRole,
      updatedAt: new Date(),
    });

    if (oldRole === 'servant' && newRole !== 'servant') {
      tx.update(targetRef, {
        assignedTeamIds: null,
        assignedTeamId: null,
        groupId: null,
      });
    }

    if (oldRole !== 'servant' && newRole === 'servant') {
      tx.update(targetRef, {
        assignedTeamIds: [],
      });
    }

    if (newRole === 'student') {
      const studentDocRef = adminDb.collection(STUDENTS_COLLECTION).doc(targetUid);
      const existingStudentSnap = await tx.get(studentDocRef);

      if (!existingStudentSnap.exists) {
        const newStudentDoc = adminDb.collection(STUDENTS_COLLECTION).doc();
        tx.set(newStudentDoc, {
          uid: targetUid,
          name: targetData.name ?? '',
          email: targetData.email ?? '',
          group: targetData.groupId ?? null,
          classId: targetData.assignedTeamId ?? null,
          phone: null,
          isArchived: false,
          role: 'student',
          createdAt: new Date(),
          updatedAt: new Date(),
        });
      } else {
        tx.update(existingStudentSnap.ref, {
          isArchived: false,
          updatedAt: new Date(),
        });
      }
    }

    if (oldRole === 'student' && newRole !== 'student') {
      const studentDocRef = adminDb.collection(STUDENTS_COLLECTION).doc(targetUid);
      const studentDocsSnap = await tx.get(studentDocRef);

      if (studentDocsSnap.exists) {
        tx.update(studentDocsSnap.ref, {
          isArchived: true,
          updatedAt: new Date(),
        });
      }
    }

    return { oldRole, newRole };
  });

  // setCustomUserClaims AFTER transaction commits (fixes inconsistency if batch fails).
  // Retry with backoff in case of transient Auth errors.
  let claimsSet = false;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      await adminAuth.setCustomUserClaims(targetUid, { role: result.newRole });
      claimsSet = true;
      break;
    } catch (claimsError) {
      const msg = claimsError instanceof Error ? claimsError.message : String(claimsError);
      console.warn(
        `changeUserRole: setCustomUserClaims attempt ${attempt} failed for ${targetUid}: ${msg}`,
      );
      if (attempt < 3) {
        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
      }
    }
  }

  if (!claimsSet) {
    const errMsg = `CRITICAL: changeUserRole failed to set claims for ${targetUid} (newRole=${result.newRole}). ` +
      `Firestore was updated but Auth claims were not. Manual reconciliation required.`;
    console.error(errMsg);
    throw new HttpsError(
      'internal',
      `Failed to sync user permissions (claimsSet=false). Target: ${targetUid}, Role: ${result.newRole}. Reconciliation required.`,
    );
  }

  await writeAuditLog({
    action: 'changeUserRole',
    actorUid,
    targetUid,
    details: { oldRole: result.oldRole, newRole: result.newRole },
  });

  return { uid: targetUid, oldRole: result.oldRole, newRole: result.newRole };
});
