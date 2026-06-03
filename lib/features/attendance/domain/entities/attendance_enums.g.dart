// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceMarkStatusAdapter extends TypeAdapter<AttendanceMarkStatus> {
  @override
  final int typeId = 12;

  @override
  AttendanceMarkStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceMarkStatus.present;
      case 1:
        return AttendanceMarkStatus.late;
      case 2:
        return AttendanceMarkStatus.absent;
      default:
        return AttendanceMarkStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceMarkStatus obj) {
    switch (obj) {
      case AttendanceMarkStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceMarkStatus.late:
        writer.writeByte(1);
        break;
      case AttendanceMarkStatus.absent:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceMarkStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
