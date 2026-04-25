// functions/src/backfill/migrate_claims.ts
// This is a one-time script intended to be run locally or via a secure HTTP trigger.
import { adminAuth, adminDb } from "../admin";

export async function runMigration() {
  const usersSnapshot = await adminDb.collection('Users').get();
  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    const claims = {
      role: data.role || 'student',
      isArchived: data.isArchived || false,
      assignedTeamIds: data.assignedTeamIds || [],
      assignedTeamId: data.assignedTeamId || null,
      groupId: data.groupId || null,
    };
    await adminAuth.setCustomUserClaims(doc.id, claims);
    console.log(`Migrated user ${doc.id}`);
  }
}
