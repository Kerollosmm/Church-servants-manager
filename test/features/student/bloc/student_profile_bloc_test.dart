import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataRepository extends Mock implements StudentDataRepository {}

void main() {
  late MockStudentDataRepository repo;

  const studentActor = AuthUser(
    uid: 'student-1',
    email: 's@test.com',
    name: 'Student',
    role: UserRole.student,
    isEmailVerified: true,
  );

  const adminActor = AuthUser(
    uid: 'admin-1',
    email: 'a@test.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  setUp(() {
    repo = MockStudentDataRepository();
  });

  blocTest<StudentProfileBloc, StudentProfileState>(
    'loads profile for student actor',
    build: () {
      when(() => repo.getStudentByUid('student-1')).thenAnswer(
        (_) async => StudentModel(
          uid: 'student-1',
          docID: 'student-1',
          name: 'Student',
          imageUrl: null,
          role: UserRole.student,
          mobile: '01234567890',
          group: Group.year1,
          teamName: 'Team A',
          motherPhone: '01111111111',
          fatherPhone: '02222222222',
          grade: 1,
          educationStage: EducationStage.preparatory,
          school: null,
          address: null,
          birthdate: null,
          fatherOfConfession: 'Fr.',
          notes: null,
          classId: 'year1',
        ),
      );
      return StudentProfileBloc(studentRepository: repo);
    },
    act: (bloc) => bloc.add(const StudentProfileLoadRequested(actor: studentActor)),
    expect: () => [
      isA<StudentProfileLoading>(),
      isA<StudentProfileLoaded>(),
    ],
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'blocks non-student actor',
    build: () => StudentProfileBloc(studentRepository: repo),
    act: (bloc) => bloc.add(const StudentProfileLoadRequested(actor: adminActor)),
    expect: () => [
      isA<StudentProfileLoading>(),
      isA<StudentProfileError>().having((e) => e.message, 'message', 'Not allowed.'),
    ],
  );
}

