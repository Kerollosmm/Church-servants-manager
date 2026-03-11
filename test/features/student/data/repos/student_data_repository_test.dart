import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late StudentDataRepository repository;

  StudentModel buildStudent({String name = 'Mina'}) {
    return StudentModel(
      uid: 'student-1',
      docID: 'student-1',
      name: name,
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: 'team-1',
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = StudentDataRepository(firestore: firestore);
  });

  test('createStudent writes createdAt and updatedAt', () async {
    await repository.createStudent(buildStudent());

    final doc = await firestore.collection('Students').doc('student-1').get();
    expect(doc.data()!['createdAt'], isNotNull);
    expect(doc.data()!['updatedAt'], isNotNull);
  });

  test('updateStudent preserves createdAt while refreshing updatedAt', () async {
    final existingCreatedAt = DateTime(2026, 3, 1, 10, 0);
    await firestore.collection('Students').doc('student-1').set({
      ...buildStudent().toMap(),
      'createdAt': existingCreatedAt,
      'updatedAt': existingCreatedAt,
    });

    await repository.updateStudent(buildStudent(name: 'Updated Mina'));

    final doc = await firestore.collection('Students').doc('student-1').get();
    final createdAt = doc.data()!['createdAt'] as Timestamp;
    expect(doc.data()!['name'], 'Updated Mina');
    expect(createdAt.toDate(), existingCreatedAt);
    expect(doc.data()!['updatedAt'], isNotNull);
  });
}
