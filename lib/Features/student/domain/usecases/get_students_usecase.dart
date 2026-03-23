import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';

// FIX [P1]: extracted student loading/lookups behind a use case.
class GetStudentsUseCase {
  const GetStudentsUseCase(this._repository, this._getStudentsStreamUseCase);

  final StudentDataRepository _repository;
  final GetStudentsStreamUseCase _getStudentsStreamUseCase;

  Stream<List<StudentModel>>? watch({
    required AuthUser actor,
    String? teamId,
    bool includeArchived = false,
  }) {
    return _getStudentsStreamUseCase(
      actor: actor,
      teamId: teamId,
      includeArchived: includeArchived,
    );
  }

  Future<StudentModel?> findById(String docId, {bool includeArchived = false}) {
    return _repository.getStudentById(docId, includeArchived: includeArchived);
  }
}
