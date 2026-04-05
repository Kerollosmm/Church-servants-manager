import { FieldValue } from 'firebase-admin/firestore';
import { adminDb } from './admin';

const AUDIT_LOGS_COLLECTION = 'audit_logs';

export type AuditAction =
  | 'createPrivilegedUser'
  | 'rollbackPrivilegedUser'
  | 'archiveManagedUser'
  | 'restoreManagedUser'
  | 'createStudentUser'
  | 'changeUserRole';

export async function writeAuditLog(params: {
  action: AuditAction;
  actorUid: string;
  targetUid?: string;
  details?: Record<string, unknown>;
}): Promise<void> {
  await adminDb.collection(AUDIT_LOGS_COLLECTION).add({
    action: params.action,
    actorUid: params.actorUid,
    targetUid: params.targetUid || null,
    details: params.details || null,
    timestamp: FieldValue.serverTimestamp(),
  });
}
