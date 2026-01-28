// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentModelsImpl _$$StudentModelsImplFromJson(Map<String, dynamic> json) =>
    _$StudentModelsImpl(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      eductionStage:
          $enumDecode(_$EducationStageEnumMap, json['eductionStage']),
      phoneNumber: json['phoneNumber'] as String,
      parentsPhone: (json['parentsPhone'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      group: $enumDecode(_$GroupEnumMap, json['group']),
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$$StudentModelsImplToJson(_$StudentModelsImpl instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'name': instance.name,
      'grade': instance.grade,
      'eductionStage': _$EducationStageEnumMap[instance.eductionStage]!,
      'phoneNumber': instance.phoneNumber,
      'parentsPhone': instance.parentsPhone,
      'group': _$GroupEnumMap[instance.group]!,
      'createdBy': instance.createdBy,
    };

const _$EducationStageEnumMap = {
  EducationStage.preparatory: 'preparatory',
  EducationStage.collage: 'collage',
  EducationStage.hightSchool: 'hightSchool',
};

const _$GroupEnumMap = {
  Group.year1: 'year1',
  Group.year2: 'year2',
  Group.year3: 'year3',
};
