// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ??
          UserRole.student,
      grade: json['grade'] as String?,
      linkedStudentId: json['linkedStudentId'] as String?,
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'role': _$UserRoleEnumMap[instance.role]!,
      'grade': instance.grade,
      'linkedStudentId': instance.linkedStudentId,
    };

const _$UserRoleEnumMap = {
  UserRole.servant: 'servant',
  UserRole.student: 'student',
  UserRole.admin: 'admin',
};
