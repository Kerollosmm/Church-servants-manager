import 'package:church_management_system/features/results/data/repos/results_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ResultsRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ResultsRepository(firestore: firestore);
  });

  group('ResultsRepository', () {
    test(
      'getResultsForServant applies mandatory groupId filter and limit',
      () async {
        final groupId = 'year1';

        // Seed some results in nested structure
        for (var i = 1; i <= 35; i++) {
          await firestore
              .collection('results')
              .doc('student-$i')
              .collection('terms')
              .doc('term-1')
              .set({
                'studentId': 'student-$i',
                'termId': 'term-1',
                'score': 90.0 + i,
                'groupId': i <= 32 ? groupId : 'other-group',
              });
        }

        final results = await repository.getResultsForServant(groupId);

        // Should only get results for 'year1' and be limited to 30
        expect(results.length, 30);
        expect(results.every((r) => r.groupId == groupId), isTrue);
      },
    );

    test('getResultForStudent returns specific student result', () async {
      final studentId = 'student-123';
      await firestore
          .collection('results')
          .doc(studentId)
          .collection('terms')
          .doc('term-1')
          .set({
            'studentId': studentId,
            'termId': 'term-1',
            'score': 85.5,
            'groupId': 'year1',
          });

      final result = await repository.getResultForStudent(studentId);

      expect(result, isNotNull);
      expect(result!.studentId, studentId);
      expect(result.score, 85.5);
    });

    test('getResultForStudent returns null for non-existent student', () async {
      final result = await repository.getResultForStudent('non-existent');
      expect(result, isNull);
    });
  });
}
