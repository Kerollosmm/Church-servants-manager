// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servant_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServantModelImpl _$$ServantModelImplFromJson(Map<String, dynamic> json) =>
    _$ServantModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      image: json['image'] as String,
      teamName: json['team_name'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$$ServantModelImplToJson(_$ServantModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'image': instance.image,
      'team_name': instance.teamName,
      'role': instance.role,
    };
