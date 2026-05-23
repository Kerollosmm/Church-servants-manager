// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StudentModel _$StudentModelFromJson(Map<String, dynamic> json) {
  return _StudentModel.fromJson(json);
}

/// @nodoc
mixin _$StudentModel {
  @HiveField(0)
  String get uid => throw _privateConstructorUsedError;
  @HiveField(1)
  String get docID => throw _privateConstructorUsedError;
  @HiveField(2)
  String get name => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get imageUrl => throw _privateConstructorUsedError;
  @HiveField(4)
  UserRole get role => throw _privateConstructorUsedError;
  @HiveField(5)
  String get mobile => throw _privateConstructorUsedError;
  @HiveField(6)
  Group get group => throw _privateConstructorUsedError;
  @HiveField(7)
  @JsonKey(name: 'team_name')
  String get teamName => throw _privateConstructorUsedError;
  @HiveField(8)
  @JsonKey(name: 'mother_number')
  String get motherPhone => throw _privateConstructorUsedError;
  @HiveField(9)
  @JsonKey(name: 'father_number')
  String get fatherPhone => throw _privateConstructorUsedError;
  @HiveField(10)
  int get grade => throw _privateConstructorUsedError;
  @HiveField(11)
  @JsonKey(name: 'education_stage')
  EducationStage get educationStage => throw _privateConstructorUsedError;
  @HiveField(12)
  @JsonKey(name: 'school_college')
  String? get school => throw _privateConstructorUsedError;
  @HiveField(13)
  String? get address => throw _privateConstructorUsedError;
  @HiveField(14)
  @_TimestampConverter()
  DateTime? get birthdate => throw _privateConstructorUsedError;
  @HiveField(15)
  @JsonKey(name: 'father_of_confession')
  String get fatherOfConfession => throw _privateConstructorUsedError;
  @HiveField(16)
  String? get notes => throw _privateConstructorUsedError;
  @HiveField(17)
  bool get isArchived => throw _privateConstructorUsedError;
  @HiveField(18)
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  @HiveField(19)
  String? get archivedByUserId => throw _privateConstructorUsedError;
  @HiveField(20)
  String? get archiveReason => throw _privateConstructorUsedError;
  @HiveField(21)
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  @HiveField(22)
  String? get restoredByUserId => throw _privateConstructorUsedError;

  /// Class ID for efficient querying - enables single query instead of N+1.
  @HiveField(23)
  String? get classId => throw _privateConstructorUsedError;

  /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
  @HiveField(24)
  Map<String, dynamic>? get attendanceSummary =>
      throw _privateConstructorUsedError;
  @HiveField(25)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  @HiveField(26)
  @_TimestampConverter()
  DateTime? get clientUpdatedAt => throw _privateConstructorUsedError;

  /// Sector this student belongs to (e.g. 'primary_boys', 'youth').
  /// Used for servant sector-scoped RBAC in Firestore Security Rules.
  @HiveField(27)
  String? get sectorId => throw _privateConstructorUsedError;

  /// Whether the student has been flagged for pastoral visitation.
  @HiveField(28)
  bool get needsVisitation => throw _privateConstructorUsedError;

  /// Timestamp of the student's last absence (set by attendance engine).
  @HiveField(29)
  @_TimestampConverter()
  DateTime? get lastAbsentDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentModelCopyWith<StudentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentModelCopyWith<$Res> {
  factory $StudentModelCopyWith(
          StudentModel value, $Res Function(StudentModel) then) =
      _$StudentModelCopyWithImpl<$Res, StudentModel>;
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String docID,
      @HiveField(2) String name,
      @HiveField(3) String? imageUrl,
      @HiveField(4) UserRole role,
      @HiveField(5) String mobile,
      @HiveField(6) Group group,
      @HiveField(7) @JsonKey(name: 'team_name') String teamName,
      @HiveField(8) @JsonKey(name: 'mother_number') String motherPhone,
      @HiveField(9) @JsonKey(name: 'father_number') String fatherPhone,
      @HiveField(10) int grade,
      @HiveField(11)
      @JsonKey(name: 'education_stage')
      EducationStage educationStage,
      @HiveField(12) @JsonKey(name: 'school_college') String? school,
      @HiveField(13) String? address,
      @HiveField(14) @_TimestampConverter() DateTime? birthdate,
      @HiveField(15)
      @JsonKey(name: 'father_of_confession')
      String fatherOfConfession,
      @HiveField(16) String? notes,
      @HiveField(17) bool isArchived,
      @HiveField(18) @_TimestampConverter() DateTime? archivedAt,
      @HiveField(19) String? archivedByUserId,
      @HiveField(20) String? archiveReason,
      @HiveField(21) @_TimestampConverter() DateTime? restoredAt,
      @HiveField(22) String? restoredByUserId,
      @HiveField(23) String? classId,
      @HiveField(24) Map<String, dynamic>? attendanceSummary,
      @HiveField(25) SyncStatus syncStatus,
      @HiveField(26) @_TimestampConverter() DateTime? clientUpdatedAt,
      @HiveField(27) String? sectorId,
      @HiveField(28) bool needsVisitation,
      @HiveField(29) @_TimestampConverter() DateTime? lastAbsentDate});
}

