// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servant_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServantModelImpl _$$ServantModelImplFromJson(Map<String, dynamic> json) =>
    _$ServantModelImpl(
      uid: json['uid'] as String?,
      docID: json['docID'] as String,
      name: json['name'] as String,
      role: json['role'] == null
          ? UserRole.servant
          : const UserRoleJsonConverter().fromJson(json['role'] as String?),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['imageUrl'] as String?,
      teamName: json['groupId'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      fatherOfConfession: json['father_of_confession'] as String?,
      birthdate:
          const FirestoreTimestampConverter().fromJson(json['birthdate']),
      notes: json['notes'] as String?,
      assignedTeamId: json['assignedTeamId'] as String?,
    );

Map<String, dynamic> _$$ServantModelImplToJson(_$ServantModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'docID': instance.docID,
      'name': instance.name,
      'role': const UserRoleJsonConverter().toJson(instance.role),
      'email': instance.email,
      'phone': instance.phone,
      'imageUrl': instance.imageUrl,
      'groupId': instance.teamName,
      'isEmailVerified': instance.isEmailVerified,
      'father_of_confession': instance.fatherOfConfession,
      'birthdate':
          const FirestoreTimestampConverter().toJson(instance.birthdate),
      'notes': instance.notes,
      'assignedTeamId': instance.assignedTeamId,
    };
