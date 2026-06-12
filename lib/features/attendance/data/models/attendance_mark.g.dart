// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_mark.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceMarkAdapter extends TypeAdapter<AttendanceMark> {
  @override
  final int typeId = 50;

  @override
  AttendanceMark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceMark(
      studentId: fields[0] as String,
      studentNameSnapshot: fields[1] as String,
      studentUid: fields[2] as String?,
      status: fields[3] as AttendanceMarkStatus,
      markedByUserId: fields[4] as String,
      markedByName: fields[5] as String,
      markedAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      serverUpdatedAt: fields[8] as DateTime?,
      note: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceMark obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.studentNameSnapshot)
      ..writeByte(2)
      ..write(obj.studentUid)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.markedByUserId)
      ..writeByte(5)
      ..write(obj.markedByName)
      ..writeByte(6)
      ..write(obj.markedAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.serverUpdatedAt)
      ..writeByte(9)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceMarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceMarkImpl _$$AttendanceMarkImplFromJson(Map<String, dynamic> json) =>
    _$AttendanceMarkImpl(
      studentId: json['studentId'] as String,
      studentNameSnapshot: json['studentNameSnapshot'] as String,
      studentUid: json['studentUid'] as String?,
      status: const AttendanceMarkStatusJsonConverter()
          .fromJson(json['status'] as String?),
      markedByUserId: json['markedByUserId'] as String,
      markedByName: json['markedByName'] as String,
      markedAt: const RequiredFirestoreTimestampConverter()
          .fromJson(json['markedAt']),
      updatedAt: const RequiredFirestoreTimestampConverter()
          .fromJson(json['updatedAt']),
      serverUpdatedAt:
          const FirestoreTimestampConverter().fromJson(json['serverUpdatedAt']),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$AttendanceMarkImplToJson(
        _$AttendanceMarkImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentNameSnapshot': instance.studentNameSnapshot,
      'studentUid': instance.studentUid,
      'status':
          const AttendanceMarkStatusJsonConverter().toJson(instance.status),
      'markedByUserId': instance.markedByUserId,
      'markedByName': instance.markedByName,
      'markedAt':
          const RequiredFirestoreTimestampConverter().toJson(instance.markedAt),
      'updatedAt': const RequiredFirestoreTimestampConverter()
          .toJson(instance.updatedAt),
      'serverUpdatedAt':
          const FirestoreTimestampConverter().toJson(instance.serverUpdatedAt),
      'note': instance.note,
    };
