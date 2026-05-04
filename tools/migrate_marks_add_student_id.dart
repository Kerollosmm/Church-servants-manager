import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration script: Add studentId to legacy attendance marks
///
/// This script reads all marks across the database and adds the studentId field
/// to any mark that doesn't have it. The studentId is inferred from the document ID
/// which is formatted as `${studentId}_${servantId}`.
///
/// Usage: dart tools/migrate_marks_add_student_id.dart
void main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  developer.log('🚀 Starting marks studentId migration...', name: 'Migration');

  int migrated = 0;
  int skipped = 0;
  int errors = 0;

  var batch = firestore.batch();
  int batchCount = 0;

  DocumentSnapshot? lastDoc;
  bool hasMore = true;
  const int pageSize = 500;

  while (hasMore) {
    Query query = firestore.collectionGroup('marks').limit(pageSize);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final marksSnapshot = await query.get();
    if (marksSnapshot.docs.isEmpty) {
      hasMore = false;
      break;
    }

    lastDoc = marksSnapshot.docs.last;

    for (final doc in marksSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('studentId')) {
        skipped++;
        continue;
      }

      final parts = doc.id.split('_');
      if (parts.isEmpty || parts.first.isEmpty) {
        errors++;
        developer.log(
          '❌ Error: Could not infer studentId from doc ID: ${doc.id}',
          name: 'Migration',
        );
        continue;
      }

      final studentId = parts.first;

      batch.update(doc.reference, {'studentId': studentId});
      batchCount++;

      if (batchCount >= 400) {
        developer.log(
          '📦 Committing batch of $batchCount updates...',
          name: 'Migration',
        );
        try {
          await batch.commit();
          migrated += batchCount;
        } catch (e) {
          developer.log('❌ Error committing batch: $e', name: 'Migration');
          errors += batchCount;
        }
        batch = firestore.batch();
        batchCount = 0;
      }
    }
  }

  if (batchCount > 0) {
    developer.log(
      '📦 Committing final batch of $batchCount updates...',
      name: 'Migration',
    );
    try {
      await batch.commit();
      migrated += batchCount;
    } catch (e) {
      developer.log('❌ Error committing final batch: $e', name: 'Migration');
      errors += batchCount;
    }
  }

  developer.log('🎉 Migration complete!', name: 'Migration');
  developer.log('   ✅ Migrated: $migrated marks', name: 'Migration');
  developer.log('   ⏭️  Skipped:  $skipped marks', name: 'Migration');
  developer.log('   ❌ Errors:   $errors marks', name: 'Migration');

  developer.log('Shutting down Firebase connections...', name: 'Migration');
  await FirebaseFirestore.instance.terminate();
  await Firebase.app().delete();
  exit(0);
}
