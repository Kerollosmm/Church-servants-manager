// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamModelImpl _$$TeamModelImplFromJson(
  Map<String, dynamic> json,
) => _$TeamModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  groupId: json['groupId'] as String,
  assignedServantId: json['assignedServantId'] as String?,
  assignedServantName: json['assignedServantName'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  archivedAt: const FirestoreTimestampConverter().fromJson(json['archivedAt']),
  archivedByUserId: json['archivedByUserId'] as String?,
  archiveReason: json['archiveReason'] as String?,
  restoredAt: const FirestoreTimestampConverter().fromJson(json['restoredAt']),
  restoredByUserId: json['restoredByUserId'] as String?,
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.synced,
);

Map<String, dynamic> _$$TeamModelImplToJson(
  _$TeamModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'groupId': instance.groupId,
  'assignedServantId': instance.assignedServantId,
  'assignedServantName': instance.assignedServantName,
  'isArchived': instance.isArchived,
  'archivedAt': const FirestoreTimestampConverter().toJson(instance.archivedAt),
  'archivedByUserId': instance.archivedByUserId,
  'archiveReason': instance.archiveReason,
  'restoredAt': const FirestoreTimestampConverter().toJson(instance.restoredAt),
  'restoredByUserId': instance.restoredByUserId,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
