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
  String get id => throw _privateConstructorUsedError;

  /// Team display name (e.g. "فريق مارمرقس").
  String get name => throw _privateConstructorUsedError;

  /// The group/year this team belongs to (e.g. "year1").
  String get groupId => throw _privateConstructorUsedError;

  /// UID of the servant assigned to this team (optional).
  String? get assignedServantId => throw _privateConstructorUsedError;

  /// Denormalized servant name for display.
  String? get assignedServantName => throw _privateConstructorUsedError;

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
    String id,
    String name,
    String groupId,
    String? assignedServantId,
    String? assignedServantName,
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
    String id,
    String name,
    String groupId,
    String? assignedServantId,
    String? assignedServantName,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamModelImpl extends _TeamModel {
  const _$TeamModelImpl({
    required this.id,
    required this.name,
    required this.groupId,
    this.assignedServantId,
    this.assignedServantName,
  }) : super._();

  factory _$TeamModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamModelImplFromJson(json);

  /// Firestore document ID.
  @override
  final String id;

  /// Team display name (e.g. "فريق مارمرقس").
  @override
  final String name;

  /// The group/year this team belongs to (e.g. "year1").
  @override
  final String groupId;

  /// UID of the servant assigned to this team (optional).
  @override
  final String? assignedServantId;

  /// Denormalized servant name for display.
  @override
  final String? assignedServantName;

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, groupId: $groupId, assignedServantId: $assignedServantId, assignedServantName: $assignedServantName)';
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
                other.assignedServantName == assignedServantName));
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
    required final String id,
    required final String name,
    required final String groupId,
    final String? assignedServantId,
    final String? assignedServantName,
  }) = _$TeamModelImpl;
  const _TeamModel._() : super._();

  factory _TeamModel.fromJson(Map<String, dynamic> json) =
      _$TeamModelImpl.fromJson;

  @override
  /// Firestore document ID.
  String get id;
  @override
  /// Team display name (e.g. "فريق مارمرقس").
  String get name;
  @override
  /// The group/year this team belongs to (e.g. "year1").
  String get groupId;
  @override
  /// UID of the servant assigned to this team (optional).
  String? get assignedServantId;
  @override
  /// Denormalized servant name for display.
  String? get assignedServantName;
  @override
  @JsonKey(ignore: true)
  _$$TeamModelImplCopyWith<_$TeamModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
