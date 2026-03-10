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
  String get uid => throw _privateConstructorUsedError;
  String get docID => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  UserRole get role => throw _privateConstructorUsedError;
  String get mobile => throw _privateConstructorUsedError;
  Group get group => throw _privateConstructorUsedError;
  @JsonKey(name: 'team_name')
  String get teamName => throw _privateConstructorUsedError;
  @JsonKey(name: 'mother_number')
  String get motherPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'father_number')
  String get fatherPhone => throw _privateConstructorUsedError;
  int get grade => throw _privateConstructorUsedError;
  @JsonKey(name: 'education_stage')
  EducationStage get educationStage => throw _privateConstructorUsedError;
  @JsonKey(name: 'school_college')
  String? get school => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get birthdate => throw _privateConstructorUsedError;
  @JsonKey(name: 'father_of_confession')
  String get fatherOfConfession => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  String? get archivedByUserId => throw _privateConstructorUsedError;
  String? get archiveReason => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  String? get restoredByUserId => throw _privateConstructorUsedError;

  /// Class ID for efficient querying - enables single query instead of N+1.
  String? get classId => throw _privateConstructorUsedError;

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
      {String uid,
      String docID,
      String name,
      String? imageUrl,
      UserRole role,
      String mobile,
      Group group,
      @JsonKey(name: 'team_name') String teamName,
      @JsonKey(name: 'mother_number') String motherPhone,
      @JsonKey(name: 'father_number') String fatherPhone,
      int grade,
      @JsonKey(name: 'education_stage') EducationStage educationStage,
      @JsonKey(name: 'school_college') String? school,
      String? address,
      @_TimestampConverter() DateTime? birthdate,
      @JsonKey(name: 'father_of_confession') String fatherOfConfession,
      String? notes,
      bool isArchived,
      @_TimestampConverter() DateTime? archivedAt,
      String? archivedByUserId,
      String? archiveReason,
      @_TimestampConverter() DateTime? restoredAt,
      String? restoredByUserId,
      String? classId});
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
      {String uid,
      String docID,
      String name,
      String? imageUrl,
      UserRole role,
      String mobile,
      Group group,
      @JsonKey(name: 'team_name') String teamName,
      @JsonKey(name: 'mother_number') String motherPhone,
      @JsonKey(name: 'father_number') String fatherPhone,
      int grade,
      @JsonKey(name: 'education_stage') EducationStage educationStage,
      @JsonKey(name: 'school_college') String? school,
      String? address,
      @_TimestampConverter() DateTime? birthdate,
      @JsonKey(name: 'father_of_confession') String fatherOfConfession,
      String? notes,
      bool isArchived,
      @_TimestampConverter() DateTime? archivedAt,
      String? archivedByUserId,
      String? archiveReason,
      @_TimestampConverter() DateTime? restoredAt,
      String? restoredByUserId,
      String? classId});
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentModelImpl extends _StudentModel {
  const _$StudentModelImpl(
      {required this.uid,
      required this.docID,
      required this.name,
      required this.imageUrl,
      required this.role,
      required this.mobile,
      required this.group,
      @JsonKey(name: 'team_name') required this.teamName,
      @JsonKey(name: 'mother_number') required this.motherPhone,
      @JsonKey(name: 'father_number') required this.fatherPhone,
      required this.grade,
      @JsonKey(name: 'education_stage') required this.educationStage,
      @JsonKey(name: 'school_college') required this.school,
      required this.address,
      @_TimestampConverter() required this.birthdate,
      @JsonKey(name: 'father_of_confession') required this.fatherOfConfession,
      required this.notes,
      this.isArchived = false,
      @_TimestampConverter() this.archivedAt,
      this.archivedByUserId,
      this.archiveReason,
      @_TimestampConverter() this.restoredAt,
      this.restoredByUserId,
      this.classId})
      : super._();

  factory _$StudentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentModelImplFromJson(json);

  @override
  final String uid;
  @override
  final String docID;
  @override
  final String name;
  @override
  final String? imageUrl;
  @override
  final UserRole role;
  @override
  final String mobile;
  @override
  final Group group;
  @override
  @JsonKey(name: 'team_name')
  final String teamName;
  @override
  @JsonKey(name: 'mother_number')
  final String motherPhone;
  @override
  @JsonKey(name: 'father_number')
  final String fatherPhone;
  @override
  final int grade;
  @override
  @JsonKey(name: 'education_stage')
  final EducationStage educationStage;
  @override
  @JsonKey(name: 'school_college')
  final String? school;
  @override
  final String? address;
  @override
  @_TimestampConverter()
  final DateTime? birthdate;
  @override
  @JsonKey(name: 'father_of_confession')
  final String fatherOfConfession;
  @override
  final String? notes;
  @override
  @JsonKey()
  final bool isArchived;
  @override
  @_TimestampConverter()
  final DateTime? archivedAt;
  @override
  final String? archivedByUserId;
  @override
  final String? archiveReason;
  @override
  @_TimestampConverter()
  final DateTime? restoredAt;
  @override
  final String? restoredByUserId;

  /// Class ID for efficient querying - enables single query instead of N+1.
  @override
  final String? classId;

  @override
  String toString() {
    return 'StudentModel(uid: $uid, docID: $docID, name: $name, imageUrl: $imageUrl, role: $role, mobile: $mobile, group: $group, teamName: $teamName, motherPhone: $motherPhone, fatherPhone: $fatherPhone, grade: $grade, educationStage: $educationStage, school: $school, address: $address, birthdate: $birthdate, fatherOfConfession: $fatherOfConfession, notes: $notes, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, classId: $classId)';
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
            (identical(other.classId, classId) || other.classId == classId));
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
        classId
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
      {required final String uid,
      required final String docID,
      required final String name,
      required final String? imageUrl,
      required final UserRole role,
      required final String mobile,
      required final Group group,
      @JsonKey(name: 'team_name') required final String teamName,
      @JsonKey(name: 'mother_number') required final String motherPhone,
      @JsonKey(name: 'father_number') required final String fatherPhone,
      required final int grade,
      @JsonKey(name: 'education_stage')
      required final EducationStage educationStage,
      @JsonKey(name: 'school_college') required final String? school,
      required final String? address,
      @_TimestampConverter() required final DateTime? birthdate,
      @JsonKey(name: 'father_of_confession')
      required final String fatherOfConfession,
      required final String? notes,
      final bool isArchived,
      @_TimestampConverter() final DateTime? archivedAt,
      final String? archivedByUserId,
      final String? archiveReason,
      @_TimestampConverter() final DateTime? restoredAt,
      final String? restoredByUserId,
      final String? classId}) = _$StudentModelImpl;
  const _StudentModel._() : super._();

  factory _StudentModel.fromJson(Map<String, dynamic> json) =
      _$StudentModelImpl.fromJson;

  @override
  String get uid;
  @override
  String get docID;
  @override
  String get name;
  @override
  String? get imageUrl;
  @override
  UserRole get role;
  @override
  String get mobile;
  @override
  Group get group;
  @override
  @JsonKey(name: 'team_name')
  String get teamName;
  @override
  @JsonKey(name: 'mother_number')
  String get motherPhone;
  @override
  @JsonKey(name: 'father_number')
  String get fatherPhone;
  @override
  int get grade;
  @override
  @JsonKey(name: 'education_stage')
  EducationStage get educationStage;
  @override
  @JsonKey(name: 'school_college')
  String? get school;
  @override
  String? get address;
  @override
  @_TimestampConverter()
  DateTime? get birthdate;
  @override
  @JsonKey(name: 'father_of_confession')
  String get fatherOfConfession;
  @override
  String? get notes;
  @override
  bool get isArchived;
  @override
  @_TimestampConverter()
  DateTime? get archivedAt;
  @override
  String? get archivedByUserId;
  @override
  String? get archiveReason;
  @override
  @_TimestampConverter()
  DateTime? get restoredAt;
  @override
  String? get restoredByUserId;
  @override

  /// Class ID for efficient querying - enables single query instead of N+1.
  String? get classId;
  @override
  @JsonKey(ignore: true)
  _$$StudentModelImplCopyWith<_$StudentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
