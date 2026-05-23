// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TeamModelAdapter extends TypeAdapter<TeamModel> {
  @override
  final int typeId = 3;

  @override
  TeamModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeamModel(
      id: fields[0] as String,
      name: fields[1] as String,
      groupId: fields[2] as String,
      assignedServantId: fields[3] as String?,
      assignedServantName: fields[4] as String?,
      isArchived: fields[5] as bool,
      archivedAt: fields[6] as DateTime?,
      archivedByUserId: fields[7] as String?,
      archiveReason: fields[8] as String?,
      restoredAt: fields[9] as DateTime?,
      restoredByUserId: fields[10] as String?,
      syncStatus: fields[11] as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, TeamModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.groupId)
      ..writeByte(3)
      ..write(obj.assignedServantId)
      ..writeByte(4)
      ..write(obj.assignedServantName)
      ..writeByte(5)
      ..write(obj.isArchived)
      ..writeByte(6)
      ..write(obj.archivedAt)
      ..writeByte(7)
      ..write(obj.archivedByUserId)
      ..writeByte(8)
      ..write(obj.archiveReason)
      ..writeByte(9)
      ..write(obj.restoredAt)
      ..writeByte(10)
      ..write(obj.restoredByUserId)
      ..writeByte(11)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamModelImpl _$$TeamModelImplFromJson(Map<String, dynamic> json) =>
    _$TeamModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      groupId: json['groupId'] as String,
      assignedServantId: json['assignedServantId'] as String?,
      assignedServantName: json['assignedServantName'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt:
          const FirestoreTimestampConverter().fromJson(json['archivedAt']),
      archivedByUserId: json['archivedByUserId'] as String?,
      archiveReason: json['archiveReason'] as String?,
      restoredAt:
          const FirestoreTimestampConverter().fromJson(json['restoredAt']),
      restoredByUserId: json['restoredByUserId'] as String?,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.synced,
    );

Map<String, dynamic> _$$TeamModelImplToJson(_$TeamModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'groupId': instance.groupId,
      'assignedServantId': instance.assignedServantId,
      'assignedServantName': instance.assignedServantName,
      'isArchived': instance.isArchived,
      'archivedAt':
          const FirestoreTimestampConverter().toJson(instance.archivedAt),
      'archivedByUserId': instance.archivedByUserId,
      'archiveReason': instance.archiveReason,
      'restoredAt':
          const FirestoreTimestampConverter().toJson(instance.restoredAt),
      'restoredByUserId': instance.restoredByUserId,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
