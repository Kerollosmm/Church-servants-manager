import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_data_event.dart';
part 'student_data_state.dart';

/// BLoC for managing student data with role-based filtering.
/// Events accept filter parameters - UI passes groupId from RoleCubit.
class StudentDataBloc extends Bloc<StudentDataEvent, StudentDataState> {
  final StudentDataRepository _studentRepository;
  String? _lastFilterGroupId;

  StudentDataBloc({required StudentDataRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentDataInitial()) {
    on<StudentsLoadRequested>(_onLoadStudents);
    on<StudentCreated>(_onCreateStudent);
    on<StudentUpdated>(_onUpdateStudent);
    on<StudentDeleted>(_onDeleteStudent);
    on<StudentsRefreshRequested>(_onRefreshStudents);
  }

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      _lastFilterGroupId = event.filterGroupId;

      List<StudentModel> students;

      if (event.filterGroupId == null) {
        // Admin: fetch all students
        students = await _studentRepository.getAllStudents(limit: event.limit);
      } else {
        // Servant: fetch students by group (class)
        students = await _studentRepository.getStudentsByClass(
          event.filterGroupId!,
        );
      }

      emit(
        StudentDataLoaded(
          students: students,
          currentFilterGroupId: event.filterGroupId,
        ),
      );
    } catch (e) {
      emit(StudentDataError('Failed to load students: $e'));
    }
  }

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      await _studentRepository.createStudent(event.student);
      emit(const StudentDataOperationSuccess('Student created successfully'));
      // Reload with last filter
      add(StudentsLoadRequested(filterGroupId: _lastFilterGroupId));
    } catch (e) {
      emit(StudentDataError('Failed to create student: $e'));
    }
  }

  Future<void> _onUpdateStudent(
    StudentUpdated event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      await _studentRepository.updateStudent(event.student);
      emit(const StudentDataOperationSuccess('Student updated successfully'));
      // Reload with last filter
      add(StudentsLoadRequested(filterGroupId: _lastFilterGroupId));
    } catch (e) {
      emit(StudentDataError('Failed to update student: $e'));
    }
  }

  Future<void> _onDeleteStudent(
    StudentDeleted event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      await _studentRepository.deleteStudent(event.docId);
      emit(const StudentDataOperationSuccess('Student deleted successfully'));
      // Reload with last filter
      add(StudentsLoadRequested(filterGroupId: _lastFilterGroupId));
    } catch (e) {
      emit(StudentDataError('Failed to delete student: $e'));
    }
  }

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    add(StudentsLoadRequested(filterGroupId: _lastFilterGroupId));
  }
}
