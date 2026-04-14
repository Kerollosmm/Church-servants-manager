import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

@freezed
class AuthUser with _$AuthUser {
  const AuthUser._();

  const factory AuthUser({
    required String uid,
    required String email,
    required String name,
    required UserRole role,
    @Default(false) bool isEmailVerified,
    @Default(false) bool isArchived,
    @_TimestampConverter() DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    @_TimestampConverter() DateTime? restoredAt,
    String? restoredByUserId,
    @Default(false) bool restorePendingPasswordReset,
    String? groupId,
    @Default(<String>[]) List<String> assignedTeamIds,
    String? assignedTeamId,
  }) = _AuthUser;

  /// Create AuthUser from Firebase User (basic info only)
  factory AuthUser.fromFirebase(User user) {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const GenericAuthFailure(
        'Firebase user has no email — cannot construct AuthUser',
      );
    }
    return AuthUser(
      uid: user.uid,
      email: email,
      name: user.displayName ?? email.split('@').first,
      role: UserRole.student,
      isEmailVerified: user.emailVerified,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  List<String> get effectiveAssignedTeamIds {
    final ids = <String>{};
    for (final id in assignedTeamIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        ids.add(trimmed);
      }
    }
    final legacyAssignedTeamId = assignedTeamId?.trim();
    if (legacyAssignedTeamId != null && legacyAssignedTeamId.isNotEmpty) {
      ids.add(legacyAssignedTeamId);
    }
    return ids.toList(growable: false);
  }

  String? get primaryAssignedTeamId =>
      effectiveAssignedTeamIds.isEmpty ? null : effectiveAssignedTeamIds.first;

  bool get isActive => !isArchived;

  /// Convert to JSON for Firestore (wrapper to match existing usage if needed,
  /// though toJson is automatically generated)
  Map<String, dynamic> toMap() => toJson();
}
