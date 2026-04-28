import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'student_model.freezed.dart';
part 'student_model.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

@freezed
class StudentModel with _$StudentModel {
  const StudentModel._();

  const factory StudentModel({
    required String uid,
    required String docID,
    required String name,
    required String? imageUrl,
    required UserRole role,
    required String mobile,
    required Group group,
    @JsonKey(name: 'team_name') required String teamName,
    @JsonKey(name: 'mother_number') required String motherPhone,
    @JsonKey(name: 'father_number') required String fatherPhone,
    required int grade,
    @JsonKey(name: 'education_stage') required EducationStage educationStage,
    @JsonKey(name: 'school_college') required String? school,
    required String? address,
    @_TimestampConverter() required DateTime? birthdate,
    @JsonKey(name: 'father_of_confession') required String fatherOfConfession,
    required String? notes,

    @Default(false) bool isArchived,
    @_TimestampConverter() DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    @_TimestampConverter() DateTime? restoredAt,
    String? restoredByUserId,

    /// Class ID for efficient querying - enables single query instead of N+1.
    String? classId,

    /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
    Map<String, dynamic>? attendanceSummary,

    /// AI-generated insights and encouragement messages.
    Map<String, dynamic>? aiRecommendations,
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
      if (value is num) return value.toInt();
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
    });
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();

  bool get isActive => !isArchived;

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
