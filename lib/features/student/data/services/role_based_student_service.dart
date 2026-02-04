import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';

/// Service that provides role-based access to student data.
/// - Admin: Can access all students
/// - Servant: Can only access students in their assigned group
class RoleBasedStudentService {
  final StudentDataRepository _studentDataService;

  RoleBasedStudentService({required StudentDataRepository studentDataService})
    : _studentDataService = studentDataService;

  /// Gets students accessible to the given user based on their role.
  /// - Admin: Returns all students
  /// - Servant: Returns only students matching the servant's group
  Future<List<StudentModel>> getAccessibleStudents({
    required AuthUser user,
    required Group? servantGroup,
  }) async {
    if (user.role == UserRole.admin) {
      // Admin can see all students
      return _studentDataService.getAllStudents(limit: 100);
    }

    if (user.role == UserRole.servant && servantGroup != null) {
      // Servant can only see students in their group
      return _getStudentsByGroup(servantGroup);
    }

    // Students or users without assigned groups see nothing
    return [];
  }

  /// Filters students by group.
  Future<List<StudentModel>> _getStudentsByGroup(Group group) async {
    return _studentDataService.getStudentsByGroup(group.name);
  }

  /// Checks if a user can access a specific student.
  bool canAccessStudent({
    required AuthUser user,
    required Group? servantGroup,
    required StudentModel student,
  }) {
    if (user.role == UserRole.admin) return true;
    if (user.role == UserRole.servant && servantGroup != null) {
      return student.group == servantGroup;
    }
    return false;
  }
}
