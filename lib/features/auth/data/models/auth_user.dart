import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
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
    @Default(false) bool requiresTokenRefresh,
    String? groupId,
    @Default(<String>[]) List<String> assignedTeamIds,
    @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
    String? assignedTeamId,
  }) = _AuthUser;

  /// Create AuthUser from Firebase User (basic info only)
  /// WARNING: This method assigns a temporary role of UserRole.student.
  /// This is UNSAFE for production authorization checks.
  /// Use AuthUser.fromFirebaseToken() instead whenever possible.
  @visibleForTesting
  factory AuthUser.fromFirebaseUnsafe(User user) {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const GenericAuthException('AuthUser must have a valid email');
    }
    return AuthUser(
      uid: user.uid,
      name: user.displayName ?? email.split('@').first,
      email: email,
      role: UserRole.student,
      isEmailVerified: user.emailVerified,
    );
  }

  /// Create AuthUser from Firebase User and custom claims
  factory AuthUser.fromFirebaseToken(User user, Map<String, dynamic> claims) {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const GenericAuthException('AuthUser must have a valid email');
    }

    // Parse role from claims
    final roleClaim = claims['role'];
    final roleStr = roleClaim is String ? roleClaim : 'student';
    final role = UserRole.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => UserRole.student,
    );

    // Parse teams from claims
    final teamsRaw = claims['assignedTeamIds'] ?? claims['teams'];
    final List<String> assignedTeamIds = [];
    if (teamsRaw is List) {
      assignedTeamIds.addAll(teamsRaw.map((e) => e.toString()));
    }

    // Pick up legacy singular ID if present
    final legacyTeamId = claims['assignedTeamId'] as String?;

    // Parse isArchived from claims
    final isArchived = claims['isArchived'] as bool? ?? false;

    return AuthUser(
      uid: user.uid,
      name: user.displayName ?? email.split('@').first,
      email: email,
      role: role,
      isEmailVerified: user.emailVerified,
      assignedTeamIds: assignedTeamIds,
      assignedTeamId: legacyTeamId,
      isArchived: isArchived,
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
