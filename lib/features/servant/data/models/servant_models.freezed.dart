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
  @HiveField(0)
  String? get uid => throw _privateConstructorUsedError;

  /// Firestore document ID.
  @HiveField(1)
  String get docID => throw _privateConstructorUsedError;
  @HiveField(2)
  String get name => throw _privateConstructorUsedError;

  /// Role (defaults to servant)
  @HiveField(3)
  @_RoleConverter()
  UserRole get role => throw _privateConstructorUsedError;

  /// Email (may be null for some users)
  @HiveField(4)
  String? get email => throw _privateConstructorUsedError;

  /// Phone number (optional - may not exist in user docs)
  @HiveField(5)
  String? get phone => throw _privateConstructorUsedError;

  /// Profile image URL
  @HiveField(6)
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Team/group name - uses groupId from Users collection
  @HiveField(7)
  @JsonKey(name: 'groupId')
  String? get teamName => throw _privateConstructorUsedError;

  /// Email verification status
  @HiveField(8)
  @JsonKey(name: 'isEmailVerified')
  bool get isEmailVerified => throw _privateConstructorUsedError;

  /// Father of confession name.
  @HiveField(9)
  @JsonKey(name: 'father_of_confession')
  String? get fatherOfConfession => throw _privateConstructorUsedError;

  /// Birthdate with Timestamp conversion.
  @HiveField(10)
  @_TimestampConverter()
  DateTime? get birthdate => throw _privateConstructorUsedError;

  /// Optional notes about the servant.
  @HiveField(11)
  String? get notes => throw _privateConstructorUsedError;
  @HiveField(12)
  bool get isArchived => throw _privateConstructorUsedError;
  @HiveField(13)
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  @HiveField(14)
  String? get archivedByUserId => throw _privateConstructorUsedError;
  @HiveField(15)
  String? get archiveReason => throw _privateConstructorUsedError;
  @HiveField(16)
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  @HiveField(17)
  String? get restoredByUserId => throw _privateConstructorUsedError;

  /// Assigned team/class ID within the servant's group.
  @HiveField(18)
  @Deprecated('Use assignedTeamIds instead')
  String? get assignedTeamId => throw _privateConstructorUsedError;

  /// Multiple assigned team IDs (if applicable).
  @HiveField(19)
  List<String> get assignedTeamIds => throw _privateConstructorUsedError;

  /// Aggregated group attendance metrics (for US1 Trend Insights).
  @HiveField(20)
  Map<String, dynamic>? get groupAttendanceSummary =>
      throw _privateConstructorUsedError;
  @HiveField(21)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  @HiveField(22)
  @_TimestampConverter()
  DateTime? get clientUpdatedAt => throw _privateConstructorUsedError;

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
    @HiveField(0) String? uid,
    @HiveField(1) String docID,
    @HiveField(2) String name,
    @HiveField(3) @_RoleConverter() UserRole role,
    @HiveField(4) String? email,
    @HiveField(5) String? phone,
    @HiveField(6) String? imageUrl,
    @HiveField(7) @JsonKey(name: 'groupId') String? teamName,
    @HiveField(8) @JsonKey(name: 'isEmailVerified') bool isEmailVerified,
    @HiveField(9)
    @JsonKey(name: 'father_of_confession')
    String? fatherOfConfession,
    @HiveField(10) @_TimestampConverter() DateTime? birthdate,
    @HiveField(11) String? notes,
    @HiveField(12) bool isArchived,
    @HiveField(13) @_TimestampConverter() DateTime? archivedAt,
    @HiveField(14) String? archivedByUserId,
    @HiveField(15) String? archiveReason,
    @HiveField(16) @_TimestampConverter() DateTime? restoredAt,
    @HiveField(17) String? restoredByUserId,
    @HiveField(18)
    @Deprecated('Use assignedTeamIds instead')
    String? assignedTeamId,
    @HiveField(19) List<String> assignedTeamIds,
    @HiveField(20) Map<String, dynamic>? groupAttendanceSummary,
    @HiveField(21) SyncStatus syncStatus,
    @HiveField(22) @_TimestampConverter() DateTime? clientUpdatedAt,
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
    Object? assignedTeamIds = null,
    Object? groupAttendanceSummary = freezed,
    Object? syncStatus = null,
    Object? clientUpdatedAt = freezed,
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
            assignedTeamIds: null == assignedTeamIds
                ? _value.assignedTeamIds
                : assignedTeamIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            groupAttendanceSummary: freezed == groupAttendanceSummary
                ? _value.groupAttendanceSummary
                : groupAttendanceSummary // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SyncStatus,
            clientUpdatedAt: freezed == clientUpdatedAt
                ? _value.clientUpdatedAt
                : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
    @HiveField(0) String? uid,
    @HiveField(1) String docID,
    @HiveField(2) String name,
    @HiveField(3) @_RoleConverter() UserRole role,
    @HiveField(4) String? email,
    @HiveField(5) String? phone,
    @HiveField(6) String? imageUrl,
    @HiveField(7) @JsonKey(name: 'groupId') String? teamName,
    @HiveField(8) @JsonKey(name: 'isEmailVerified') bool isEmailVerified,
    @HiveField(9)
    @JsonKey(name: 'father_of_confession')
    String? fatherOfConfession,
    @HiveField(10) @_TimestampConverter() DateTime? birthdate,
    @HiveField(11) String? notes,
    @HiveField(12) bool isArchived,
    @HiveField(13) @_TimestampConverter() DateTime? archivedAt,
    @HiveField(14) String? archivedByUserId,
    @HiveField(15) String? archiveReason,
    @HiveField(16) @_TimestampConverter() DateTime? restoredAt,
    @HiveField(17) String? restoredByUserId,
    @HiveField(18)
    @Deprecated('Use assignedTeamIds instead')
    String? assignedTeamId,
    @HiveField(19) List<String> assignedTeamIds,
    @HiveField(20) Map<String, dynamic>? groupAttendanceSummary,
    @HiveField(21) SyncStatus syncStatus,
    @HiveField(22) @_TimestampConverter() DateTime? clientUpdatedAt,
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
    Object? assignedTeamIds = null,
    Object? groupAttendanceSummary = freezed,
    Object? syncStatus = null,
    Object? clientUpdatedAt = freezed,
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
        assignedTeamIds: null == assignedTeamIds
            ? _value._assignedTeamIds
            : assignedTeamIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        groupAttendanceSummary: freezed == groupAttendanceSummary
            ? _value._groupAttendanceSummary
            : groupAttendanceSummary // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SyncStatus,
        clientUpdatedAt: freezed == clientUpdatedAt
            ? _value.clientUpdatedAt
            : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ServantModelImpl extends _ServantModel {
  const _$ServantModelImpl({
    @HiveField(0) this.uid,
    @HiveField(1) required this.docID,
    @HiveField(2) required this.name,
    @HiveField(3) @_RoleConverter() this.role = UserRole.servant,
    @HiveField(4) this.email,
    @HiveField(5) this.phone,
    @HiveField(6) this.imageUrl,
    @HiveField(7) @JsonKey(name: 'groupId') this.teamName,
    @HiveField(8)
    @JsonKey(name: 'isEmailVerified')
    this.isEmailVerified = false,
    @HiveField(9)
    @JsonKey(name: 'father_of_confession')
    this.fatherOfConfession,
    @HiveField(10) @_TimestampConverter() this.birthdate,
    @HiveField(11) this.notes,
    @HiveField(12) this.isArchived = false,
    @HiveField(13) @_TimestampConverter() this.archivedAt,
    @HiveField(14) this.archivedByUserId,
    @HiveField(15) this.archiveReason,
    @HiveField(16) @_TimestampConverter() this.restoredAt,
    @HiveField(17) this.restoredByUserId,
    @HiveField(18)
    @Deprecated('Use assignedTeamIds instead')
    this.assignedTeamId,
    @HiveField(19) final List<String> assignedTeamIds = const <String>[],
    @HiveField(20) final Map<String, dynamic>? groupAttendanceSummary,
    @HiveField(21) this.syncStatus = SyncStatus.synced,
    @HiveField(22) @_TimestampConverter() this.clientUpdatedAt,
  }) : _assignedTeamIds = assignedTeamIds,
       _groupAttendanceSummary = groupAttendanceSummary,
       super._();

  factory _$ServantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServantModelImplFromJson(json);

  /// Firebase Auth UID for this servant.
  @override
  @HiveField(0)
  final String? uid;

  /// Firestore document ID.
  @override
  @HiveField(1)
  final String docID;
  @override
  @HiveField(2)
  final String name;

  /// Role (defaults to servant)
  @override
  @JsonKey()
  @HiveField(3)
  @_RoleConverter()
  final UserRole role;

  /// Email (may be null for some users)
  @override
  @HiveField(4)
  final String? email;

  /// Phone number (optional - may not exist in user docs)
  @override
  @HiveField(5)
  final String? phone;

  /// Profile image URL
  @override
  @HiveField(6)
  final String? imageUrl;

  /// Team/group name - uses groupId from Users collection
  @override
  @HiveField(7)
  @JsonKey(name: 'groupId')
  final String? teamName;

  /// Email verification status
  @override
  @HiveField(8)
  @JsonKey(name: 'isEmailVerified')
  final bool isEmailVerified;

  /// Father of confession name.
  @override
  @HiveField(9)
  @JsonKey(name: 'father_of_confession')
  final String? fatherOfConfession;

  /// Birthdate with Timestamp conversion.
  @override
  @HiveField(10)
  @_TimestampConverter()
  final DateTime? birthdate;

  /// Optional notes about the servant.
  @override
  @HiveField(11)
  final String? notes;
  @override
  @JsonKey()
  @HiveField(12)
  final bool isArchived;
  @override
  @HiveField(13)
  @_TimestampConverter()
  final DateTime? archivedAt;
  @override
  @HiveField(14)
  final String? archivedByUserId;
  @override
  @HiveField(15)
  final String? archiveReason;
  @override
  @HiveField(16)
  @_TimestampConverter()
  final DateTime? restoredAt;
  @override
  @HiveField(17)
  final String? restoredByUserId;

  /// Assigned team/class ID within the servant's group.
  @override
  @HiveField(18)
  @Deprecated('Use assignedTeamIds instead')
  final String? assignedTeamId;

  /// Multiple assigned team IDs (if applicable).
  final List<String> _assignedTeamIds;

  /// Multiple assigned team IDs (if applicable).
  @override
  @JsonKey()
  @HiveField(19)
  List<String> get assignedTeamIds {
    if (_assignedTeamIds is EqualUnmodifiableListView) return _assignedTeamIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignedTeamIds);
  }

  /// Aggregated group attendance metrics (for US1 Trend Insights).
  final Map<String, dynamic>? _groupAttendanceSummary;

  /// Aggregated group attendance metrics (for US1 Trend Insights).
  @override
  @HiveField(20)
  Map<String, dynamic>? get groupAttendanceSummary {
    final value = _groupAttendanceSummary;
    if (value == null) return null;
    if (_groupAttendanceSummary is EqualUnmodifiableMapView)
      return _groupAttendanceSummary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  @HiveField(21)
  final SyncStatus syncStatus;
  @override
  @HiveField(22)
  @_TimestampConverter()
  final DateTime? clientUpdatedAt;

  @override
  String toString() {
    return 'ServantModel(uid: $uid, docID: $docID, name: $name, role: $role, email: $email, phone: $phone, imageUrl: $imageUrl, teamName: $teamName, isEmailVerified: $isEmailVerified, fatherOfConfession: $fatherOfConfession, birthdate: $birthdate, notes: $notes, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, assignedTeamId: $assignedTeamId, assignedTeamIds: $assignedTeamIds, groupAttendanceSummary: $groupAttendanceSummary, syncStatus: $syncStatus, clientUpdatedAt: $clientUpdatedAt)';
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
            ) &&
            const DeepCollectionEquality().equals(
              other._groupAttendanceSummary,
              _groupAttendanceSummary,
            ) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.clientUpdatedAt, clientUpdatedAt) ||
                other.clientUpdatedAt == clientUpdatedAt));
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
    const DeepCollectionEquality().hash(_groupAttendanceSummary),
    syncStatus,
    clientUpdatedAt,
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
    @HiveField(0) final String? uid,
    @HiveField(1) required final String docID,
    @HiveField(2) required final String name,
    @HiveField(3) @_RoleConverter() final UserRole role,
    @HiveField(4) final String? email,
    @HiveField(5) final String? phone,
    @HiveField(6) final String? imageUrl,
    @HiveField(7) @JsonKey(name: 'groupId') final String? teamName,
    @HiveField(8) @JsonKey(name: 'isEmailVerified') final bool isEmailVerified,
    @HiveField(9)
    @JsonKey(name: 'father_of_confession')
    final String? fatherOfConfession,
    @HiveField(10) @_TimestampConverter() final DateTime? birthdate,
    @HiveField(11) final String? notes,
    @HiveField(12) final bool isArchived,
    @HiveField(13) @_TimestampConverter() final DateTime? archivedAt,
    @HiveField(14) final String? archivedByUserId,
    @HiveField(15) final String? archiveReason,
    @HiveField(16) @_TimestampConverter() final DateTime? restoredAt,
    @HiveField(17) final String? restoredByUserId,
    @HiveField(18)
    @Deprecated('Use assignedTeamIds instead')
    final String? assignedTeamId,
    @HiveField(19) final List<String> assignedTeamIds,
    @HiveField(20) final Map<String, dynamic>? groupAttendanceSummary,
    @HiveField(21) final SyncStatus syncStatus,
    @HiveField(22) @_TimestampConverter() final DateTime? clientUpdatedAt,
  }) = _$ServantModelImpl;
  const _ServantModel._() : super._();

  factory _ServantModel.fromJson(Map<String, dynamic> json) =
      _$ServantModelImpl.fromJson;

  @override
  /// Firebase Auth UID for this servant.
  @HiveField(0)
  String? get uid;
  @override
  /// Firestore document ID.
  @HiveField(1)
  String get docID;
  @override
  @HiveField(2)
  String get name;
  @override
  /// Role (defaults to servant)
  @HiveField(3)
  @_RoleConverter()
  UserRole get role;
  @override
  /// Email (may be null for some users)
  @HiveField(4)
  String? get email;
  @override
  /// Phone number (optional - may not exist in user docs)
  @HiveField(5)
  String? get phone;
  @override
  /// Profile image URL
  @HiveField(6)
  String? get imageUrl;
  @override
  /// Team/group name - uses groupId from Users collection
  @HiveField(7)
  @JsonKey(name: 'groupId')
  String? get teamName;
  @override
  /// Email verification status
  @HiveField(8)
  @JsonKey(name: 'isEmailVerified')
  bool get isEmailVerified;
  @override
  /// Father of confession name.
  @HiveField(9)
  @JsonKey(name: 'father_of_confession')
  String? get fatherOfConfession;
  @override
  /// Birthdate with Timestamp conversion.
  @HiveField(10)
  @_TimestampConverter()
  DateTime? get birthdate;
  @override
  /// Optional notes about the servant.
  @HiveField(11)
  String? get notes;
  @override
  @HiveField(12)
  bool get isArchived;
  @override
  @HiveField(13)
  @_TimestampConverter()
  DateTime? get archivedAt;
  @override
  @HiveField(14)
  String? get archivedByUserId;
  @override
  @HiveField(15)
  String? get archiveReason;
  @override
  @HiveField(16)
  @_TimestampConverter()
  DateTime? get restoredAt;
  @override
  @HiveField(17)
  String? get restoredByUserId;
  @override
  /// Assigned team/class ID within the servant's group.
  @HiveField(18)
  @Deprecated('Use assignedTeamIds instead')
  String? get assignedTeamId;
  @override
  /// Multiple assigned team IDs (if applicable).
  @HiveField(19)
  List<String> get assignedTeamIds;
  @override
  /// Aggregated group attendance metrics (for US1 Trend Insights).
  @HiveField(20)
  Map<String, dynamic>? get groupAttendanceSummary;
  @override
  @HiveField(21)
  SyncStatus get syncStatus;
  @override
  @HiveField(22)
  @_TimestampConverter()
  DateTime? get clientUpdatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ServantModelImplCopyWith<_$ServantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
