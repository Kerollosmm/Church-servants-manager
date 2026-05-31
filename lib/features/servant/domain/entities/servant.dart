import 'package:church_management_system/core/constants/enums.dart';

class Servant {
  final String? uid;
  final String docID;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? imageUrl;
  final String? teamName;
  final bool isEmailVerified;
  final String? fatherOfConfession;
  final DateTime? birthdate;
  final String? notes;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedByUserId;
  final String? archiveReason;
  final DateTime? restoredAt;
  final String? restoredByUserId;
  final String? assignedTeamId;
  final List<String> assignedTeamIds;
  final Map<String, dynamic>? groupAttendanceSummary;
  final SyncStatus syncStatus;
  final DateTime? clientUpdatedAt;
  final List<String> assignedSectorIds;

  const Servant({
    this.uid,
    required this.docID,
    required this.name,
    this.role = UserRole.servant,
    this.email,
    this.phone,
    this.imageUrl,
    this.teamName,
    this.isEmailVerified = false,
    this.fatherOfConfession,
    this.birthdate,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.archivedByUserId,
    this.archiveReason,
    this.restoredAt,
    this.restoredByUserId,
    this.assignedTeamId,
    this.assignedTeamIds = const <String>[],
    this.groupAttendanceSummary,
    this.syncStatus = SyncStatus.synced,
    this.clientUpdatedAt,
    this.assignedSectorIds = const <String>[],
  });

  bool get isActive => !isArchived;

  List<String> get effectiveAssignedTeamIds {
    final ids = <String>{};
    for (final id in assignedTeamIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        ids.add(trimmed);
      }
    }
    final legacyId = assignedTeamId?.trim();
    if (legacyId != null && legacyId.isNotEmpty) {
      ids.add(legacyId);
    }
    return ids.toList(growable: false);
  }

  Servant copyWith({
    String? uid,
    String? docID,
    String? name,
    UserRole? role,
    String? email,
    String? phone,
    String? imageUrl,
    String? teamName,
    bool? isEmailVerified,
    String? fatherOfConfession,
    DateTime? birthdate,
    String? notes,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredByUserId,
    String? assignedTeamId,
    List<String>? assignedTeamIds,
    Map<String, dynamic>? groupAttendanceSummary,
    SyncStatus? syncStatus,
    DateTime? clientUpdatedAt,
    List<String>? assignedSectorIds,
  }) {
    return Servant(
      uid: uid ?? this.uid,
      docID: docID ?? this.docID,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      teamName: teamName ?? this.teamName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fatherOfConfession: fatherOfConfession ?? this.fatherOfConfession,
      birthdate: birthdate ?? this.birthdate,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedByUserId: archivedByUserId ?? this.archivedByUserId,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredByUserId: restoredByUserId ?? this.restoredByUserId,
      assignedTeamId: assignedTeamId ?? this.assignedTeamId,
      assignedTeamIds: assignedTeamIds ?? this.assignedTeamIds,
      groupAttendanceSummary:
          groupAttendanceSummary ?? this.groupAttendanceSummary,
      syncStatus: syncStatus ?? this.syncStatus,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      assignedSectorIds: assignedSectorIds ?? this.assignedSectorIds,
    );
  }
}
