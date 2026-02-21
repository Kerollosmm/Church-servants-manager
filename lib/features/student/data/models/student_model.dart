import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/utils/json_converters.dart';

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

    /// Class ID for efficient querying - enables single query instead of N+1.
    String? classId,
  }) = _StudentModel;

  /// Creates a StudentModel from JSON.
  factory StudentModel.fromJson(Map<String, dynamic> json) =>
      _$StudentModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory StudentModel.fromMap(Map<String, dynamic> data, String docId) {
    return StudentModel.fromJson({...data, 'docID': docId});
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();
}
