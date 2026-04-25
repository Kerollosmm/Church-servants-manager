// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) {
  return _AuthUser.fromJson(json);
}

/// @nodoc
mixin _$AuthUser {
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  UserRole get role => throw _privateConstructorUsedError;
  bool get isEmailVerified => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  String? get archivedByUserId => throw _privateConstructorUsedError;
  String? get archiveReason => throw _privateConstructorUsedError;
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  String? get restoredByUserId => throw _privateConstructorUsedError;
  bool get restorePendingPasswordReset => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  List<String> get assignedTeamIds => throw _privateConstructorUsedError;
  String? get assignedTeamId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthUserCopyWith<AuthUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthUserCopyWith<$Res> {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) then) =
      _$AuthUserCopyWithImpl<$Res, AuthUser>;
  @useResult
  $Res call(
      {String uid,
      String email,
      String name,
      UserRole role,
      bool isEmailVerified,
      bool isArchived,
      @_TimestampConverter() DateTime? archivedAt,
      String? archivedByUserId,
      String? archiveReason,
      @_TimestampConverter() DateTime? restoredAt,
      String? restoredByUserId,
      bool restorePendingPasswordReset,
      String? groupId,
      List<String> assignedTeamIds,
      String? assignedTeamId});
}

/// @nodoc
class _$AuthUserCopyWithImpl<$Res, $Val extends AuthUser>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? name = null,
    Object? role = null,
    Object? isEmailVerified = null,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? restorePendingPasswordReset = null,
    Object? groupId = freezed,
    Object? assignedTeamIds = null,
    Object? assignedTeamId = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
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
      restorePendingPasswordReset: null == restorePendingPasswordReset
          ? _value.restorePendingPasswordReset
          : restorePendingPasswordReset // ignore: cast_nullable_to_non_nullable
              as bool,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedTeamIds: null == assignedTeamIds
          ? _value.assignedTeamIds
          : assignedTeamIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assignedTeamId: freezed == assignedTeamId
          ? _value.assignedTeamId
          : assignedTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthUserImplCopyWith<$Res>
    implements $AuthUserCopyWith<$Res> {
  factory _$$AuthUserImplCopyWith(
          _$AuthUserImpl value, $Res Function(_$AuthUserImpl) then) =
      __$$AuthUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String email,
      String name,
      UserRole role,
      bool isEmailVerified,
      bool isArchived,
      @_TimestampConverter() DateTime? archivedAt,
      String? archivedByUserId,
      String? archiveReason,
      @_TimestampConverter() DateTime? restoredAt,
      String? restoredByUserId,
      bool restorePendingPasswordReset,
      String? groupId,
      List<String> assignedTeamIds,
      String? assignedTeamId});
}

/// @nodoc
class __$$AuthUserImplCopyWithImpl<$Res>
    extends _$AuthUserCopyWithImpl<$Res, _$AuthUserImpl>
    implements _$$AuthUserImplCopyWith<$Res> {
  __$$AuthUserImplCopyWithImpl(
      _$AuthUserImpl _value, $Res Function(_$AuthUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? name = null,
    Object? role = null,
    Object? isEmailVerified = null,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? restorePendingPasswordReset = null,
    Object? groupId = freezed,
    Object? assignedTeamIds = null,
    Object? assignedTeamId = freezed,
  }) {
    return _then(_$AuthUserImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
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
      restorePendingPasswordReset: null == restorePendingPasswordReset
          ? _value.restorePendingPasswordReset
          : restorePendingPasswordReset // ignore: cast_nullable_to_non_nullable
              as bool,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedTeamIds: null == assignedTeamIds
          ? _value._assignedTeamIds
          : assignedTeamIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      assignedTeamId: freezed == assignedTeamId
          ? _value.assignedTeamId
          : assignedTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthUserImpl extends _AuthUser {
  const _$AuthUserImpl(
      {required this.uid,
      required this.email,
      required this.name,
      required this.role,
      this.isEmailVerified = false,
      this.isArchived = false,
      @_TimestampConverter() this.archivedAt,
      this.archivedByUserId,
      this.archiveReason,
      @_TimestampConverter() this.restoredAt,
      this.restoredByUserId,
      this.restorePendingPasswordReset = false,
      this.groupId,
      final List<String> assignedTeamIds = const <String>[],
      this.assignedTeamId})
      : _assignedTeamIds = assignedTeamIds,
        super._();

  factory _$AuthUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthUserImplFromJson(json);

  @override
  final String uid;
  @override
  final String email;
  @override
  final String name;
  @override
  final UserRole role;
  @override
  @JsonKey()
  final bool isEmailVerified;
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
  @override
  @JsonKey()
  final bool restorePendingPasswordReset;
  @override
  final String? groupId;
  final List<String> _assignedTeamIds;
  @override
  @JsonKey()
  List<String> get assignedTeamIds {
    if (_assignedTeamIds is EqualUnmodifiableListView) return _assignedTeamIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignedTeamIds);
  }

  @override
  final String? assignedTeamId;

  @override
  String toString() {
    return 'AuthUser(uid: $uid, email: $email, name: $name, role: $role, isEmailVerified: $isEmailVerified, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, restorePendingPasswordReset: $restorePendingPasswordReset, groupId: $groupId, assignedTeamIds: $assignedTeamIds, assignedTeamId: $assignedTeamId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthUserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isEmailVerified, isEmailVerified) ||
                other.isEmailVerified == isEmailVerified) &&
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
            (identical(other.restorePendingPasswordReset,
                    restorePendingPasswordReset) ||
                other.restorePendingPasswordReset ==
                    restorePendingPasswordReset) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality()
                .equals(other._assignedTeamIds, _assignedTeamIds) &&
            (identical(other.assignedTeamId, assignedTeamId) ||
                other.assignedTeamId == assignedTeamId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      email,
      name,
      role,
      isEmailVerified,
      isArchived,
      archivedAt,
      archivedByUserId,
      archiveReason,
      restoredAt,
      restoredByUserId,
      restorePendingPasswordReset,
      groupId,
      const DeepCollectionEquality().hash(_assignedTeamIds),
      assignedTeamId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthUserImplCopyWith<_$AuthUserImpl> get copyWith =>
      __$$AuthUserImplCopyWithImpl<_$AuthUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthUserImplToJson(
      this,
    );
  }
}

abstract class _AuthUser extends AuthUser {
  const factory _AuthUser(
      {required final String uid,
      required final String email,
      required final String name,
      required final UserRole role,
      final bool isEmailVerified,
      final bool isArchived,
      @_TimestampConverter() final DateTime? archivedAt,
      final String? archivedByUserId,
      final String? archiveReason,
      @_TimestampConverter() final DateTime? restoredAt,
      final String? restoredByUserId,
      final bool restorePendingPasswordReset,
      final String? groupId,
      final List<String> assignedTeamIds,
      final String? assignedTeamId}) = _$AuthUserImpl;
  const _AuthUser._() : super._();

  factory _AuthUser.fromJson(Map<String, dynamic> json) =
      _$AuthUserImpl.fromJson;

  @override
  String get uid;
  @override
  String get email;
  @override
  String get name;
  @override
  UserRole get role;
  @override
  bool get isEmailVerified;
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
  bool get restorePendingPasswordReset;
  @override
  String? get groupId;
  @override
  List<String> get assignedTeamIds;
  @override
  String? get assignedTeamId;
  @override
  @JsonKey(ignore: true)
  _$$AuthUserImplCopyWith<_$AuthUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
