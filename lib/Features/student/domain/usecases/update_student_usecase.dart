import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/student_operation_exception.dart';

// FIX [P1]: extracted student update validation/orchestration behind a use case.
class UpdateStudentUseCase {
  const UpdateStudentUseCase(this._repository, this._canMutateStudent);

  final StudentDataRepository _repository;
  final CanMutateStudentUseCase _canMutateStudent;

  Future<void> call({
    required AuthUser actor,
    required StudentModel updatedStudent,
  }) async {
    final existing = await _repository.getStudentById(updatedStudent.docID);
    if (existing == null) {
      throw const StudentOperationException('لم يتم العثور على المخدوم.');
    }
    if (!_canMutateStudent(actor, existing)) {
      throw const StudentOperationException('غير مسموح.');
    }

    final isRoleChange = existing.role != updatedStudent.role;
    if (isRoleChange && actor.role != UserRole.admin) {
      throw const StudentOperationException('غير مسموح.');
    }
    if (isRoleChange &&
        updatedStudent.role == UserRole.servant &&
        updatedStudent.uid.trim().isEmpty) {
      throw const StudentOperationException(
        'لا يمكن ترقية المخدوم بدون حساب مستخدم مرتبط.',
      );
    }

    if (isRoleChange) {
      await _repository.updateStudentAndSyncLinkedUserRole(
        updatedStudent: updatedStudent,
        previousRole: existing.role,
      );
      return;
    }

    await _repository.updateStudent(updatedStudent);
  }
}
