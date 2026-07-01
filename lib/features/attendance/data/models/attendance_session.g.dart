// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceSessionModelAdapter
    extends TypeAdapter<AttendanceSessionModel> {
  @override
  final int typeId = 53;

  @override
  AttendanceSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceSessionModel(
      id: fields[0] as String,
      teamId: fields[1] as String,
      teamNameSnapshot: fields[2] as String?,
      title: fields[3] as String?,
      dateKey: fields[4] as String,
      startsAt: fields[5] as DateTime,
      endsAt: fields[6] as DateTime,
      durationMinutes: fields[7] as int,
      createdByUserId: fields[8] as String,
      createdByName: fields[9] as String,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      isClosed: fields[12] as bool,
      studentIdsSnapshot: (fields[13] as List).cast<String>(),
      studentNameSnapshots: (fields[14] as Map).cast<String, String>(),
      presentCount: fields[15] as int,
      lateCount: fields[16] as int,
      absentCount: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceSessionModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamId)
      ..writeByte(2)
      ..write(obj.teamNameSnapshot)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.dateKey)
      ..writeByte(5)
      ..write(obj.startsAt)
      ..writeByte(6)
      ..write(obj.endsAt)
      ..writeByte(7)
      ..write(obj.durationMinutes)
      ..writeByte(8)
      ..write(obj.createdByUserId)
      ..writeByte(9)
      ..write(obj.createdByName)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isClosed)
      ..writeByte(13)
      ..write(obj.studentIdsSnapshot)
      ..writeByte(14)
      ..write(obj.studentNameSnapshots)
      ..writeByte(15)
      ..write(obj.presentCount)
      ..writeByte(16)
      ..write(obj.lateCount)
      ..writeByte(17)
      ..write(obj.absentCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceSessionModelImpl _$$AttendanceSessionModelImplFromJson(
  Map<String, dynamic> json,
) => _$AttendanceSessionModelImpl(
  id: json['id'] as String,
  teamId: json['teamId'] as String,
  teamNameSnapshot: json['teamNameSnapshot'] as String?,
  title: json['title'] as String?,
  dateKey: json['dateKey'] as String,
  startsAt: const RequiredFirestoreTimestampConverter().fromJson(
    json['startsAt'],
  ),
  endsAt: const RequiredFirestoreTimestampConverter().fromJson(json['endsAt']),
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  createdByUserId: json['createdByUserId'] as String,
  createdByName: json['createdByName'] as String,
  createdAt: const RequiredFirestoreTimestampConverter().fromJson(
    json['createdAt'],
  ),
  updatedAt: const RequiredFirestoreTimestampConverter().fromJson(
    json['updatedAt'],
  ),
  isClosed: json['isClosed'] as bool? ?? false,
  studentIdsSnapshot:
      (json['studentIdsSnapshot'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  studentNameSnapshots:
      (json['studentNameSnapshots'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
  lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
  absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AttendanceSessionModelImplToJson(
  _$AttendanceSessionModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'teamId': instance.teamId,
  'teamNameSnapshot': instance.teamNameSnapshot,
  'title': instance.title,
  'dateKey': instance.dateKey,
  'startsAt': const RequiredFirestoreTimestampConverter().toJson(
    instance.startsAt,
  ),
  'endsAt': const RequiredFirestoreTimestampConverter().toJson(instance.endsAt),
  'durationMinutes': instance.durationMinutes,
  'createdByUserId': instance.createdByUserId,
  'createdByName': instance.createdByName,
  'createdAt': const RequiredFirestoreTimestampConverter().toJson(
    instance.createdAt,
  ),
  'updatedAt': const RequiredFirestoreTimestampConverter().toJson(
    instance.updatedAt,
  ),
  'isClosed': instance.isClosed,
  'studentIdsSnapshot': instance.studentIdsSnapshot,
  'studentNameSnapshots': instance.studentNameSnapshots,
  'presentCount': instance.presentCount,
  'lateCount': instance.lateCount,
  'absentCount': instance.absentCount,
};
