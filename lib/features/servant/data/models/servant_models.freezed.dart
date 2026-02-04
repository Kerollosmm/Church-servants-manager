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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServantModel _$ServantModelFromJson(Map<String, dynamic> json) {
  return _ServantModel.fromJson(json);
}

/// @nodoc
mixin _$ServantModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'team_name')
  String get teamName => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ServantModelCopyWith<ServantModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServantModelCopyWith<$Res> {
  factory $ServantModelCopyWith(
          ServantModel value, $Res Function(ServantModel) then) =
      _$ServantModelCopyWithImpl<$Res, ServantModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String phone,
      String email,
      String image,
      @JsonKey(name: 'team_name') String teamName,
      String role});
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
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? email = null,
    Object? image = null,
    Object? teamName = null,
    Object? role = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServantModelImplCopyWith<$Res>
    implements $ServantModelCopyWith<$Res> {
  factory _$$ServantModelImplCopyWith(
          _$ServantModelImpl value, $Res Function(_$ServantModelImpl) then) =
      __$$ServantModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String phone,
      String email,
      String image,
      @JsonKey(name: 'team_name') String teamName,
      String role});
}

/// @nodoc
class __$$ServantModelImplCopyWithImpl<$Res>
    extends _$ServantModelCopyWithImpl<$Res, _$ServantModelImpl>
    implements _$$ServantModelImplCopyWith<$Res> {
  __$$ServantModelImplCopyWithImpl(
      _$ServantModelImpl _value, $Res Function(_$ServantModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? email = null,
    Object? image = null,
    Object? teamName = null,
    Object? role = null,
  }) {
    return _then(_$ServantModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServantModelImpl implements _ServantModel {
  const _$ServantModelImpl(
      {required this.id,
      required this.name,
      required this.phone,
      required this.email,
      required this.image,
      @JsonKey(name: 'team_name') required this.teamName,
      required this.role});

  factory _$ServantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServantModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String email;
  @override
  final String image;
  @override
  @JsonKey(name: 'team_name')
  final String teamName;
  @override
  final String role;

  @override
  String toString() {
    return 'ServantModel(id: $id, name: $name, phone: $phone, email: $email, image: $image, teamName: $teamName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServantModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, phone, email, image, teamName, role);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ServantModelImplCopyWith<_$ServantModelImpl> get copyWith =>
      __$$ServantModelImplCopyWithImpl<_$ServantModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServantModelImplToJson(
      this,
    );
  }
}

abstract class _ServantModel implements ServantModel {
  const factory _ServantModel(
      {required final String id,
      required final String name,
      required final String phone,
      required final String email,
      required final String image,
      @JsonKey(name: 'team_name') required final String teamName,
      required final String role}) = _$ServantModelImpl;

  factory _ServantModel.fromJson(Map<String, dynamic> json) =
      _$ServantModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get phone;
  @override
  String get email;
  @override
  String get image;
  @override
  @JsonKey(name: 'team_name')
  String get teamName;
  @override
  String get role;
  @override
  @JsonKey(ignore: true)
  _$$ServantModelImplCopyWith<_$ServantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
