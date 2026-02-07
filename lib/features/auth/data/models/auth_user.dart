import 'package:church_managment_system/core/constants/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
class AuthUser with _$AuthUser {
  const AuthUser._();

  const factory AuthUser({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    @Default(false) bool isEmailVerified,
    String? groupId,
  }) = _AuthUser;

  /// Create AuthUser from Firebase User (basic info only)
  factory AuthUser.fromFirebase(User user) => AuthUser(
    uid: user.uid,
    name: user.displayName ?? user.email?.split('@').first ?? 'User',
    email: user.email ?? '',
    role: UserRole.student,
    isEmailVerified: user.emailVerified,
    groupId: null,
  );

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  /// Convert to JSON for Firestore (wrapper to match existing usage if needed,
  /// though toJson is automatically generated)
  Map<String, dynamic> toMap() => toJson();
}
