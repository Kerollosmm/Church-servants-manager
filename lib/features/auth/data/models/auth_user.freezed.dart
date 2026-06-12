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

AuthUserModel _$AuthUserModelFromJson(Map<String, dynamic> json) {
  return _AuthUserModel.fromJson(json);
}

/// @nodoc
mixin _$AuthUserModel {
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
  bool get requiresTokenRefresh => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  List<String> get assignedTeamIds => throw _privateConstructorUsedError;
  @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
  String? get assignedTeamId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthUserModelCopyWith<AuthUserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthUserModelCopyWith<$Res> {
  factory $AuthUserModelCopyWith(
          AuthUserModel value, $Res Function(AuthUserModel) then) =
      _$AuthUserModelCopyWithImpl<$Res, AuthUserModel>;
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
      bool requiresTokenRefresh,
      String? groupId,
      List<String> assignedTeamIds,
      @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
      String? assignedTeamId});
}

/// @nodoc
class _$AuthUserModelCopyWithImpl<$Res, $Val extends AuthUserModel>
    implements $AuthUserModelCopyWith<$Res> {
  _$AuthUserModelCopyWithImpl(this._value, this._then);

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
    Object? requiresTokenRefresh = null,
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
      requiresTokenRefresh: null == requiresTokenRefresh
          ? _value.requiresTokenRefresh
          : requiresTokenRefresh // ignore: cast_nullable_to_non_nullable
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
abstract class _$$AuthUserModelImplCopyWith<$Res>
    implements $AuthUserModelCopyWith<$Res> {
  factory _$$AuthUserModelImplCopyWith(
          _$AuthUserModelImpl value, $Res Function(_$AuthUserModelImpl) then) =
      __$$AuthUserModelImplCopyWithImpl<$Res>;
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
      bool requiresTokenRefresh,
      String? groupId,
      List<String> assignedTeamIds,
      @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
      String? assignedTeamId});
}

/// @nodoc
class __$$AuthUserModelImplCopyWithImpl<$Res>
    extends _$AuthUserModelCopyWithImpl<$Res, _$AuthUserModelImpl>
    implements _$$AuthUserModelImplCopyWith<$Res> {
  __$$AuthUserModelImplCopyWithImpl(
      _$AuthUserModelImpl _value, $Res Function(_$AuthUserModelImpl) _then)
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
    Object? requiresTokenRefresh = null,
    Object? groupId = freezed,
    Object? assignedTeamIds = null,
    Object? assignedTeamId = freezed,
  }) {
    return _then(_$AuthUserModelImpl(
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
      requiresTokenRefresh: null == requiresTokenRefresh
          ? _value.requiresTokenRefresh
          : requiresTokenRefresh // ignore: cast_nullable_to_non_nullable
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
class _$AuthUserModelImpl extends _AuthUserModel {
  const _$AuthUserModelImpl(
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
      this.requiresTokenRefresh = false,
      this.groupId,
      final List<String> assignedTeamIds = const <String>[],
      @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
      this.assignedTeamId})
      : _assignedTeamIds = assignedTeamIds,
        super._();

  factory _$AuthUserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthUserModelImplFromJson(json);

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
  @JsonKey()
  final bool requiresTokenRefresh;
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
  @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
  final String? assignedTeamId;

  @override
  String toString() {
    return 'AuthUserModel(uid: $uid, email: $email, name: $name, role: $role, isEmailVerified: $isEmailVerified, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, restorePendingPasswordReset: $restorePendingPasswordReset, requiresTokenRefresh: $requiresTokenRefresh, groupId: $groupId, assignedTeamIds: $assignedTeamIds, assignedTeamId: $assignedTeamId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthUserModelImpl &&
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
            (identical(other.requiresTokenRefresh, requiresTokenRefresh) ||
                other.requiresTokenRefresh == requiresTokenRefresh) &&
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
      requiresTokenRefresh,
      groupId,
      const DeepCollectionEquality().hash(_assignedTeamIds),
      assignedTeamId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthUserModelImplCopyWith<_$AuthUserModelImpl> get copyWith =>
      __$$AuthUserModelImplCopyWithImpl<_$AuthUserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthUserModelImplToJson(
      this,
    );
  }
}

abstract class _AuthUserModel extends AuthUserModel {
  const factory _AuthUserModel(
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
      final bool requiresTokenRefresh,
      final String? groupId,
      final List<String> assignedTeamIds,
      @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
      final String? assignedTeamId}) = _$AuthUserModelImpl;
  const _AuthUserModel._() : super._();

  factory _AuthUserModel.fromJson(Map<String, dynamic> json) =
      _$AuthUserModelImpl.fromJson;

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
  bool get requiresTokenRefresh;
  @override
  String? get groupId;
  @override
  List<String> get assignedTeamIds;
  @override
  @Deprecated('Use effectiveAssignedTeamIds or assignedTeamIds instead')
  String? get assignedTeamId;
  @override
  @JsonKey(ignore: true)
  _$$AuthUserModelImplCopyWith<_$AuthUserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