/// @nodoc
class _$StudentModelCopyWithImpl<$Res, $Val extends StudentModel>
    implements $StudentModelCopyWith<$Res> {
  _$StudentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? docID = null,
    Object? name = null,
    Object? imageUrl = freezed,
    Object? role = null,
    Object? mobile = null,
    Object? group = null,
    Object? teamName = null,
    Object? motherPhone = null,
    Object? fatherPhone = null,
    Object? grade = null,
    Object? educationStage = null,
    Object? school = freezed,
    Object? address = freezed,
    Object? birthdate = freezed,
    Object? fatherOfConfession = null,
    Object? notes = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? classId = freezed,
    Object? attendanceSummary = freezed,
    Object? syncStatus = null,
    Object? clientUpdatedAt = freezed,
    Object? sectorId = freezed,
    Object? needsVisitation = null,
    Object? lastAbsentDate = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      docID: null == docID
          ? _value.docID
          : docID // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      mobile: null == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as Group,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      motherPhone: null == motherPhone
          ? _value.motherPhone
          : motherPhone // ignore: cast_nullable_to_non_nullable
              as String,
      fatherPhone: null == fatherPhone
          ? _value.fatherPhone
          : fatherPhone // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as int,
      educationStage: null == educationStage
          ? _value.educationStage
          : educationStage // ignore: cast_nullable_to_non_nullable
              as EducationStage,
      school: freezed == school
          ? _value.school
          : school // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      birthdate: freezed == birthdate
          ? _value.birthdate
          : birthdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fatherOfConfession: null == fatherOfConfession
          ? _value.fatherOfConfession
          : fatherOfConfession // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedByUserId: freezed == archivedByUserId
          ? _value.archivedByUserId
          : archivedByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      archiveReason: freezed == archiveReason
          ? _value.archiveReason
          : archiveReason // ignore: cast_nullable_to_non_nullable
              as String?,
      restoredAt: freezed == restoredAt
          ? _value.restoredAt
          : restoredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoredByUserId: freezed == restoredByUserId
          ? _value.restoredByUserId
          : restoredByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      classId: freezed == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendanceSummary: freezed == attendanceSummary
          ? _value.attendanceSummary
          : attendanceSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      clientUpdatedAt: freezed == clientUpdatedAt
          ? _value.clientUpdatedAt
          : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sectorId: freezed == sectorId
          ? _value.sectorId
          : sectorId // ignore: cast_nullable_to_non_nullable
              as String?,
      needsVisitation: null == needsVisitation
          ? _value.needsVisitation
          : needsVisitation // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAbsentDate: freezed == lastAbsentDate
          ? _value.lastAbsentDate
          : lastAbsentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentModelImplCopyWith<$Res>
    implements $StudentModelCopyWith<$Res> {
  factory _$$StudentModelImplCopyWith(
          _$StudentModelImpl value, $Res Function(_$StudentModelImpl) then) =
      __$$StudentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String uid,
      @HiveField(1) String docID,
      @HiveField(2) String name,
      @HiveField(3) String? imageUrl,
      @HiveField(4) UserRole role,
      @HiveField(5) String mobile,
      @HiveField(6) Group group,
      @HiveField(7) @JsonKey(name: 'team_name') String teamName,
      @HiveField(8) @JsonKey(name: 'mother_number') String motherPhone,
      @HiveField(9) @JsonKey(name: 'father_number') String fatherPhone,
      @HiveField(10) int grade,
      @HiveField(11)
      @JsonKey(name: 'education_stage')
      EducationStage educationStage,
      @HiveField(12) @JsonKey(name: 'school_college') String? school,
      @HiveField(13) String? address,
      @HiveField(14) @_TimestampConverter() DateTime? birthdate,
      @HiveField(15)
      @JsonKey(name: 'father_of_confession')
      String fatherOfConfession,
      @HiveField(16) String? notes,
      @HiveField(17) bool isArchived,
      @HiveField(18) @_TimestampConverter() DateTime? archivedAt,
      @HiveField(19) String? archivedByUserId,
      @HiveField(20) String? archiveReason,
      @HiveField(21) @_TimestampConverter() DateTime? restoredAt,
      @HiveField(22) String? restoredByUserId,
      @HiveField(23) String? classId,
      @HiveField(24) Map<String, dynamic>? attendanceSummary,
      @HiveField(25) SyncStatus syncStatus,
      @HiveField(26) @_TimestampConverter() DateTime? clientUpdatedAt,
      @HiveField(27) String? sectorId,
      @HiveField(28) bool needsVisitation,
      @HiveField(29) @_TimestampConverter() DateTime? lastAbsentDate});
}

