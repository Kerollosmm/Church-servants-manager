// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'servant_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ServantModel _$ServantModelFromJson(Map<String, dynamic> json) {
  return _ServantModel.fromJson(json);
}

/// @nodoc
mixin _$ServantModel {
  /// Firebase Auth UID for this servant.
  String? get uid => throw _privateConstructorUsedError;

  /// Firestore document ID.
  String get docID => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Role (defaults to servant)
  @_RoleConverter()
  UserRole get role => throw _privateConstructorUsedError;

  /// Email (may be null for some users)
  String? get email => throw _privateConstructorUsedError;

  /// Phone number (optional - may not exist in user docs)
  String? get phone => throw _privateConstructorUsedError;

  /// Profile image URL
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Team/group name - uses groupId from Users collection
  @JsonKey(name: 'groupId')
  String? get teamName => throw _privateConstructorUsedError;

  /// Email verification status
  @JsonKey(name: 'isEmailVerified')
  bool get isEmailVerified => throw _privateConstructorUsedError;

  /// Father of confession name.
  @JsonKey(name: 'father_of_confession')
  String? get fatherOfConfession => throw _privateConstructorUsedError;

  /// Birthdate with Timestamp conversion.
  @_TimestampConverter()
  DateTime? get birthdate => throw _privateConstructorUsedError;

  /// Optional notes about the servant.
  String? get notes => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  String? get archivedByUserId => throw _privateConstructorUsedError;
  String? get archiveReason => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  String? get restoredByUserId => throw _privateConstructorUsedError;

  /// Assigned team/class ID within the servant's group.
  String? get assignedTeamId => throw _privateConstructorUsedError;

  /// Multiple assigned team IDs (if applicable).
  List<String>? get assignedTeamIds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ServantModelCopyWith<ServantModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServantModelCopyWith<$Res> {
  factory $ServantModelCopyWith(
    ServantModel value,
    $Res Function(ServantModel) then,
  ) = _$ServantModelCopyWithImpl<$Res, ServantModel>;
  @useResult
  $Res call({
    String? uid,
    String docID,
    String name,
    @_RoleConverter() UserRole role,
    String? email,
    String? phone,
    String? imageUrl,
    @JsonKey(name: 'groupId') String? teamName,
    @JsonKey(name: 'isEmailVerified') bool isEmailVerified,
    @JsonKey(name: 'father_of_confession') String? fatherOfConfession,
    @_TimestampConverter() DateTime? birthdate,
    String? notes,
    bool isArchived,
    @_TimestampConverter() DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    @_TimestampConverter() DateTime? restoredAt,
    String? restoredByUserId,
    String? assignedTeamId,
    List<String>? assignedTeamIds,
  });
}

/// @nodoc
class _$ServantModelCopyWithImpl<$Res, $Val extends ServantModel>
    implements $ServantModelCopyWith<$Res> {
  _$ServantModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = freezed,
    Object? docID = null,
    Object? name = null,
    Object? role = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? imageUrl = freezed,
    Object? teamName = freezed,
    Object? isEmailVerified = null,
    Object? fatherOfConfession = freezed,
    Object? birthdate = freezed,
    Object? notes = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? assignedTeamId = freezed,
    Object? assignedTeamIds = freezed,
  }) {
    return _then(
      _value.copyWith(
            uid: freezed == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String?,
            docID: null == docID
                ? _value.docID
                : docID // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as UserRole,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            teamName: freezed == teamName
                ? _value.teamName
                : teamName // ignore: cast_nullable_to_non_nullable
                      as String?,
            isEmailVerified: null == isEmailVerified
                ? _value.isEmailVerified
                : isEmailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            fatherOfConfession: freezed == fatherOfConfession
                ? _value.fatherOfConfession
                : fatherOfConfession // ignore: cast_nullable_to_non_nullable
                      as String?,
            birthdate: freezed == birthdate
                ? _value.birthdate
                : birthdate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
            assignedTeamId: freezed == assignedTeamId
                ? _value.assignedTeamId
                : assignedTeamId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedTeamIds: freezed == assignedTeamIds
                ? _value.assignedTeamIds
                : assignedTeamIds // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServantModelImplCopyWith<$Res>
    implements $ServantModelCopyWith<$Res> {
  factory _$$ServantModelImplCopyWith(
    _$ServantModelImpl value,
    $Res Function(_$ServantModelImpl) then,
  ) = __$$ServantModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? uid,
    String docID,
    String name,
    @_RoleConverter() UserRole role,
    String? email,
    String? phone,
    String? imageUrl,
    @JsonKey(name: 'groupId') String? teamName,
    @JsonKey(name: 'isEmailVerified') bool isEmailVerified,
    @JsonKey(name: 'father_of_confession') String? fatherOfConfession,
    @_TimestampConverter() DateTime? birthdate,
    String? notes,
    bool isArchived,
    @_TimestampConverter() DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    @_TimestampConverter() DateTime? restoredAt,
    String? restoredByUserId,
    String? assignedTeamId,
    List<String>? assignedTeamIds,
  });
}

/// @nodoc
class __$$ServantModelImplCopyWithImpl<$Res>
    extends _$ServantModelCopyWithImpl<$Res, _$ServantModelImpl>
    implements _$$ServantModelImplCopyWith<$Res> {
  __$$ServantModelImplCopyWithImpl(
    _$ServantModelImpl _value,
    $Res Function(_$ServantModelImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = freezed,
    Object? docID = null,
    Object? name = null,
    Object? role = null,
    Object? email = freezed,
    Object? phone = freezed,
    Object? imageUrl = freezed,
    Object? teamName = freezed,
    Object? isEmailVerified = null,
    Object? fatherOfConfession = freezed,
    Object? birthdate = freezed,
    Object? notes = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? assignedTeamId = freezed,
    Object? assignedTeamIds = freezed,
  }) {
    return _then(
      _$ServantModelImpl(
        uid: freezed == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String?,
        docID: null == docID
            ? _value.docID
            : docID // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as UserRole,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        teamName: freezed == teamName
            ? _value.teamName
            : teamName // ignore: cast_nullable_to_non_nullable
                  as String?,
        isEmailVerified: null == isEmailVerified
            ? _value.isEmailVerified
            : isEmailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        fatherOfConfession: freezed == fatherOfConfession
            ? _value.fatherOfConfession
            : fatherOfConfession // ignore: cast_nullable_to_non_nullable
                  as String?,
        birthdate: freezed == birthdate
            ? _value.birthdate
            : birthdate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
        assignedTeamId: freezed == assignedTeamId
            ? _value.assignedTeamId
            : assignedTeamId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedTeamIds: freezed == assignedTeamIds
            ? _value._assignedTeamIds
            : assignedTeamIds // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServantModelImpl extends _ServantModel {
  const _$ServantModelImpl({
    this.uid,
    required this.docID,
    required this.name,
    @_RoleConverter() this.role = UserRole.servant,
    this.email,
    this.phone,
    this.imageUrl,
    @JsonKey(name: 'groupId') this.teamName,
    @JsonKey(name: 'isEmailVerified') this.isEmailVerified = false,
    @JsonKey(name: 'father_of_confession') this.fatherOfConfession,
    @_TimestampConverter() this.birthdate,
    this.notes,
    this.isArchived = false,
    @_TimestampConverter() this.archivedAt,
    this.archivedByUserId,
    this.archiveReason,
    @_TimestampConverter() this.restoredAt,
    this.restoredByUserId,
    this.assignedTeamId,
    final List<String>? assignedTeamIds,
  }) : _assignedTeamIds = assignedTeamIds,
       super._();

  factory _$ServantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServantModelImplFromJson(json);

  /// Firebase Auth UID for this servant.
  @override
  final String? uid;

  /// Firestore document ID.
  @override
  final String docID;
  @override
  final String name;

  /// Role (defaults to servant)
  @override
  @JsonKey()
  @_RoleConverter()
  final UserRole role;

  /// Email (may be null for some users)
  @override
  final String? email;

  /// Phone number (optional - may not exist in user docs)
  @override
  final String? phone;

  /// Profile image URL
  @override
  final String? imageUrl;

  /// Team/group name - uses groupId from Users collection
  @override
  @JsonKey(name: 'groupId')
  final String? teamName;

  /// Email verification status
  @override
  @JsonKey(name: 'isEmailVerified')
  final bool isEmailVerified;

  /// Father of confession name.
  @override
  @JsonKey(name: 'father_of_confession')
  final String? fatherOfConfession;

  /// Birthdate with Timestamp conversion.
  @override
  @_TimestampConverter()
  final DateTime? birthdate;

  /// Optional notes about the servant.
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

  /// Assigned team/class ID within the servant's group.
  @override
  final String? assignedTeamId;

  /// Multiple assigned team IDs (if applicable).
  final List<String>? _assignedTeamIds;

  /// Multiple assigned team IDs (if applicable).
  @override
  List<String>? get assignedTeamIds {
    final value = _assignedTeamIds;
    if (value == null) return null;
    if (_assignedTeamIds is EqualUnmodifiableListView) return _assignedTeamIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ServantModel(uid: $uid, docID: $docID, name: $name, role: $role, email: $email, phone: $phone, imageUrl: $imageUrl, teamName: $teamName, isEmailVerified: $isEmailVerified, fatherOfConfession: $fatherOfConfession, birthdate: $birthdate, notes: $notes, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, assignedTeamId: $assignedTeamId, assignedTeamIds: $assignedTeamIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServantModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.docID, docID) || other.docID == docID) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.isEmailVerified, isEmailVerified) ||
                other.isEmailVerified == isEmailVerified) &&
            (identical(other.fatherOfConfession, fatherOfConfession) ||
                other.fatherOfConfession == fatherOfConfession) &&
            (identical(other.birthdate, birthdate) ||
                other.birthdate == birthdate) &&
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
            (identical(other.assignedTeamId, assignedTeamId) ||
                other.assignedTeamId == assignedTeamId) &&
            const DeepCollectionEquality().equals(
              other._assignedTeamIds,
              _assignedTeamIds,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    uid,
    docID,
    name,
    role,
    email,
    phone,
    imageUrl,
    teamName,
    isEmailVerified,
    fatherOfConfession,
    birthdate,
    notes,
    isArchived,
    archivedAt,
    archivedByUserId,
    archiveReason,
    restoredAt,
    restoredByUserId,
    assignedTeamId,
    const DeepCollectionEquality().hash(_assignedTeamIds),
  ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ServantModelImplCopyWith<_$ServantModelImpl> get copyWith =>
      __$$ServantModelImplCopyWithImpl<_$ServantModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServantModelImplToJson(this);
  }
}

abstract class _ServantModel extends ServantModel {
  const factory _ServantModel({
    final String? uid,
    required final String docID,
    required final String name,
    @_RoleConverter() final UserRole role,
    final String? email,
    final String? phone,
    final String? imageUrl,
    @JsonKey(name: 'groupId') final String? teamName,
    @JsonKey(name: 'isEmailVerified') final bool isEmailVerified,
    @JsonKey(name: 'father_of_confession') final String? fatherOfConfession,
    @_TimestampConverter() final DateTime? birthdate,
    final String? notes,
    final bool isArchived,
    @_TimestampConverter() final DateTime? archivedAt,
    final String? archivedByUserId,
    final String? archiveReason,
    @_TimestampConverter() final DateTime? restoredAt,
    final String? restoredByUserId,
    final String? assignedTeamId,
    final List<String>? assignedTeamIds,
  }) = _$ServantModelImpl;
  const _ServantModel._() : super._();

  factory _ServantModel.fromJson(Map<String, dynamic> json) =
      _$ServantModelImpl.fromJson;

  @override
  /// Firebase Auth UID for this servant.
  String? get uid;
  @override
  /// Firestore document ID.
  String get docID;
  @override
  String get name;
  @override
  /// Role (defaults to servant)
  @_RoleConverter()
  UserRole get role;
  @override
  /// Email (may be null for some users)
  String? get email;
  @override
  /// Phone number (optional - may not exist in user docs)
  String? get phone;
  @override
  /// Profile image URL
  String? get imageUrl;
  @override
  /// Team/group name - uses groupId from Users collection
  @JsonKey(name: 'groupId')
  String? get teamName;
  @override
  /// Email verification status
  @JsonKey(name: 'isEmailVerified')
  bool get isEmailVerified;
  @override
  /// Father of confession name.
  @JsonKey(name: 'father_of_confession')
  String? get fatherOfConfession;
  @override
  /// Birthdate with Timestamp conversion.
  @_TimestampConverter()
  DateTime? get birthdate;
  @override
  /// Optional notes about the servant.
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
  /// Assigned team/class ID within the servant's group.
  String? get assignedTeamId;
  @override
  /// Multiple assigned team IDs (if applicable).
  List<String>? get assignedTeamIds;
  @override
  @JsonKey(ignore: true)
  _$$ServantModelImplCopyWith<_$ServantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
