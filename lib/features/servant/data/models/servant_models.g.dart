// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servant_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServantModelAdapter extends TypeAdapter<ServantModel> {
  @override
  final int typeId = 2;

  @override
  ServantModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServantModel(
      uid: fields[0] as String?,
      docID: fields[1] as String,
      name: fields[2] as String,
      role: fields[3] as UserRole,
      email: fields[4] as String?,
      phone: fields[5] as String?,
      imageUrl: fields[6] as String?,
      teamName: fields[7] as String?,
      isEmailVerified: fields[8] as bool,
      fatherOfConfession: fields[9] as String?,
      birthdate: fields[10] as DateTime?,
      notes: fields[11] as String?,
      isArchived: fields[12] as bool,
      archivedAt: fields[13] as DateTime?,
      archivedByUserId: fields[14] as String?,
      archiveReason: fields[15] as String?,
      restoredAt: fields[16] as DateTime?,
      restoredByUserId: fields[17] as String?,
      assignedTeamId: fields[18] as String?,
      assignedTeamIds: (fields[19] as List).cast<String>(),
      groupAttendanceSummary: (fields[20] as Map?)?.cast<String, dynamic>(),
      syncStatus: fields[21] as SyncStatus,
      clientUpdatedAt: fields[22] as DateTime?,
      assignedSectorIds: (fields[23] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ServantModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.docID)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.teamName)
      ..writeByte(8)
      ..write(obj.isEmailVerified)
      ..writeByte(9)
      ..write(obj.fatherOfConfession)
      ..writeByte(10)
      ..write(obj.birthdate)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.archivedAt)
      ..writeByte(14)
      ..write(obj.archivedByUserId)
      ..writeByte(15)
      ..write(obj.archiveReason)
      ..writeByte(16)
      ..write(obj.restoredAt)
      ..writeByte(17)
      ..write(obj.restoredByUserId)
      ..writeByte(18)
      ..write(obj.assignedTeamId)
      ..writeByte(19)
      ..write(obj.assignedTeamIds)
      ..writeByte(20)
      ..write(obj.groupAttendanceSummary)
      ..writeByte(21)
      ..write(obj.syncStatus)
      ..writeByte(22)
      ..write(obj.clientUpdatedAt)
      ..writeByte(23)
      ..write(obj.assignedSectorIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServantModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
  assignedSectorIds:
      (json['assignedSectorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
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
  'assignedSectorIds': instance.assignedSectorIds,
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
