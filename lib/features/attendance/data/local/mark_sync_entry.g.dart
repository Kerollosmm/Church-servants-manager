// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_sync_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarkSyncEntryAdapter extends TypeAdapter<MarkSyncEntry> {
  @override
  final int typeId = 51;

  @override
  MarkSyncEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarkSyncEntry(
      id: fields[0] as String,
      teamId: fields[1] as String,
      sessionId: fields[2] as String,
      studentId: fields[3] as String,
      operation: fields[4] as MarkSyncOperation,
      markData: (fields[5] as Map?)?.cast<String, dynamic>(),
      queuedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MarkSyncEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.studentId)
      ..writeByte(4)
      ..write(obj.operation)
      ..writeByte(5)
      ..write(obj.markData)
      ..writeByte(6)
      ..write(obj.queuedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkSyncEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MarkSyncOperationAdapter extends TypeAdapter<MarkSyncOperation> {
  @override
  final int typeId = 52;

  @override
  MarkSyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MarkSyncOperation.create;
      case 1:
        return MarkSyncOperation.update;
      case 2:
        return MarkSyncOperation.delete;
      default:
        return MarkSyncOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, MarkSyncOperation obj) {
    switch (obj) {
      case MarkSyncOperation.create:
        writer.writeByte(0);
        break;
      case MarkSyncOperation.update:
        writer.writeByte(1);
        break;
      case MarkSyncOperation.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkSyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
