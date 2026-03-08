import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

void main() {
  late MockStudentDataRepository repository;

  StudentModel student({
    required String id,
    required String name,
    String? classId,
  }) {
    return StudentModel(
      uid: id,
      docID: id,
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
      classId: classId,
    );
  }

  setUp(() {
    repository = MockStudentDataRepository();
  });

  test('load seeds selection from assigned team membership', () async {
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: [
          student(id: 's1', name: 'Andrew', classId: 'team-a'),
          student(id: 's2', name: 'Mina'),
        ],
        isFromCache: false,
      ),
    );

    final cubit = TeamMembersCubit(studentRepository: repository);
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    expect(cubit.state.students.length, 2);
    expect(cubit.state.selectedStudentIds, {'s1'});
    expect(cubit.state.visibleStudents.length, 2);
    await cubit.close();
  });

  test('search and toggleSelection update visible state locally', () async {
    when(() => repository.getStudentsByGroupWithFallback('year1')).thenAnswer(
      (_) async => (
        students: [
          student(id: 's1', name: 'Andrew'),
          student(id: 's2', name: 'Mina'),
        ],
        isFromCache: true,
      ),
    );

    final cubit = TeamMembersCubit(studentRepository: repository);
    await cubit.load(groupId: 'year1', teamId: 'team-a');

    cubit.search('and');
    expect(cubit.state.visibleStudents.map((s) => s.docID).toList(), ['s1']);

    cubit.toggleSelection('s2', true);
    expect(cubit.state.selectedStudentIds.contains('s2'), isTrue);
    expect(cubit.selectedStudents().map((s) => s.docID).toSet(), {'s2'});
    await cubit.close();
  });
}
