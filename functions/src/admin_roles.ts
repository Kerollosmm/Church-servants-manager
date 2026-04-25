import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { adminAuth, adminDb } from "./admin";

export const assignRole = onCall(async (request) => {
  const caller = request.auth?.token;
  if (!caller || caller.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can assign roles.");
  }

  const { targetUid, newRole, assignedTeamIds } = request.data;
  
  if (!targetUid || typeof targetUid !== 'string') {
    throw new HttpsError("invalid-argument", "Missing or invalid targetUid.");
  }
  if (!newRole || typeof newRole !== 'string') {
    throw new HttpsError("invalid-argument", "Missing or invalid newRole.");
  }

  const safeTeams = Array.isArray(assignedTeamIds) ? assignedTeamIds : [];

  try {
    // 1. Fetch current claims and merge (Source of Truth)
    const userRecord = await adminAuth.getUser(targetUid);
    const currentClaims = userRecord.customClaims || {};
    const claims = { ...currentClaims, role: newRole, assignedTeamIds: safeTeams };
    await adminAuth.setCustomUserClaims(targetUid, claims);

    // 2. Write Audit Log
    await adminDb.collection("AuditLogs").add({
      action: "ROLE_ASSIGNMENT",
      actorUid: request.auth?.uid,
      targetUid,
      newRole,
      assignedTeamIds: safeTeams,
      timestamp: FieldValue.serverTimestamp(),
    });

    // 3. Update Display Document (Best Effort)
    await adminDb.collection("Users").doc(targetUid).update({
      role: newRole, // kept for display sync
      assignedTeamIds: safeTeams,
    });

    return { success: true };
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    throw new HttpsError("internal", `Failed to assign role: ${msg}`);
  }
});
