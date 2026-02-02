import 'package:church_managment_system/core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_model.freezed.dart';
part 'student_model.g.dart';

/// Converts Firestore Timestamp to/from Dart DateTime.
class _TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const _TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}

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
