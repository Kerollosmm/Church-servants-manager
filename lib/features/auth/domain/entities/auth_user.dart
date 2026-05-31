import 'package:church_management_system/core/constants/enums.dart';

class AuthUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isEmailVerified;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedByUserId;
  final String? archiveReason;
  final DateTime? restoredAt;
  final String? restoredByUserId;
  final bool restorePendingPasswordReset;
  final bool requiresTokenRefresh;
  final String? groupId;
  final List<String> assignedTeamIds;
  final String? assignedTeamId;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isEmailVerified = false,
    this.isArchived = false,
    this.archivedAt,
    this.archivedByUserId,
    this.archiveReason,
    this.restoredAt,
    this.restoredByUserId,
    this.restorePendingPasswordReset = false,
    this.requiresTokenRefresh = false,
    this.groupId,
    this.assignedTeamIds = const <String>[],
    this.assignedTeamId,
  });

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

  AuthUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    bool? isEmailVerified,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredByUserId,
    bool? restorePendingPasswordReset,
    bool? requiresTokenRefresh,
    String? groupId,
    List<String>? assignedTeamIds,
    String? assignedTeamId,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedByUserId: archivedByUserId ?? this.archivedByUserId,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredByUserId: restoredByUserId ?? this.restoredByUserId,
      restorePendingPasswordReset:
          restorePendingPasswordReset ?? this.restorePendingPasswordReset,
      requiresTokenRefresh: requiresTokenRefresh ?? this.requiresTokenRefresh,
      groupId: groupId ?? this.groupId,
      assignedTeamIds: assignedTeamIds ?? this.assignedTeamIds,
      assignedTeamId: assignedTeamId ?? this.assignedTeamId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          isEmailVerified == other.isEmailVerified &&
          isArchived == other.isArchived &&
          archivedAt == other.archivedAt &&
          archivedByUserId == other.archivedByUserId &&
          archiveReason == other.archiveReason &&
          restoredAt == other.restoredAt &&
          restoredByUserId == other.restoredByUserId &&
          restorePendingPasswordReset == other.restorePendingPasswordReset &&
          requiresTokenRefresh == other.requiresTokenRefresh &&
          groupId == other.groupId &&
          assignedTeamId == other.assignedTeamId;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      isEmailVerified.hashCode ^
      isArchived.hashCode ^
      archivedAt.hashCode ^
      archivedByUserId.hashCode ^
      archiveReason.hashCode ^
      restoredAt.hashCode ^
      restoredByUserId.hashCode ^
      restorePendingPasswordReset.hashCode ^
      requiresTokenRefresh.hashCode ^
      groupId.hashCode ^
      assignedTeamId.hashCode;
}
