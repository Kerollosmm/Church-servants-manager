import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:csms/core/constants/enums.dart';

/// Represents an authenticated user in the application.
class AuthUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isEmailVerified;
  final String? linkedStudentId;
  final String? grade;

  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.isEmailVerified = false,
    this.linkedStudentId,
    this.grade,
  });

  /// Create AuthUser from Firebase User (basic info only)
  factory AuthUser.fromFirebase(User user) => AuthUser(
    uid: user.uid,
    name: user.displayName ?? user.email?.split('@').first ?? 'User',
    email: user.email ?? '',
    isEmailVerified: user.emailVerified,
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
    linkedStudentId: json['linkedStudentId'] as String?,
    grade: json['grade'] as String?,
  );

  /// Convert AuthUser to JSON for Firestore
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role.name,
    'isEmailVerified': isEmailVerified,
    'linkedStudentId': linkedStudentId,
    'grade': grade,
  };

  /// Create a copy with modified fields
  AuthUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? isEmailVerified,
    String? linkedStudentId,
    String? grade,
  }) => AuthUser(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    linkedStudentId: linkedStudentId ?? this.linkedStudentId,
    grade: grade ?? this.grade,
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
