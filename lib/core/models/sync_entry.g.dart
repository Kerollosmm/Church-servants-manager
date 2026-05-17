// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncEntryAdapter extends TypeAdapter<SyncEntry> {
  @override
  final int typeId = 100;

  @override
  SyncEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncEntry(
      id: fields[0] as String,
      actionType: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
      failedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionType)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.failedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