/// @nodoc
class __$$StudentModelImplCopyWithImpl<$Res>
    extends _$StudentModelCopyWithImpl<$Res, _$StudentModelImpl>
    implements _$$StudentModelImplCopyWith<$Res> {
  __$$StudentModelImplCopyWithImpl(
      _$StudentModelImpl _value, $Res Function(_$StudentModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? docID = null,
    Object? name = null,
    Object? imageUrl = freezed,
    Object? role = null,
    Object? mobile = null,
    Object? group = null,
    Object? teamName = null,
    Object? motherPhone = null,
    Object? fatherPhone = null,
    Object? grade = null,
    Object? educationStage = null,
    Object? school = freezed,
    Object? address = freezed,
    Object? birthdate = freezed,
    Object? fatherOfConfession = null,
    Object? notes = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? classId = freezed,
    Object? attendanceSummary = freezed,
    Object? syncStatus = null,
    Object? clientUpdatedAt = freezed,
    Object? sectorId = freezed,
    Object? needsVisitation = null,
    Object? lastAbsentDate = freezed,
  }) {
    return _then(_$StudentModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      docID: null == docID
          ? _value.docID
          : docID // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      mobile: null == mobile
          ? _value.mobile
          : mobile // ignore: cast_nullable_to_non_nullable
              as String,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as Group,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      motherPhone: null == motherPhone
          ? _value.motherPhone
          : motherPhone // ignore: cast_nullable_to_non_nullable
              as String,
      fatherPhone: null == fatherPhone
          ? _value.fatherPhone
          : fatherPhone // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as int,
      educationStage: null == educationStage
          ? _value.educationStage
          : educationStage // ignore: cast_nullable_to_non_nullable
              as EducationStage,
      school: freezed == school
          ? _value.school
          : school // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      birthdate: freezed == birthdate
          ? _value.birthdate
          : birthdate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fatherOfConfession: null == fatherOfConfession
          ? _value.fatherOfConfession
          : fatherOfConfession // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedByUserId: freezed == archivedByUserId
          ? _value.archivedByUserId
          : archivedByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      archiveReason: freezed == archiveReason
          ? _value.archiveReason
          : archiveReason // ignore: cast_nullable_to_non_nullable
              as String?,
      restoredAt: freezed == restoredAt
          ? _value.restoredAt
          : restoredAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoredByUserId: freezed == restoredByUserId
          ? _value.restoredByUserId
          : restoredByUserId // ignore: cast_nullable_to_non_nullable
              as String?,
      classId: freezed == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String?,
      attendanceSummary: freezed == attendanceSummary
          ? _value._attendanceSummary
          : attendanceSummary // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      clientUpdatedAt: freezed == clientUpdatedAt
          ? _value.clientUpdatedAt
          : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sectorId: freezed == sectorId
          ? _value.sectorId
          : sectorId // ignore: cast_nullable_to_non_nullable
              as String?,
      needsVisitation: null == needsVisitation
          ? _value.needsVisitation
          : needsVisitation // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAbsentDate: freezed == lastAbsentDate
          ? _value.lastAbsentDate
          : lastAbsentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentModelImpl extends _StudentModel {
  const _$StudentModelImpl(
      {@HiveField(0) required this.uid,
      @HiveField(1) required this.docID,
      @HiveField(2) required this.name,
      @HiveField(3) required this.imageUrl,
      @HiveField(4) required this.role,
      @HiveField(5) required this.mobile,
      @HiveField(6) required this.group,
      @HiveField(7) @JsonKey(name: 'team_name') required this.teamName,
      @HiveField(8) @JsonKey(name: 'mother_number') required this.motherPhone,
      @HiveField(9) @JsonKey(name: 'father_number') required this.fatherPhone,
      @HiveField(10) required this.grade,
      @HiveField(11)
      @JsonKey(name: 'education_stage')
      required this.educationStage,
      @HiveField(12) @JsonKey(name: 'school_college') required this.school,
      @HiveField(13) required this.address,
      @HiveField(14) @_TimestampConverter() required this.birthdate,
      @HiveField(15)
      @JsonKey(name: 'father_of_confession')
      required this.fatherOfConfession,
      @HiveField(16) required this.notes,
      @HiveField(17) this.isArchived = false,
      @HiveField(18) @_TimestampConverter() this.archivedAt,
      @HiveField(19) this.archivedByUserId,
      @HiveField(20) this.archiveReason,
      @HiveField(21) @_TimestampConverter() this.restoredAt,
      @HiveField(22) this.restoredByUserId,
      @HiveField(23) this.classId,
      @HiveField(24) final Map<String, dynamic>? attendanceSummary,
      @HiveField(25) this.syncStatus = SyncStatus.synced,
      @HiveField(26) @_TimestampConverter() this.clientUpdatedAt,
      @HiveField(27) this.sectorId,
      @HiveField(28) this.needsVisitation = false,
      @HiveField(29) @_TimestampConverter() this.lastAbsentDate})
      : _attendanceSummary = attendanceSummary,
        super._();

  factory _$StudentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentModelImplFromJson(json);

  @override
  @HiveField(0)
  final String uid;
  @override
  @HiveField(1)
  final String docID;
  @override
  @HiveField(2)
  final String name;
  @override
  @HiveField(3)
  final String? imageUrl;
  @override
  @HiveField(4)
  final UserRole role;
  @override
  @HiveField(5)
  final String mobile;
  @override
  @HiveField(6)
  final Group group;
  @override
  @HiveField(7)
  @JsonKey(name: 'team_name')
  final String teamName;
  @override
  @HiveField(8)
  @JsonKey(name: 'mother_number')
  final String motherPhone;
  @override
  @HiveField(9)
  @JsonKey(name: 'father_number')
  final String fatherPhone;
  @override
  @HiveField(10)
  final int grade;
  @override
  @HiveField(11)
  @JsonKey(name: 'education_stage')
  final EducationStage educationStage;
  @override
  @HiveField(12)
  @JsonKey(name: 'school_college')
  final String? school;
  @override
  @HiveField(13)
  final String? address;
  @override
  @HiveField(14)
  @_TimestampConverter()
  final DateTime? birthdate;
  @override
  @HiveField(15)
  @JsonKey(name: 'father_of_confession')
  final String fatherOfConfession;
  @override
  @HiveField(16)
  final String? notes;
  @override
  @JsonKey()
  @HiveField(17)
  final bool isArchived;
  @override
  @HiveField(18)
  @_TimestampConverter()
  final DateTime? archivedAt;
  @override
  @HiveField(19)
  final String? archivedByUserId;
  @override
  @HiveField(20)
  final String? archiveReason;
  @override
  @HiveField(21)
  @_TimestampConverter()
  final DateTime? restoredAt;
  @override
  @HiveField(22)
  final String? restoredByUserId;

  /// Class ID for efficient querying - enables single query instead of N+1.
  @override
  @HiveField(23)
  final String? classId;

  /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
  final Map<String, dynamic>? _attendanceSummary;

  /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
  @override
  @HiveField(24)
  Map<String, dynamic>? get attendanceSummary {
    final value = _attendanceSummary;
    if (value == null) return null;
    if (_attendanceSummary is EqualUnmodifiableMapView)
      return _attendanceSummary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  @HiveField(25)
  final SyncStatus syncStatus;
  @override
  @HiveField(26)
  @_TimestampConverter()
  final DateTime? clientUpdatedAt;

  /// Sector this student belongs to (e.g. 'primary_boys', 'youth').
  /// Used for servant sector-scoped RBAC in Firestore Security Rules.
  @override
  @HiveField(27)
  final String? sectorId;

  /// Whether the student has been flagged for pastoral visitation.
  @override
  @JsonKey()
  @HiveField(28)
  final bool needsVisitation;

  /// Timestamp of the student's last absence (set by attendance engine).
  @override
  @HiveField(29)
  @_TimestampConverter()
  final DateTime? lastAbsentDate;

  @override
  String toString() {
    return 'StudentModel(uid: $uid, docID: $docID, name: $name, imageUrl: $imageUrl, role: $role, mobile: $mobile, group: $group, teamName: $teamName, motherPhone: $motherPhone, fatherPhone: $fatherPhone, grade: $grade, educationStage: $educationStage, school: $school, address: $address, birthdate: $birthdate, fatherOfConfession: $fatherOfConfession, notes: $notes, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, classId: $classId, attendanceSummary: $attendanceSummary, syncStatus: $syncStatus, clientUpdatedAt: $clientUpdatedAt, sectorId: $sectorId, needsVisitation: $needsVisitation, lastAbsentDate: $lastAbsentDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.docID, docID) || other.docID == docID) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.motherPhone, motherPhone) ||
                other.motherPhone == motherPhone) &&
            (identical(other.fatherPhone, fatherPhone) ||
                other.fatherPhone == fatherPhone) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.educationStage, educationStage) ||
                other.educationStage == educationStage) &&
            (identical(other.school, school) || other.school == school) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.birthdate, birthdate) ||
                other.birthdate == birthdate) &&
            (identical(other.fatherOfConfession, fatherOfConfession) ||
                other.fatherOfConfession == fatherOfConfession) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.archivedByUserId, archivedByUserId) ||
                other.archivedByUserId == archivedByUserId) &&
            (identical(other.archiveReason, archiveReason) ||
                other.archiveReason == archiveReason) &&
            (identical(other.restoredAt, restoredAt) ||
                other.restoredAt == restoredAt) &&
            (identical(other.restoredByUserId, restoredByUserId) ||
                other.restoredByUserId == restoredByUserId) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            const DeepCollectionEquality()
                .equals(other._attendanceSummary, _attendanceSummary) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.clientUpdatedAt, clientUpdatedAt) ||
                other.clientUpdatedAt == clientUpdatedAt) &&
            (identical(other.sectorId, sectorId) ||
                other.sectorId == sectorId) &&
            (identical(other.needsVisitation, needsVisitation) ||
                other.needsVisitation == needsVisitation) &&
            (identical(other.lastAbsentDate, lastAbsentDate) ||
                other.lastAbsentDate == lastAbsentDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        uid,
        docID,
        name,
        imageUrl,
        role,
        mobile,
        group,
        teamName,
        motherPhone,
        fatherPhone,
        grade,
        educationStage,
        school,
        address,
        birthdate,
        fatherOfConfession,
        notes,
        isArchived,
        archivedAt,
        archivedByUserId,
        archiveReason,
        restoredAt,
        restoredByUserId,
        classId,
        const DeepCollectionEquality().hash(_attendanceSummary),
        syncStatus,
        clientUpdatedAt,
        sectorId,
        needsVisitation,
        lastAbsentDate
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentModelImplCopyWith<_$StudentModelImpl> get copyWith =>
      __$$StudentModelImplCopyWithImpl<_$StudentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentModelImplToJson(
      this,
    );
  }
}

