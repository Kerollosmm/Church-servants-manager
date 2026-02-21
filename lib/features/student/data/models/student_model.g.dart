// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentModelImpl _$$StudentModelImplFromJson(Map<String, dynamic> json) =>
    _$StudentModelImpl(
      uid: json['uid'] as String,
      docID: json['docID'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      mobile: json['mobile'] as String,
      group: $enumDecode(_$GroupEnumMap, json['group']),
      teamName: json['team_name'] as String,
      motherPhone: json['mother_number'] as String,
      fatherPhone: json['father_number'] as String,
      grade: (json['grade'] as num).toInt(),
      educationStage: $enumDecode(
        _$EducationStageEnumMap,
        json['education_stage'],
      ),
      school: json['school_college'] as String?,
      address: json['address'] as String?,
      birthdate: const _TimestampConverter().fromJson(json['birthdate']),
      fatherOfConfession: json['father_of_confession'] as String,
      notes: json['notes'] as String?,
      classId: json['classId'] as String?,
    );

Map<String, dynamic> _$$StudentModelImplToJson(_$StudentModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'docID': instance.docID,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'role': _$UserRoleEnumMap[instance.role]!,
      'mobile': instance.mobile,
      'group': _$GroupEnumMap[instance.group]!,
      'team_name': instance.teamName,
      'mother_number': instance.motherPhone,
      'father_number': instance.fatherPhone,
      'grade': instance.grade,
      'education_stage': _$EducationStageEnumMap[instance.educationStage]!,
      'school_college': instance.school,
      'address': instance.address,
      'birthdate': const _TimestampConverter().toJson(instance.birthdate),
      'father_of_confession': instance.fatherOfConfession,
      'notes': instance.notes,
      'classId': instance.classId,
    };

const _$UserRoleEnumMap = {
  UserRole.servant: 'servant',
  UserRole.student: 'student',
  UserRole.admin: 'admin',
};

const _$GroupEnumMap = {
  Group.year1: 'year1',
  Group.year2: 'year2',
  Group.year3: 'year3',
};

const _$EducationStageEnumMap = {
  EducationStage.preparatory: 'preparatory',
  EducationStage.highSchool: 'highSchool',
  EducationStage.college: 'college',
};
