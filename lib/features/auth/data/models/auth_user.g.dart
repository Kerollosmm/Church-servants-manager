// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthUserImpl _$$AuthUserImplFromJson(
  Map<String, dynamic> json,
) => _$AuthUserImpl(
  uid: json['uid'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  isEmailVerified: json['isEmailVerified'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  archivedAt: const FirestoreTimestampConverter().fromJson(json['archivedAt']),
  archivedByUserId: json['archivedByUserId'] as String?,
  archiveReason: json['archiveReason'] as String?,
  restoredAt: const FirestoreTimestampConverter().fromJson(json['restoredAt']),
  restoredByUserId: json['restoredByUserId'] as String?,
  restorePendingPasswordReset:
      json['restorePendingPasswordReset'] as bool? ?? false,
  groupId: json['groupId'] as String?,
  assignedTeamIds:
      (json['assignedTeamIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  assignedTeamId: json['assignedTeamId'] as String?,
);

Map<String, dynamic> _$$AuthUserImplToJson(
  _$AuthUserImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'name': instance.name,
  'role': _$UserRoleEnumMap[instance.role]!,
  'isEmailVerified': instance.isEmailVerified,
  'isArchived': instance.isArchived,
  'archivedAt': const FirestoreTimestampConverter().toJson(instance.archivedAt),
  'archivedByUserId': instance.archivedByUserId,
  'archiveReason': instance.archiveReason,
  'restoredAt': const FirestoreTimestampConverter().toJson(instance.restoredAt),
  'restoredByUserId': instance.restoredByUserId,
  'restorePendingPasswordReset': instance.restorePendingPasswordReset,
  'groupId': instance.groupId,
  'assignedTeamIds': instance.assignedTeamIds,
  'assignedTeamId': instance.assignedTeamId,
};

const _$UserRoleEnumMap = {
  UserRole.servant: 'servant',
  UserRole.student: 'student',
  UserRole.admin: 'admin',
};