abstract class _StudentModel extends StudentModel {
  const factory _StudentModel(
      {@HiveField(0) required final String uid,
      @HiveField(1) required final String docID,
      @HiveField(2) required final String name,
      @HiveField(3) required final String? imageUrl,
      @HiveField(4) required final UserRole role,
      @HiveField(5) required final String mobile,
      @HiveField(6) required final Group group,
      @HiveField(7) @JsonKey(name: 'team_name') required final String teamName,
      @HiveField(8)
      @JsonKey(name: 'mother_number')
      required final String motherPhone,
      @HiveField(9)
      @JsonKey(name: 'father_number')
      required final String fatherPhone,
      @HiveField(10) required final int grade,
      @HiveField(11)
      @JsonKey(name: 'education_stage')
      required final EducationStage educationStage,
      @HiveField(12)
      @JsonKey(name: 'school_college')
      required final String? school,
      @HiveField(13) required final String? address,
      @HiveField(14) @_TimestampConverter() required final DateTime? birthdate,
      @HiveField(15)
      @JsonKey(name: 'father_of_confession')
      required final String fatherOfConfession,
      @HiveField(16) required final String? notes,
      @HiveField(17) final bool isArchived,
      @HiveField(18) @_TimestampConverter() final DateTime? archivedAt,
      @HiveField(19) final String? archivedByUserId,
      @HiveField(20) final String? archiveReason,
      @HiveField(21) @_TimestampConverter() final DateTime? restoredAt,
      @HiveField(22) final String? restoredByUserId,
      @HiveField(23) final String? classId,
      @HiveField(24) final Map<String, dynamic>? attendanceSummary,
      @HiveField(25) final SyncStatus syncStatus,
      @HiveField(26) @_TimestampConverter() final DateTime? clientUpdatedAt,
      @HiveField(27) final String? sectorId,
      @HiveField(28) final bool needsVisitation,
      @HiveField(29)
      @_TimestampConverter()
      final DateTime? lastAbsentDate}) = _$StudentModelImpl;
  const _StudentModel._() : super._();

