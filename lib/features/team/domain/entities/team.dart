import 'package:church_management_system/core/constants/enums.dart';

class Team {
  final String id;
  final String name;
  final String groupId;
  final String? assignedServantId;
  final String? assignedServantName;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedByUserId;
  final String? archiveReason;
  final DateTime? restoredAt;
  final String? restoredByUserId;
  final SyncStatus syncStatus;

  const Team({
    required this.id,
    required this.name,
    required this.groupId,
    this.assignedServantId,
    this.assignedServantName,
    this.isArchived = false,
    this.archivedAt,
    this.archivedByUserId,
    this.archiveReason,
    this.restoredAt,
    this.restoredByUserId,
    this.syncStatus = SyncStatus.synced,
  });

  bool get isActive => !isArchived;

  Team copyWith({
    String? id,
    String? name,
    String? groupId,
    String? assignedServantId,
    String? assignedServantName,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredByUserId,
    SyncStatus? syncStatus,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      assignedServantId: assignedServantId ?? this.assignedServantId,
      assignedServantName: assignedServantName ?? this.assignedServantName,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedByUserId: archivedByUserId ?? this.archivedByUserId,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredByUserId: restoredByUserId ?? this.restoredByUserId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
