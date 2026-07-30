import 'package:church_management_system/features/student/data/models/pastoral_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PastoralRecordModel', () {
    test(
      'generateRecordId produces non-deterministic, unguessable IDs with UUID suffix',
      () {
        final now = DateTime.now();
        const studentId = 'student-123';

        final id1 = PastoralRecordModel.generateRecordId(studentId, now);
        final id2 = PastoralRecordModel.generateRecordId(studentId, now);

        expect(id1, startsWith('${studentId}_${now.millisecondsSinceEpoch}_'));
        expect(id2, startsWith('${studentId}_${now.millisecondsSinceEpoch}_'));
        expect(id1, isNot(equals(id2)));
      },
    );
  });
}
