import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { adminDb } from '../admin';
import { FieldValue } from 'firebase-admin/firestore';

/**
 * Phase 7: Backend Automation (T019)
 * Triggered when an attendance session is closed.
 * Updates denormalized aggregates on Student and Class documents.
 */
export const onSessionClosed = onDocumentUpdated('Classes/{classId}/attendance_sessions/{sessionId}', async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  // Only trigger when isClosed changes from false/null to true
  if (beforeData?.isClosed === true || afterData?.isClosed !== true) {
    return;
  }

  const { classId, sessionId } = event.params;
  console.log(`Processing closed session ${sessionId} for class ${classId}`);

  try {
    // 1. Fetch all marks for this session
    const marksSnap = await adminDb
      .collection(`Classes/${classId}/attendance_sessions/${sessionId}/marks`)
      .get();

    if (marksSnap.empty) return;

    // 2. Update Student Aggregates
    const batch = adminDb.batch();

    for (const markDoc of marksSnap.docs) {
      const studentId = markDoc.id;
      const markData = markDoc.data();

      // Only increment if present/late
      if (markData.status === 'present' || markData.status === 'late') {
        const studentRef = adminDb.collection('Students').doc(studentId);
        batch.set(studentRef, {
          attendanceSummary: {
            totalPresent: FieldValue.increment(1),
            lastAttendanceDate: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    // 3. Update Group Aggregate
    const classRef = adminDb.collection('Classes').doc(classId);
    batch.set(classRef, {
      groupAttendanceSummary: {
        lastSessionDate: FieldValue.serverTimestamp(),
        lastSessionAttendanceCount: marksSnap.size,
        updatedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    await batch.commit();
    console.log(`Successfully updated aggregates for session ${sessionId}`);

  } catch (error) {
    console.error(`Error updating aggregates for session ${sessionId}:`, error);
  }
});
