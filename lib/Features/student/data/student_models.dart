import 'package:csms/core/constants/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_models.freezed.dart';
part 'student_models.g.dart';

@freezed
class StudentModels with _$StudentModels {
  const factory StudentModels({
    required String studentId,
    required String name,
    required String grade, // grade on school or collage
    required EducationStage eductionStage, // {school, collage}
    required String phoneNumber,
    required List<String> parentsPhone,
    required Group group, // GROUP NAME {YEAR1, YEAR2, YEAR3}
    required String createdBy, // servant who add the student data
  }) = _StudentModels;

  factory StudentModels.fromJson(Map<String, dynamic> json) =>
      _$StudentModelsFromJson(json);
}
