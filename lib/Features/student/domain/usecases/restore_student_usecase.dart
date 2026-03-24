import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/student_operation_exception.dart';

// FIX [P1]: extracted student restore orchestration behind a use case.
class RestoreStudentUseCase {
  const RestoreStudentUseCase(
    this._repository,
    this._adminUserProvisioningService,
  );

  final StudentDataRepository _repository;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<void> call({required AuthUser actor, required String docId}) async {
    final existing = await _repository.getStudentById(
      docId,
      includeArchived: true,
    );
    if (existing == null) {
      throw const StudentOperationException('لم يتم العثور على المخدوم.');
    }
    if (actor.role != UserRole.admin) {
      throw const StudentOperationException('غير مسموح.');
    }

    // FIX [004-C2]: pass actor uid so repository records the real performer.
    await _repository.restoreStudent(docId, performedByUid: actor.uid);
    if (existing.uid.trim().isNotEmpty) {
      await _adminUserProvisioningService.restoreUser(uid: existing.uid.trim());
    }
  }
}
