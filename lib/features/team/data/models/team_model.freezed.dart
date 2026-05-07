// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) {
  return _TeamModel.fromJson(json);
}

/// @nodoc
mixin _$TeamModel {
  /// Firestore document ID.
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;

  /// Team display name (e.g. "فريق مارمرقس").
  @HiveField(1)
  String get name => throw _privateConstructorUsedError;

  /// The group/year this team belongs to (e.g. "year1").
  @HiveField(2)
  String get groupId => throw _privateConstructorUsedError;

  /// UID of the servant assigned to this team (optional).
  @HiveField(3)
  String? get assignedServantId => throw _privateConstructorUsedError;

  /// Denormalized servant name for display.
  @HiveField(4)
  String? get assignedServantName => throw _privateConstructorUsedError;
  @HiveField(5)
  bool get isArchived => throw _privateConstructorUsedError;
  @HiveField(6)
  @_TimestampConverter()
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  @HiveField(7)
  String? get archivedByUserId => throw _privateConstructorUsedError;
  @HiveField(8)
  String? get archiveReason => throw _privateConstructorUsedError;
  @HiveField(9)
  @_TimestampConverter()
  DateTime? get restoredAt => throw _privateConstructorUsedError;
  @HiveField(10)
  String? get restoredByUserId => throw _privateConstructorUsedError;
  @HiveField(11)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TeamModelCopyWith<TeamModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamModelCopyWith<$Res> {
  factory $TeamModelCopyWith(TeamModel value, $Res Function(TeamModel) then) =
      _$TeamModelCopyWithImpl<$Res, TeamModel>;
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String name,
    @HiveField(2) String groupId,
    @HiveField(3) String? assignedServantId,
    @HiveField(4) String? assignedServantName,
    @HiveField(5) bool isArchived,
    @HiveField(6) @_TimestampConverter() DateTime? archivedAt,
    @HiveField(7) String? archivedByUserId,
    @HiveField(8) String? archiveReason,
    @HiveField(9) @_TimestampConverter() DateTime? restoredAt,
    @HiveField(10) String? restoredByUserId,
    @HiveField(11) SyncStatus syncStatus,
  });
}

/// @nodoc
class _$TeamModelCopyWithImpl<$Res, $Val extends TeamModel>
    implements $TeamModelCopyWith<$Res> {
  _$TeamModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? groupId = null,
    Object? assignedServantId = freezed,
    Object? assignedServantName = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? syncStatus = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            assignedServantId: freezed == assignedServantId
                ? _value.assignedServantId
                : assignedServantId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedServantName: freezed == assignedServantName
                ? _value.assignedServantName
                : assignedServantName // ignore: cast_nullable_to_non_nullable
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
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SyncStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TeamModelImplCopyWith<$Res>
    implements $TeamModelCopyWith<$Res> {
  factory _$$TeamModelImplCopyWith(
    _$TeamModelImpl value,
    $Res Function(_$TeamModelImpl) then,
  ) = __$$TeamModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String name,
    @HiveField(2) String groupId,
    @HiveField(3) String? assignedServantId,
    @HiveField(4) String? assignedServantName,
    @HiveField(5) bool isArchived,
    @HiveField(6) @_TimestampConverter() DateTime? archivedAt,
    @HiveField(7) String? archivedByUserId,
    @HiveField(8) String? archiveReason,
    @HiveField(9) @_TimestampConverter() DateTime? restoredAt,
    @HiveField(10) String? restoredByUserId,
    @HiveField(11) SyncStatus syncStatus,
  });
}

