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
    /// The student document ID (used as the Firestore mark document ID).
    required String studentId,

    /// The student's display name captured at mark time.
    required String studentNameSnapshot,

    /// Optional UID of the student's auth account (null if student has no account).
    String? studentUid,

    /// The attendance status of the student.
    @AttendanceMarkStatusJsonConverter() required AttendanceMarkStatus status,

    /// UID of the servant/admin who created this mark.
    required String markedByUserId,

    /// Name of the servant/admin who created this mark.
    required String markedByName,

    /// Device-side timestamp when the mark was first created.
    @_RequiredTimestampConverter() required DateTime markedAt,

    /// Device-side timestamp of the last update to this mark.
    @_RequiredTimestampConverter() required DateTime updatedAt,

    /// Server-side timestamp set by Firestore on write (nullable).
    @FirestoreTimestampConverter() DateTime? serverUpdatedAt,

    /// Optional note added by the servant when marking.
    String? note,
  }) = _AttendanceMark;

  factory AttendanceMark.fromJson(Map<String, dynamic> json) =>
      _$AttendanceMarkFromJson(json);

  /// Whether this mark represents the student being present (present or late).
  bool get isPresent => status == AttendanceMarkStatus.present;

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
    final markedAt =
        converter.fromJson(data['markedAt']) ??
        converter.fromJson(data['updatedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return AttendanceMark.fromJson({
      ...data,
      'studentId': studentDocId,
      'studentNameSnapshot': readString('studentNameSnapshot') ?? '',
      'status': readString('status') ?? AttendanceMarkStatus.present.name,
      'studentUid': readString('studentUid'),
      'markedByUserId': readString('markedByUserId') ?? '',
      'markedByName': readString('markedByName') ?? '',
      'markedAt': markedAt,
      'updatedAt': converter.fromJson(data['updatedAt']) ?? markedAt,
      'serverUpdatedAt': converter.fromJson(data['serverUpdatedAt']),
      'note': readString('note'),
    });
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    map.remove('studentId');
    // Remove serverUpdatedAt from client writes — Firestore sets it.
    map.remove('serverUpdatedAt');
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
      case 'absent':
        return AttendanceMarkStatus.absent;
      case 'present':
      default:
        return AttendanceMarkStatus.present;
    }
  }

  @override
  String toJson(AttendanceMarkStatus object) => object.name;
}
