import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/student_operation_exception.dart';

// FIX [P1]: extracted student creation/rollback orchestration behind a use case.
class AddStudentUseCase {
  const AddStudentUseCase(
    this._repository,
    this._canMutateStudent,
    this._adminUserProvisioningService,
  );

  final StudentDataRepository _repository;
  final CanMutateStudentUseCase _canMutateStudent;
  final AdminUserProvisioningService _adminUserProvisioningService;

  Future<void> call({
    required AuthUser actor,
    required StudentModel student,
    String? email,
    String? password,
  }) async {
    if (!_canMutateStudent(actor, student)) {
      throw const StudentOperationException('غير مسموح.');
    }

    AuthUser? createdAuthUser;
    try {
      createdAuthUser = await _createLinkedAuthUser(
        student: student,
        email: email,
        password: password,
      );
      final studentToCreate = createdAuthUser == null
          ? student
          : student.copyWith(
              uid: createdAuthUser.uid,
              docID: createdAuthUser.uid,
            );
      await _repository.createStudent(studentToCreate);
    } catch (error) {
      if (createdAuthUser != null) {
        try {
          await _adminUserProvisioningService.rollbackCreatedUser(
            uid: createdAuthUser.uid,
            email: email!,
            password: password!,
          );
        } catch (_) {
          throw const StudentOperationException(
            'تعذر إنشاء المخدوم، كما فشلت إعادة التراجع عن الحساب المرتبط. حاول مرة أخرى.',
          );
        }
      }
      rethrow;
    }
  }

  Future<AuthUser?> _createLinkedAuthUser({
    required StudentModel student,
    String? email,
    String? password,
  }) {
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Future<AuthUser?>.value(null);
    }
    return _adminUserProvisioningService.createUser(
      email: email,
      password: password,
      name: student.name,
      role: student.role,
    );
  }
}
