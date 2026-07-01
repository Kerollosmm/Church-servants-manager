import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('Starting student attendance history backfill script...');

  try {
    // Initialize Firebase. Assumes DefaultFirebaseOptions or initialized environment.
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;

    final sessionsSnapshot = await firestore
        .collection('attendance')
        .where('isClosed', isEqualTo: true)
        .get();

    print('Found ${sessionsSnapshot.docs.length} closed sessions.');

    int totalWrites = 0;
    for (final sessionDoc in sessionsSnapshot.docs) {
      final sessionId = sessionDoc.id;
      final data = sessionDoc.data();
      final teamId = data['teamId'] as String?;
      final studentIdsSnapshot = List<String>.from(
        data['studentIdsSnapshot'] ?? [],
      );
      final studentNameSnapshots = Map<String, String>.from(
        data['studentNameSnapshots'] ?? {},
      );
      final startsAtTimestamp = data['startsAt'] as Timestamp?;
      final startsAt = startsAtTimestamp?.toDate() ?? DateTime.now();

      if (teamId == null || studentIdsSnapshot.isEmpty) {
        print(
          'Skipping session $sessionId (missing teamId or studentIdsSnapshot).',
        );
        continue;
      }

      print('Processing session $sessionId for team $teamId...');

      // Fetch all marks for this session
      final marksSnapshot = await firestore
          .collection('attendance')
          .doc(sessionId)
          .collection('marks')
          .get();

      final marksByStudent = <String, ({String status, Timestamp? markedAt})>{};
      for (final doc in marksSnapshot.docs) {
        final studentId = doc.id.split('_').first;
        final status = doc.data()['status'] as String? ?? 'absent';
        final dbTimestamp = doc.data()['markedAt'] ?? doc.data()['updatedAt'];
        final markedAt = dbTimestamp is Timestamp ? dbTimestamp : null;
        marksByStudent[studentId] = (status: status, markedAt: markedAt);
      }

      // Write subcollection documents in batched chunks of 450
      final List<List<String>> chunks = [];
      for (int i = 0; i < studentIdsSnapshot.length; i += 450) {
        chunks.add(
          studentIdsSnapshot.sublist(
            i,
            (i + 450).clamp(0, studentIdsSnapshot.length),
          ),
        );
      }

      for (final chunk in chunks) {
        final batch = firestore.batch();
        for (final studentId in chunk) {
          final markData = marksByStudent[studentId];
          final status = markData?.status ?? 'absent';
          final markedAt = markData?.markedAt;
          final studentName = studentNameSnapshots[studentId] ?? 'مخدوم';

          final studentSessionRef = firestore
              .collection('students')
              .doc(studentId)
              .collection('attendanceSessions')
              .doc(sessionId);

          batch.set(studentSessionRef, {
            'sessionId': sessionId,
            'teamId': teamId,
            'studentId': studentId,
            'studentName': studentName,
            'status': status,
            'markedAt': markedAt,
            'startsAt': Timestamp.fromDate(startsAt),
            'closedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        totalWrites += chunk.length;
      }
    }

    print(
      'Backfill complete! Wrote $totalWrites student attendance history entries.',
    );
    exit(0);
  } catch (e, stack) {
    print('Backfill failed with error: $e');
    print(stack);
    exit(1);
  }
}