  factory _StudentModel.fromJson(Map<String, dynamic> json) =
      _$StudentModelImpl.fromJson;

  @override
  @HiveField(0)
  String get uid;
  @override
  @HiveField(1)
  String get docID;
  @override
  @HiveField(2)
  String get name;
  @override
  @HiveField(3)
  String? get imageUrl;
  @override
  @HiveField(4)
  UserRole get role;
  @override
  @HiveField(5)
  String get mobile;
  @override
  @HiveField(6)
  Group get group;
  @override
  @HiveField(7)
  @JsonKey(name: 'team_name')
  String get teamName;
  @override
  @HiveField(8)
  @JsonKey(name: 'mother_number')
  String get motherPhone;
  @override
  @HiveField(9)
  @JsonKey(name: 'father_number')
  String get fatherPhone;
  @override
  @HiveField(10)
  int get grade;
  @override
  @HiveField(11)
  @JsonKey(name: 'education_stage')
  EducationStage get educationStage;
  @override
  @HiveField(12)
  @JsonKey(name: 'school_college')
  String? get school;
  @override
  @HiveField(13)
  String? get address;
  @override
  @HiveField(14)
  @_TimestampConverter()
  DateTime? get birthdate;
  @override
  @HiveField(15)
  @JsonKey(name: 'father_of_confession')
  String get fatherOfConfession;
  @override
  @HiveField(16)
  String? get notes;
  @override
  @HiveField(17)
  bool get isArchived;
  @override
  @HiveField(18)
  @_TimestampConverter()
  DateTime? get archivedAt;
  @override
  @HiveField(19)
  String? get archivedByUserId;
  @override
  @HiveField(20)
  String? get archiveReason;
  @override
  @HiveField(21)
  @_TimestampConverter()
  DateTime? get restoredAt;
  @override
  @HiveField(22)
  String? get restoredByUserId;
  @override

  /// Class ID for efficient querying - enables single query instead of N+1.
  @HiveField(23)
  String? get classId;
  @override

  /// Aggregated attendance metrics (totalPresent, streak, etc.) updated on session close.
  @HiveField(24)
  Map<String, dynamic>? get attendanceSummary;
  @override
  @HiveField(25)
  SyncStatus get syncStatus;
  @override
  @HiveField(26)
  @_TimestampConverter()
  DateTime? get clientUpdatedAt;
  @override

  /// Sector this student belongs to (e.g. 'primary_boys', 'youth').
  /// Used for servant sector-scoped RBAC in Firestore Security Rules.
  @HiveField(27)
  String? get sectorId;
  @override

  /// Whether the student has been flagged for pastoral visitation.
  @HiveField(28)
  bool get needsVisitation;
  @override

  /// Timestamp of the student's last absence (set by attendance engine).
  @HiveField(29)
  @_TimestampConverter()
  DateTime? get lastAbsentDate;
  @override
  @JsonKey(ignore: true)
  _$$StudentModelImplCopyWith<_$StudentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
