import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { adminAuth, adminDb } from "./admin";

export const assignRole = onCall(async (request) => {
  const caller = request.auth?.token;
  if (!caller || caller.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can assign roles.");
  }

  const { targetUid, newRole, teams } = request.data;
  const safeTeams = teams || [];

  // 1. Set Custom Claims (Source of Truth)
  const claims = { role: newRole, teams: safeTeams };
  await adminAuth.setCustomUserClaims(targetUid, claims);

  // 2. Write Audit Log
  await adminDb.collection("AuditLogs").add({
    action: "ROLE_ASSIGNMENT",
    actorUid: request.auth?.uid,
    targetUid,
    newRole,
    teams: safeTeams,
    timestamp: FieldValue.serverTimestamp(),
  });

  // 3. Update Display Document (Best Effort)
  await adminDb.collection("Users").doc(targetUid).update({
    role: newRole, // kept for display sync
    assignedTeamIds: safeTeams,
  });

  return { success: true };
});
