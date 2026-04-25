import { onDocumentUpdated, onDocumentCreated } from 'firebase-functions/v2/firestore';
import { adminAuth } from '../admin';

/**
 * Triggers when a user document is created or updated in Firestore.
 * Syncs relevant fields to Firebase Auth Custom Claims for zero-cost RBAC.
 */
async function syncClaims(userId: string, data: any) {
  const claims = {
    role: data.role || 'none',
    isArchived: data.isArchived || false,
    assignedTeamIds: data.assignedTeamIds || [],
    assignedTeamId: data.assignedTeamId || null,
    groupId: data.groupId || null,
  };
  
  try {
    await adminAuth.setCustomUserClaims(userId, claims);
    console.log(`Successfully synced claims for user ${userId}:`, claims);
  } catch (error) {
    console.error(`Failed to sync claims for user ${userId}:`, error);
  }
}

/*
export const syncUserClaimsOnUpdate = onDocumentUpdated('Users/{userId}', async (event) => {
  const newData = event.data?.after.data();
  const oldData = event.data?.before.data();
  const userId = event.params.userId;

  if (!newData) return;

  const relevantFields = ['role', 'isArchived', 'assignedTeamIds', 'assignedTeamId', 'groupId'];
  const hasChanged = relevantFields.some(field => JSON.stringify(newData[field]) !== JSON.stringify(oldData?.[field]));

  if (hasChanged) {
    await syncClaims(userId, newData);
  }
});

export const syncUserClaimsOnCreate = onDocumentCreated('Users/{userId}', async (event) => {
  const data = event.data?.data();
  const userId = event.params.userId;

  if (!data) return;

  await syncClaims(userId, data);
});
*/
