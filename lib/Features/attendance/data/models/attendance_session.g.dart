// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceSessionImpl _$$AttendanceSessionImplFromJson(
  Map<String, dynamic> json,
) => _$AttendanceSessionImpl(
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
);

Map<String, dynamic> _$$AttendanceSessionImplToJson(
  _$AttendanceSessionImpl instance,
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
};
