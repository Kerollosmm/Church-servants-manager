import 'package:church_management_system/core/constants/enums.dart';

class AdminUserProvisioningRequest {
  const AdminUserProvisioningRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final UserRole role;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'role': role.name,
    };
  }
}

class AdminUserProvisioningResponse {
  const AdminUserProvisioningResponse({required this.uid});

  final String uid;

  factory AdminUserProvisioningResponse.fromJson(Map<Object?, Object?> json) {
    final uid = json['uid'];
    if (uid is! String || uid.trim().isEmpty) {
      throw const FormatException('Provisioning response is missing uid.');
    }
    return AdminUserProvisioningResponse(uid: uid.trim());
  }
}

class AdminUserRollbackRequest {
  const AdminUserRollbackRequest({required this.uid});

  final String uid;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'uid': uid};
  }
}
