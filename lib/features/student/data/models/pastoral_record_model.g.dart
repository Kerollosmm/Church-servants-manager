// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pastoral_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PastoralRecordModelAdapter extends TypeAdapter<PastoralRecordModel> {
  @override
  final int typeId = 35;

  @override
  PastoralRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PastoralRecordModel(
      recordId: fields[0] as String,
      studentId: fields[1] as String,
      type: fields[2] as VisitationType,
      summary: fields[3] as String,
      visitedByUid: fields[4] as String,
      visitedByName: fields[5] as String,
      createdAt: fields[6] as DateTime,
      syncStatus: fields[7] as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, PastoralRecordModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.recordId)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.summary)
      ..writeByte(4)
      ..write(obj.visitedByUid)
      ..writeByte(5)
      ..write(obj.visitedByName)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PastoralRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PastoralRecordModelImpl _$$PastoralRecordModelImplFromJson(
  Map<String, dynamic> json,
) => _$PastoralRecordModelImpl(
  recordId: json['recordId'] as String,
  studentId: json['studentId'] as String,
  type: $enumDecode(_$VisitationTypeEnumMap, json['type']),
  summary: json['summary'] as String,
  visitedByUid: json['visitedByUid'] as String,
  visitedByName: json['visitedByName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.pending,
);

Map<String, dynamic> _$$PastoralRecordModelImplToJson(
  _$PastoralRecordModelImpl instance,
) => <String, dynamic>{
  'recordId': instance.recordId,
  'studentId': instance.studentId,
  'type': _$VisitationTypeEnumMap[instance.type]!,
  'summary': instance.summary,
  'visitedByUid': instance.visitedByUid,
  'visitedByName': instance.visitedByName,
  'createdAt': instance.createdAt.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$VisitationTypeEnumMap = {
  VisitationType.phoneCall: 'phoneCall',
  VisitationType.homeVisit: 'homeVisit',
  VisitationType.socialMedia: 'socialMedia',
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
