import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/usecases/add_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/delete_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/restore_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/search_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/update_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStudentsUseCase extends Mock implements GetStudentsUseCase {}

class MockSearchStudentsUseCase extends Mock implements SearchStudentsUseCase {}

class MockAddStudentUseCase extends Mock implements AddStudentUseCase {}

class MockUpdateStudentUseCase extends Mock implements UpdateStudentUseCase {}

class MockDeleteStudentUseCase extends Mock implements DeleteStudentUseCase {}

class MockRestoreStudentUseCase extends Mock implements RestoreStudentUseCase {}

void main() {
  late MockGetStudentsUseCase getStudentsUseCase;
  late MockSearchStudentsUseCase searchStudentsUseCase;
  late MockAddStudentUseCase addStudentUseCase;
  late MockUpdateStudentUseCase updateStudentUseCase;
  late MockDeleteStudentUseCase deleteStudentUseCase;
  late MockRestoreStudentUseCase restoreStudentUseCase;
  late StudentDataBloc bloc;
  late StreamController<List<StudentModel>> studentsController;
  late FakeFirebaseFirestore firestore;

  AuthUser admin() => const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  StudentModel student(String id, String name) => StudentModel(
    uid: id,
    docID: id,
    name: name,
    imageUrl: null,
    role: UserRole.student,
    mobile: '01234567890',
    group: Group.year1,
    teamName: 'Team A',
    motherPhone: '01234567890',
    fatherPhone: '01234567890',
    grade: 1,
    educationStage: EducationStage.preparatory,
    school: null,
    address: null,
    birthdate: null,
    fatherOfConfession: 'Fr.',
    notes: null,
    classId: 'team-a',
  );

  Future<DocumentSnapshot<Map<String, dynamic>>> cursor(String id) async {
    await firestore.collection('Students').doc(id).set(<String, dynamic>{
      'name': id,
      'isArchived': false,
    });
    return firestore.collection('Students').doc(id).get();
  }

  setUp(() {
    getStudentsUseCase = MockGetStudentsUseCase();
    searchStudentsUseCase = MockSearchStudentsUseCase();
    addStudentUseCase = MockAddStudentUseCase();
    updateStudentUseCase = MockUpdateStudentUseCase();
    deleteStudentUseCase = MockDeleteStudentUseCase();
    restoreStudentUseCase = MockRestoreStudentUseCase();
    studentsController = StreamController<List<StudentModel>>.broadcast();
    firestore = FakeFirebaseFirestore();

    when(
      () => getStudentsUseCase.watch(
        actor: admin(),
        teamId: null,
        includeArchived: false,
      ),
    ).thenAnswer((_) => studentsController.stream);

    bloc = StudentDataBloc(
      getStudentsUseCase: getStudentsUseCase,
      searchStudentsUseCase: searchStudentsUseCase,
      addStudentUseCase: addStudentUseCase,
      updateStudentUseCase: updateStudentUseCase,
      deleteStudentUseCase: deleteStudentUseCase,
      restoreStudentUseCase: restoreStudentUseCase,
    );
  });

  tearDown(() async {
    await studentsController.close();
    await bloc.close();
  });

  test(
    'load more appends page 2 correctly and marks the last page as reached',
    () async {
      final firstCursor = await cursor('cursor-1');
      final secondCursor = await cursor('cursor-2');

      when(
        () => getStudentsUseCase.fetchPage(
          actor: admin(),
          limit: 20,
          lastDocument: null,
          teamId: null,
          includeArchived: false,
        ),
      ).thenAnswer(
        (_) async => StudentsPage(
          students: <StudentModel>[student('s1', 'Adam')],
          lastDocument: firstCursor,
          hasReachedMax: false,
        ),
      );

      when(
        () => getStudentsUseCase.fetchPage(
          actor: admin(),
          limit: 20,
          lastDocument: firstCursor,
          teamId: null,
          includeArchived: false,
        ),
      ).thenAnswer(
        (_) async => StudentsPage(
          students: <StudentModel>[student('s2', 'Bishop')],
          lastDocument: secondCursor,
          hasReachedMax: true,
        ),
      );

      final states = <StudentDataState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(StudentsLoadRequested(actor: admin(), limit: 20));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(StudentsLoadMoreRequested(actor: admin()));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final loaded = states.whereType<StudentDataLoaded>().last;
      expect(loaded.students.map((item) => item.docID), <String>['s1', 's2']);
      expect(loaded.lastDocument, same(secondCursor));
      expect(loaded.hasReachedMax, isTrue);

      await subscription.cancel();
    },
  );

  test(
    'stream emissions do not reset lastDocument or hasReachedMax after initial page load',
    () async {
      final firstCursor = await cursor('cursor-1');

      when(
        () => getStudentsUseCase.fetchPage(
          actor: admin(),
          limit: 20,
          lastDocument: null,
          teamId: null,
          includeArchived: false,
        ),
      ).thenAnswer(
        (_) async => StudentsPage(
          students: <StudentModel>[student('s1', 'Adam')],
          lastDocument: firstCursor,
          hasReachedMax: false,
        ),
      );

      final states = <StudentDataState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(StudentsLoadRequested(actor: admin(), limit: 20));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      studentsController.add(<StudentModel>[
        student('s1', 'Adam Updated'),
        student('s2', 'Benjamin'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final loaded = states.whereType<StudentDataLoaded>().last;
      expect(loaded.lastDocument, same(firstCursor));
      expect(loaded.hasReachedMax, isFalse);
      expect(loaded.students, hasLength(1));
      expect(loaded.students.first.name, 'Adam Updated');

      await subscription.cancel();
    },
  );
}
