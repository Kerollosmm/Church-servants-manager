import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'student_model.freezed.dart';
part 'student_model.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

@freezed
@HiveType(typeId: 1)
class StudentModel with _$StudentModel {
  const StudentModel._();

  const factory StudentModel({
    @HiveField(0) required String uid,
    @HiveField(1) required String docID,
    @HiveField(2) required String name,
    @HiveField(3) required String? imageUrl,
    @HiveField(4) required UserRole role,
    @HiveField(5) required String mobile,
    @HiveField(6) required Group group,
    @HiveField(7) @JsonKey(name: 'team_name') required String teamName,
    @HiveField(8) @JsonKey(name: 'mother_number') required String motherPhone,
    @HiveField(9) @JsonKey(name: 'father_number') required String fatherPhone,
    @HiveField(10) required int grade,
    @HiveField(11)
    @JsonKey(name: 'education_stage')
    required EducationStage educationStage,
    @HiveField(12) @JsonKey(name: 'school_college') required String? school,
    @HiveField(13) required String? address,
    @HiveField(14) @_TimestampConverter() required DateTime? birthdate,
    @HiveField(15)
    @JsonKey(name: 'father_of_confession')
    required String fatherOfConfession,
    @HiveField(16) required String? notes,

    @HiveField(17) @Default(false) bool isArchived,
    @HiveField(18) @_TimestampConverter() DateTime? archivedAt,
    @HiveField(19) String? archivedByUserId,
    @HiveField(20) String? archiveReason,
    @HiveField(21) @_TimestampConverter() DateTime? restoredAt,
    @HiveField(22) String? restoredByUserId,

    /// Class ID for efficient querying - enables single query instead of N+1.
    @HiveField(23) String? classId,

    /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
    @HiveField(24) Map<String, dynamic>? attendanceSummary,

    @HiveField(25) @Default(SyncStatus.synced) SyncStatus syncStatus,
    @HiveField(26) @_TimestampConverter() DateTime? clientUpdatedAt,

    /// Sector this student belongs to (e.g. 'primary_boys', 'youth').
    /// Used for servant sector-scoped RBAC in Firestore Security Rules.
    @HiveField(27) String? sectorId,

    /// Whether the student has been flagged for pastoral visitation.
    @HiveField(28) @Default(false) bool needsVisitation,

    /// Timestamp of the student's last absence (set by attendance engine).
    @HiveField(29) @_TimestampConverter() DateTime? lastAbsentDate,
  }) = _StudentModel;

  /// Creates a StudentModel from JSON.
  factory StudentModel.fromJson(Map<String, dynamic> json) =>
      _$StudentModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory StudentModel.fromMap(Map<String, dynamic> data, String docId) {
    String? readString(String key) {
      final value = data[key];
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    int? readInt(String key) {
      final value = data[key];
      if (value == null) return null;
      if (value is num) {
        // Only accept true integers or doubles with no fractional part
        if (value % 1 == 0) return value.toInt();
        return null;
      }
      if (value is String) return int.tryParse(value);
      return null;
    }

    return StudentModel.fromJson({
      ...data,
      'uid': readString('uid') ?? '',
      'docID': readString('docID') ?? docId,
      'name': readString('name') ?? '',
      'mobile': readString('mobile') ?? '',
      'team_name': readString('team_name') ?? '',
      'mother_number': readString('mother_number') ?? '',
      'father_number': readString('father_number') ?? '',
      'school_college': readString('school_college'),
      'address': readString('address'),
      'father_of_confession': readString('father_of_confession') ?? '',
      'notes': readString('notes'),
      'classId': readString('classId'),
      'imageUrl': readString('imageUrl'),
      'grade': readInt('grade') ?? 1,
      'role': readString('role') ?? 'student',
      'group': readString('group') ?? 'year1',
      'education_stage': readString('education_stage') ?? 'highSchool',
      'syncStatus': readString('syncStatus') ?? 'synced',
      'sectorId': readString('sectorId') ?? readString('group'),
      'needsVisitation': data['needsVisitation'] as bool? ?? false,
      'lastAbsentDate': data['lastAbsentDate'],
    });
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();

  bool get isActive => !isArchived;

  /// Returns true if the student needs visitation and the last absence
  /// was more than 7 days ago, indicating the visit is overdue.
  bool get isOverdueForVisitation {
    if (!needsVisitation) return false;
    if (lastAbsentDate == null) return false;
    return DateTime.now().difference(lastAbsentDate!).inDays > 7;
  }

  /// Returns true if all required fields are filled.
  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
        mobile.trim().isNotEmpty &&
        motherPhone.trim().isNotEmpty &&
        fatherPhone.trim().isNotEmpty &&
        fatherOfConfession.trim().isNotEmpty &&
        (classId?.trim().isNotEmpty ?? false);
  }
}
