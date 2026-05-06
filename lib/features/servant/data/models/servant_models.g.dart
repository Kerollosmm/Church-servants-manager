// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servant_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServantModelImpl _$$ServantModelImplFromJson(
  Map<String, dynamic> json,
) => _$ServantModelImpl(
  uid: json['uid'] as String?,
  docID: json['docID'] as String,
  name: json['name'] as String,
  role: json['role'] == null
      ? UserRole.servant
      : const UserRoleJsonConverter().fromJson(json['role'] as String?),
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  imageUrl: json['imageUrl'] as String?,
  teamName: json['groupId'] as String?,
  isEmailVerified: json['isEmailVerified'] as bool? ?? false,
  fatherOfConfession: json['father_of_confession'] as String?,
  birthdate: const FirestoreTimestampConverter().fromJson(json['birthdate']),
  notes: json['notes'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  archivedAt: const FirestoreTimestampConverter().fromJson(json['archivedAt']),
  archivedByUserId: json['archivedByUserId'] as String?,
  archiveReason: json['archiveReason'] as String?,
  restoredAt: const FirestoreTimestampConverter().fromJson(json['restoredAt']),
  restoredByUserId: json['restoredByUserId'] as String?,
  assignedTeamId: json['assignedTeamId'] as String?,
  assignedTeamIds:
      (json['assignedTeamIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  groupAttendanceSummary:
      json['groupAttendanceSummary'] as Map<String, dynamic>?,
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.synced,
  clientUpdatedAt: const FirestoreTimestampConverter().fromJson(
    json['clientUpdatedAt'],
  ),
);

Map<String, dynamic> _$$ServantModelImplToJson(
  _$ServantModelImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'docID': instance.docID,
  'name': instance.name,
  'role': const UserRoleJsonConverter().toJson(instance.role),
  'email': instance.email,
  'phone': instance.phone,
  'imageUrl': instance.imageUrl,
  'groupId': instance.teamName,
  'isEmailVerified': instance.isEmailVerified,
  'father_of_confession': instance.fatherOfConfession,
  'birthdate': const FirestoreTimestampConverter().toJson(instance.birthdate),
  'notes': instance.notes,
  'isArchived': instance.isArchived,
  'archivedAt': const FirestoreTimestampConverter().toJson(instance.archivedAt),
  'archivedByUserId': instance.archivedByUserId,
  'archiveReason': instance.archiveReason,
  'restoredAt': const FirestoreTimestampConverter().toJson(instance.restoredAt),
  'restoredByUserId': instance.restoredByUserId,
  'assignedTeamId': instance.assignedTeamId,
  'assignedTeamIds': instance.assignedTeamIds,
  'groupAttendanceSummary': instance.groupAttendanceSummary,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
  'clientUpdatedAt': const FirestoreTimestampConverter().toJson(
    instance.clientUpdatedAt,
  ),
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
