import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap tolerates missing legacy optional string fields', () {
    final student = StudentModel.fromMap({
      'uid': 'u1',
      'name': 'Student One',
      'role': 'student',
      'mobile': '01234567890',
      'group': 'year1',
      'team_name': 'Team A',
      'grade': 1,
      'education_stage': 'preparatory',
    }, 'doc-1');

    expect(student.docID, 'doc-1');
    expect(student.uid, 'u1');
    expect(student.group, Group.year1);
    expect(student.role, UserRole.student);
    expect(student.motherPhone, '');
    expect(student.fatherPhone, '');
    expect(student.fatherOfConfession, '');
    expect(student.school, isNull);
    expect(student.address, isNull);
    expect(student.notes, isNull);
  });
}
