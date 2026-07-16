import 'package:church_management_system/core/constants/enums.dart';

class Invitation {
  final String email;
  final String name;
  final UserRole role;
  final DateTime invitedAt;
  final String status;

  Invitation({
    required this.email,
    required this.name,
    required this.role,
    required this.invitedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role.name,
    'invitedAt': invitedAt.toIso8601String(),
    'status': status,
  };

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      invitedAt: map['invitedAt'] is DateTime
          ? map['invitedAt'] as DateTime
          : map['invitedAt'] is String
          ? DateTime.parse(map['invitedAt'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
    );
  }
}
