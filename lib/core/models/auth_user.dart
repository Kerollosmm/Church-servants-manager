import 'package:church_managment_system/core/constants/enums.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

/// Represents an authenticated user in the application.
class AuthUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isEmailVerified;
  final String? groupId; // Servant's assigned group ID

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isEmailVerified = false,
    this.groupId,
  });

  /// Create AuthUser from Firebase User (basic info only)
  factory AuthUser.fromFirebase(User user) => AuthUser(
    uid: user.uid,
    name: user.displayName ?? user.email?.split('@').first ?? 'User',
    email: user.email ?? '',
    role: UserRole.student,
    isEmailVerified: user.emailVerified,
    groupId: null,
  );

  /// Create AuthUser from JSON (Firestore document)
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    uid: json['uid'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.student,
    ),
    isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    groupId: json['groupId'] as String?,
  );

  /// Convert AuthUser to JSON for Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role.name,
    'isEmailVerified': isEmailVerified,
    'groupId': groupId,
  };

  /// Create a copy with modified fields
  AuthUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? isEmailVerified,
    String? groupId,
  }) => AuthUser(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    groupId: groupId ?? this.groupId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
