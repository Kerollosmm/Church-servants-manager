import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/student_operation_exception.dart';

// FIX [P1]: extracted student archive orchestration behind a use case.
class DeleteStudentUseCase {
  const DeleteStudentUseCase(
    this._repository,
    this._canMutateStudent,
    this._adminUserProvisioningService,
  );

  final StudentDataRepository _repository;
  final CanMutateStudentUseCase _canMutateStudent;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<void> call({required AuthUser actor, required String docId}) async {
    final existing = await _repository.getStudentById(docId);
    if (existing == null) {
      throw const StudentOperationException('لم يتم العثور على المخدوم.');
    }
    if (!_canMutateStudent(actor, existing)) {
      throw const StudentOperationException('غير مسموح.');
    }

    // FIX [004-C2]: pass actor uid so repository records the real performer.
    await _repository.deleteStudent(docId, performedByUid: actor.uid);
    if (existing.uid.trim().isNotEmpty) {
      await _adminUserProvisioningService.archiveUser(uid: existing.uid.trim());
    }
  }
}
