// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_ledger_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PointsLedgerEntryAdapter extends TypeAdapter<PointsLedgerEntry> {
  @override
  final int typeId = 30;

  @override
  PointsLedgerEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointsLedgerEntry(
      id: fields[0] as String,
      studentId: fields[1] as String,
      delta: fields[2] as int,
      runningTotal: fields[3] as int,
      reason: fields[4] as String,
      issuedByUid: fields[5] as String,
      issuedByName: fields[6] as String,
      createdAt: fields[7] as DateTime,
      syncStatus: fields[8] as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, PointsLedgerEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.delta)
      ..writeByte(3)
      ..write(obj.runningTotal)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.issuedByUid)
      ..writeByte(6)
      ..write(obj.issuedByName)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointsLedgerEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointsLedgerEntryImpl _$$PointsLedgerEntryImplFromJson(
  Map<String, dynamic> json,
) => _$PointsLedgerEntryImpl(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  delta: (json['delta'] as num).toInt(),
  runningTotal: (json['runningTotal'] as num).toInt(),
  reason: json['reason'] as String,
  issuedByUid: json['issuedByUid'] as String,
  issuedByName: json['issuedByName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.pending,
);

Map<String, dynamic> _$$PointsLedgerEntryImplToJson(
  _$PointsLedgerEntryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'delta': instance.delta,
  'runningTotal': instance.runningTotal,
  'reason': instance.reason,
  'issuedByUid': instance.issuedByUid,
  'issuedByName': instance.issuedByName,
  'createdAt': instance.createdAt.toIso8601String(),
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
};

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
