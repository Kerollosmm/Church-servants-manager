// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentModelAdapter extends TypeAdapter<StudentModel> {
  @override
  final int typeId = 1;

  @override
  StudentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentModel(
      uid: fields[0] as String,
      docID: fields[1] as String,
      name: fields[2] as String,
      imageUrl: fields[3] as String?,
      role: fields[4] as UserRole,
      mobile: fields[5] as String,
      group: fields[6] as Group,
      teamName: fields[7] as String,
      motherPhone: fields[8] as String,
      fatherPhone: fields[9] as String,
      grade: fields[10] as int,
      educationStage: fields[11] as EducationStage,
      school: fields[12] as String?,
      address: fields[13] as String?,
      birthdate: fields[14] as DateTime?,
      fatherOfConfession: fields[15] as String,
      notes: fields[16] as String?,
      isArchived: fields[17] as bool,
      archivedAt: fields[18] as DateTime?,
      archivedByUserId: fields[19] as String?,
      archiveReason: fields[20] as String?,
      restoredAt: fields[21] as DateTime?,
      restoredByUserId: fields[22] as String?,
      classId: fields[23] as String?,
      attendanceSummary: (fields[24] as Map?)?.cast<String, dynamic>(),
      syncStatus: fields[25] as SyncStatus,
      clientUpdatedAt: fields[26] as DateTime?,
      sectorId: fields[27] as String?,
      needsVisitation: fields[28] as bool,
      lastAbsentDate: fields[29] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentModel obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.docID)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.mobile)
      ..writeByte(6)
      ..write(obj.group)
      ..writeByte(7)
      ..write(obj.teamName)
      ..writeByte(8)
      ..write(obj.motherPhone)
      ..writeByte(9)
      ..write(obj.fatherPhone)
      ..writeByte(10)
      ..write(obj.grade)
      ..writeByte(11)
      ..write(obj.educationStage)
      ..writeByte(12)
      ..write(obj.school)
      ..writeByte(13)
      ..write(obj.address)
      ..writeByte(14)
      ..write(obj.birthdate)
      ..writeByte(15)
      ..write(obj.fatherOfConfession)
      ..writeByte(16)
      ..write(obj.notes)
      ..writeByte(17)
      ..write(obj.isArchived)
      ..writeByte(18)
      ..write(obj.archivedAt)
      ..writeByte(19)
      ..write(obj.archivedByUserId)
      ..writeByte(20)
      ..write(obj.archiveReason)
      ..writeByte(21)
      ..write(obj.restoredAt)
      ..writeByte(22)
      ..write(obj.restoredByUserId)
      ..writeByte(23)
      ..write(obj.classId)
      ..writeByte(24)
      ..write(obj.attendanceSummary)
      ..writeByte(25)
      ..write(obj.syncStatus)
      ..writeByte(26)
      ..write(obj.clientUpdatedAt)
      ..writeByte(27)
      ..write(obj.sectorId)
      ..writeByte(28)
      ..write(obj.needsVisitation)
      ..writeByte(29)
      ..write(obj.lastAbsentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentModelImpl _$$StudentModelImplFromJson(
  Map<String, dynamic> json,
) => _$StudentModelImpl(
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
  educationStage: $enumDecode(_$EducationStageEnumMap, json['education_stage']),
  school: json['school_college'] as String?,
  address: json['address'] as String?,
  birthdate: const FirestoreTimestampConverter().fromJson(json['birthdate']),
  fatherOfConfession: json['father_of_confession'] as String,
  notes: json['notes'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  archivedAt: const FirestoreTimestampConverter().fromJson(json['archivedAt']),
  archivedByUserId: json['archivedByUserId'] as String?,
  archiveReason: json['archiveReason'] as String?,
  restoredAt: const FirestoreTimestampConverter().fromJson(json['restoredAt']),
  restoredByUserId: json['restoredByUserId'] as String?,
  classId: json['classId'] as String?,
  attendanceSummary: json['attendanceSummary'] as Map<String, dynamic>?,
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.synced,
  clientUpdatedAt: const FirestoreTimestampConverter().fromJson(
    json['clientUpdatedAt'],
  ),
  sectorId: json['sectorId'] as String?,
  needsVisitation: json['needsVisitation'] as bool? ?? false,
  lastAbsentDate: const FirestoreTimestampConverter().fromJson(
    json['lastAbsentDate'],
  ),
);

Map<String, dynamic> _$$StudentModelImplToJson(
  _$StudentModelImpl instance,
) => <String, dynamic>{
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
  'birthdate': const FirestoreTimestampConverter().toJson(instance.birthdate),
  'father_of_confession': instance.fatherOfConfession,
  'notes': instance.notes,
  'isArchived': instance.isArchived,
  'archivedAt': const FirestoreTimestampConverter().toJson(instance.archivedAt),
  'archivedByUserId': instance.archivedByUserId,
  'archiveReason': instance.archiveReason,
  'restoredAt': const FirestoreTimestampConverter().toJson(instance.restoredAt),
  'restoredByUserId': instance.restoredByUserId,
  'classId': instance.classId,
  'attendanceSummary': instance.attendanceSummary,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
  'clientUpdatedAt': const FirestoreTimestampConverter().toJson(
    instance.clientUpdatedAt,
  ),
  'sectorId': instance.sectorId,
  'needsVisitation': instance.needsVisitation,
  'lastAbsentDate': const FirestoreTimestampConverter().toJson(
    instance.lastAbsentDate,
  ),
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

const _$SyncStatusEnumMap = {
  SyncStatus.pending: 'pending',
  SyncStatus.synced: 'synced',
  SyncStatus.failed: 'failed',
};
