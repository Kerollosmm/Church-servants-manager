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
    });
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();

  bool get isActive => !isArchived;

  String? get canonicalLinkedUserId {
    final normalized = uid.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
