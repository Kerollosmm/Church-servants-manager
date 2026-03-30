import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_mark.freezed.dart';
part 'attendance_mark.g.dart';

typedef _RequiredTimestampConverter = RequiredFirestoreTimestampConverter;

// ignore_for_file: invalid_annotation_target

@freezed
class AttendanceMark with _$AttendanceMark {
  const AttendanceMark._();

  const factory AttendanceMark({
    required String studentId,
    required String studentNameSnapshot,
    @AttendanceMarkStatusJsonConverter() required AttendanceMarkStatus status,
    required String markedByUserId,
    required String markedByName,
    @_RequiredTimestampConverter() required DateTime markedAt,
    @_RequiredTimestampConverter() required DateTime updatedAt,
    String? note,
  }) = _AttendanceMark;

  factory AttendanceMark.fromJson(Map<String, dynamic> json) =>
      _$AttendanceMarkFromJson(json);

  factory AttendanceMark.fromMap(
    Map<String, dynamic> data,
    String studentDocId,
  ) {
    String? readString(String key) {
      final value = data[key];
      if (value == null) return null;
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    final converter = const FirestoreTimestampConverter();
    final updatedAt = converter.fromJson(data['updatedAt']);
    final markedAt =
        converter.fromJson(data['markedAt']) ??
        updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return AttendanceMark.fromJson({
      ...data,
      'studentId': studentDocId,
      'studentNameSnapshot': readString('studentNameSnapshot') ?? '',
      'status': readString('status') ?? AttendanceMarkStatus.present.name,
      'markedByUserId': readString('markedByUserId') ?? '',
      'markedByName': readString('markedByName') ?? '',
      'markedAt': markedAt,
      'updatedAt': updatedAt ?? markedAt,
      'note': readString('note'),
    });
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    map.remove('studentId');
    return map;
  }
}

class AttendanceMarkStatusJsonConverter
    implements JsonConverter<AttendanceMarkStatus, String?> {
  const AttendanceMarkStatusJsonConverter();

  @override
  AttendanceMarkStatus fromJson(String? json) {
    switch (json?.trim().toLowerCase()) {
      case 'late':
        return AttendanceMarkStatus.late;
      case 'present':
      default:
        return AttendanceMarkStatus.present;
    }
  }

  @override
  String toJson(AttendanceMarkStatus object) => object.name;
}
