import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'attendance_mark.freezed.dart';
part 'attendance_mark.g.dart';

typedef _RequiredTimestampConverter = RequiredFirestoreTimestampConverter;

// ignore_for_file: invalid_annotation_target

@freezed
@HiveType(typeId: 50)
class AttendanceMark with _$AttendanceMark {
  const AttendanceMark._();

  const factory AttendanceMark({
    /// The student document ID (used as the Firestore mark document ID).
    @HiveField(0) required String studentId,

    /// The student's display name captured at mark time.
    @HiveField(1) required String studentNameSnapshot,

    /// Optional UID of the student's auth account (null if student has no account).
    @HiveField(2) String? studentUid,

    /// The attendance status of the student.
    @HiveField(3)
    @AttendanceMarkStatusJsonConverter()
    required AttendanceMarkStatus status,

    /// UID of the servant/admin who created this mark.
    @HiveField(4) required String markedByUserId,

    /// Name of the servant/admin who created this mark.
    @HiveField(5) required String markedByName,

    /// Device-side timestamp when the mark was first created.
    @HiveField(6) @_RequiredTimestampConverter() required DateTime markedAt,

    /// Device-side timestamp of the last update to this mark.
    @HiveField(7) @_RequiredTimestampConverter() required DateTime updatedAt,

    /// Server-side timestamp set by Firestore on write (nullable).
    @HiveField(8) @FirestoreTimestampConverter() DateTime? serverUpdatedAt,

    /// Optional note added by the servant when marking.
    @HiveField(9) String? note,
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
    return toJson()
      ..remove('studentId')
      // Remove serverUpdatedAt from client writes — Firestore sets it.
      ..remove('serverUpdatedAt');
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
