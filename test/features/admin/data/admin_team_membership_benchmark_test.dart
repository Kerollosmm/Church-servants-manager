import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminTeamMembershipService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = AdminTeamMembershipService(firestore: firestore);
  });

  test('Benchmark _recomputeStudentIdsForClasses', () async {
    // Generate 200 classes and 1000 students distributed among them
    final classIds = List.generate(200, (i) => 'class_$i');
    
    Future<void> commitInChunks(List<void Function(WriteBatch)> ops) async {
      for (var i = 0; i < ops.length; i += 400) {
        final b = firestore.batch();
        final end = (i + 400 > ops.length) ? ops.length : i + 400;
        for (final op in ops.sublist(i, end)) {
          op(b);
        }
        await b.commit();
      }
    }

    final ops = <void Function(WriteBatch)>[];
    
    for (final classId in classIds) {
      ops.add((b) => b.set(firestore.collection(FirestoreCollections.classes).doc(classId), {
        'name': 'Class $classId',
      }));
    }

    // 5 students per class
    int studentIndex = 0;
    for (final classId in classIds) {
      for (int i = 0; i < 5; i++) {
        ops.add((b) => b.set(firestore.collection(FirestoreCollections.students).doc('student_$studentIndex'), {
          'classId': classId,
          'isArchived': false,
          'name': 'Student $studentIndex',
        }));
        studentIndex++;
      }
    }
    
    // Add some archived students to ensure filtering works
    for (int i = 0; i < 50; i++) {
      ops.add((b) => b.set(firestore.collection(FirestoreCollections.students).doc('archived_student_$i'), {
        'classId': classIds[i % classIds.length],
        'isArchived': true,
        'name': 'Archived Student $i',
      }));
    }

    await commitInChunks(ops);

    // Measure
    final stopwatch = Stopwatch()..start();
    await service.recomputeStudentIdsForClasses(classIds.toSet());
    stopwatch.stop();

    print('Benchmark: recomputeStudentIdsForClasses took ${stopwatch.elapsedMilliseconds} ms for 200 classes');
  });
}