/// @nodoc
class __$$TeamModelImplCopyWithImpl<$Res>
    extends _$TeamModelCopyWithImpl<$Res, _$TeamModelImpl>
    implements _$$TeamModelImplCopyWith<$Res> {
  __$$TeamModelImplCopyWithImpl(
    _$TeamModelImpl _value,
    $Res Function(_$TeamModelImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? groupId = null,
    Object? assignedServantId = freezed,
    Object? assignedServantName = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedByUserId = freezed,
    Object? archiveReason = freezed,
    Object? restoredAt = freezed,
    Object? restoredByUserId = freezed,
    Object? syncStatus = null,
  }) {
    return _then(
      _$TeamModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        assignedServantId: freezed == assignedServantId
            ? _value.assignedServantId
            : assignedServantId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedServantName: freezed == assignedServantName
            ? _value.assignedServantName
            : assignedServantName // ignore: cast_nullable_to_non_nullable
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
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SyncStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamModelImpl extends _TeamModel {
  const _$TeamModelImpl({
    @HiveField(0) required this.id,
    @HiveField(1) required this.name,
    @HiveField(2) required this.groupId,
    @HiveField(3) this.assignedServantId,
    @HiveField(4) this.assignedServantName,
    @HiveField(5) this.isArchived = false,
    @HiveField(6) @_TimestampConverter() this.archivedAt,
    @HiveField(7) this.archivedByUserId,
    @HiveField(8) this.archiveReason,
    @HiveField(9) @_TimestampConverter() this.restoredAt,
    @HiveField(10) this.restoredByUserId,
    @HiveField(11) this.syncStatus = SyncStatus.synced,
  }) : super._();

  factory _$TeamModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamModelImplFromJson(json);

  /// Firestore document ID.
  @override
  @HiveField(0)
  final String id;

  /// Team display name (e.g. "فريق مارمرقس").
  @override
  @HiveField(1)
  final String name;

  /// The group/year this team belongs to (e.g. "year1").
  @override
  @HiveField(2)
  final String groupId;

  /// UID of the servant assigned to this team (optional).
  @override
  @HiveField(3)
  final String? assignedServantId;

  /// Denormalized servant name for display.
  @override
  @HiveField(4)
  final String? assignedServantName;
  @override
  @JsonKey()
  @HiveField(5)
  final bool isArchived;
  @override
  @HiveField(6)
  @_TimestampConverter()
  final DateTime? archivedAt;
  @override
  @HiveField(7)
  final String? archivedByUserId;
  @override
  @HiveField(8)
  final String? archiveReason;
  @override
  @HiveField(9)
  @_TimestampConverter()
  final DateTime? restoredAt;
  @override
  @HiveField(10)
  final String? restoredByUserId;
  @override
  @JsonKey()
  @HiveField(11)
  final SyncStatus syncStatus;

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, groupId: $groupId, assignedServantId: $assignedServantId, assignedServantName: $assignedServantName, isArchived: $isArchived, archivedAt: $archivedAt, archivedByUserId: $archivedByUserId, archiveReason: $archiveReason, restoredAt: $restoredAt, restoredByUserId: $restoredByUserId, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.assignedServantId, assignedServantId) ||
                other.assignedServantId == assignedServantId) &&
            (identical(other.assignedServantName, assignedServantName) ||
                other.assignedServantName == assignedServantName) &&
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
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    groupId,
    assignedServantId,
    assignedServantName,
    isArchived,
    archivedAt,
    archivedByUserId,
    archiveReason,
    restoredAt,
    restoredByUserId,
    syncStatus,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamModelImplCopyWith<_$TeamModelImpl> get copyWith =>
      __$$TeamModelImplCopyWithImpl<_$TeamModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamModelImplToJson(this);
  }
}

abstract class _TeamModel extends TeamModel {
  const factory _TeamModel({
    @HiveField(0) required final String id,
    @HiveField(1) required final String name,
    @HiveField(2) required final String groupId,
    @HiveField(3) final String? assignedServantId,
    @HiveField(4) final String? assignedServantName,
    @HiveField(5) final bool isArchived,
    @HiveField(6) @_TimestampConverter() final DateTime? archivedAt,
    @HiveField(7) final String? archivedByUserId,
    @HiveField(8) final String? archiveReason,
    @HiveField(9) @_TimestampConverter() final DateTime? restoredAt,
    @HiveField(10) final String? restoredByUserId,
    @HiveField(11) final SyncStatus syncStatus,
  }) = _$TeamModelImpl;
  const _TeamModel._() : super._();

  factory _TeamModel.fromJson(Map<String, dynamic> json) =
      _$TeamModelImpl.fromJson;

  @override
  /// Firestore document ID.
  @HiveField(0)
  String get id;
  @override
  /// Team display name (e.g. "فريق مارمرقس").
  @HiveField(1)
  String get name;
  @override
  /// The group/year this team belongs to (e.g. "year1").
  @HiveField(2)
  String get groupId;
  @override
  /// UID of the servant assigned to this team (optional).
  @HiveField(3)
  String? get assignedServantId;
  @override
  /// Denormalized servant name for display.
  @HiveField(4)
  String? get assignedServantName;
  @override
  @HiveField(5)
  bool get isArchived;
  @override
  @HiveField(6)
  @_TimestampConverter()
  DateTime? get archivedAt;
  @override
  @HiveField(7)
  String? get archivedByUserId;
  @override
  @HiveField(8)
  String? get archiveReason;
  @override
  @HiveField(9)
  @_TimestampConverter()
  DateTime? get restoredAt;
  @override
  @HiveField(10)
  String? get restoredByUserId;
  @override
  @HiveField(11)
  SyncStatus get syncStatus;
  @override
  @JsonKey(ignore: true)
  _$$TeamModelImplCopyWith<_$TeamModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
