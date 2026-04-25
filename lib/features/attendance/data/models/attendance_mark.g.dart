// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_mark.dart';

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
