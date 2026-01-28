// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StudentModels _$StudentModelsFromJson(Map<String, dynamic> json) {
  return _StudentModels.fromJson(json);
}

/// @nodoc
mixin _$StudentModels {
  String get studentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get grade =>
      throw _privateConstructorUsedError; // grade on school or collage
  EducationStage get eductionStage =>
      throw _privateConstructorUsedError; // {school, collage}
  String get phoneNumber => throw _privateConstructorUsedError;
  List<String> get parentsPhone => throw _privateConstructorUsedError;
  Group get group =>
      throw _privateConstructorUsedError; // GROUP NAME {YEAR1, YEAR2, YEAR3}
  String get createdBy => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentModelsCopyWith<StudentModels> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentModelsCopyWith<$Res> {
  factory $StudentModelsCopyWith(
          StudentModels value, $Res Function(StudentModels) then) =
      _$StudentModelsCopyWithImpl<$Res, StudentModels>;
  @useResult
  $Res call(
      {String studentId,
      String name,
      String grade,
      EducationStage eductionStage,
      String phoneNumber,
      List<String> parentsPhone,
      Group group,
      String createdBy});
}

/// @nodoc
class _$StudentModelsCopyWithImpl<$Res, $Val extends StudentModels>
    implements $StudentModelsCopyWith<$Res> {
  _$StudentModelsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? name = null,
    Object? grade = null,
    Object? eductionStage = null,
    Object? phoneNumber = null,
    Object? parentsPhone = null,
    Object? group = null,
    Object? createdBy = null,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      eductionStage: null == eductionStage
          ? _value.eductionStage
          : eductionStage // ignore: cast_nullable_to_non_nullable
              as EducationStage,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      parentsPhone: null == parentsPhone
          ? _value.parentsPhone
          : parentsPhone // ignore: cast_nullable_to_non_nullable
              as List<String>,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as Group,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentModelsImplCopyWith<$Res>
    implements $StudentModelsCopyWith<$Res> {
  factory _$$StudentModelsImplCopyWith(
          _$StudentModelsImpl value, $Res Function(_$StudentModelsImpl) then) =
      __$$StudentModelsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String studentId,
      String name,
      String grade,
      EducationStage eductionStage,
      String phoneNumber,
      List<String> parentsPhone,
      Group group,
      String createdBy});
}

/// @nodoc
class __$$StudentModelsImplCopyWithImpl<$Res>
    extends _$StudentModelsCopyWithImpl<$Res, _$StudentModelsImpl>
    implements _$$StudentModelsImplCopyWith<$Res> {
  __$$StudentModelsImplCopyWithImpl(
      _$StudentModelsImpl _value, $Res Function(_$StudentModelsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? name = null,
    Object? grade = null,
    Object? eductionStage = null,
    Object? phoneNumber = null,
    Object? parentsPhone = null,
    Object? group = null,
    Object? createdBy = null,
  }) {
    return _then(_$StudentModelsImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      eductionStage: null == eductionStage
          ? _value.eductionStage
          : eductionStage // ignore: cast_nullable_to_non_nullable
              as EducationStage,
      phoneNumber: null == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      parentsPhone: null == parentsPhone
          ? _value._parentsPhone
          : parentsPhone // ignore: cast_nullable_to_non_nullable
              as List<String>,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as Group,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentModelsImpl implements _StudentModels {
  const _$StudentModelsImpl(
      {required this.studentId,
      required this.name,
      required this.grade,
      required this.eductionStage,
      required this.phoneNumber,
      required final List<String> parentsPhone,
      required this.group,
      required this.createdBy})
      : _parentsPhone = parentsPhone;

  factory _$StudentModelsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentModelsImplFromJson(json);

  @override
  final String studentId;
  @override
  final String name;
  @override
  final String grade;
// grade on school or collage
  @override
  final EducationStage eductionStage;
// {school, collage}
  @override
  final String phoneNumber;
  final List<String> _parentsPhone;
  @override
  List<String> get parentsPhone {
    if (_parentsPhone is EqualUnmodifiableListView) return _parentsPhone;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parentsPhone);
  }

  @override
  final Group group;
// GROUP NAME {YEAR1, YEAR2, YEAR3}
  @override
  final String createdBy;

  @override
  String toString() {
    return 'StudentModels(studentId: $studentId, name: $name, grade: $grade, eductionStage: $eductionStage, phoneNumber: $phoneNumber, parentsPhone: $parentsPhone, group: $group, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentModelsImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.eductionStage, eductionStage) ||
                other.eductionStage == eductionStage) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            const DeepCollectionEquality()
                .equals(other._parentsPhone, _parentsPhone) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      studentId,
      name,
      grade,
      eductionStage,
      phoneNumber,
      const DeepCollectionEquality().hash(_parentsPhone),
      group,
      createdBy);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentModelsImplCopyWith<_$StudentModelsImpl> get copyWith =>
      __$$StudentModelsImplCopyWithImpl<_$StudentModelsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentModelsImplToJson(
      this,
    );
  }
}

abstract class _StudentModels implements StudentModels {
  const factory _StudentModels(
      {required final String studentId,
      required final String name,
      required final String grade,
      required final EducationStage eductionStage,
      required final String phoneNumber,
      required final List<String> parentsPhone,
      required final Group group,
      required final String createdBy}) = _$StudentModelsImpl;

  factory _StudentModels.fromJson(Map<String, dynamic> json) =
      _$StudentModelsImpl.fromJson;

  @override
  String get studentId;
  @override
  String get name;
  @override
  String get grade;
  @override // grade on school or collage
  EducationStage get eductionStage;
  @override // {school, collage}
  String get phoneNumber;
  @override
  List<String> get parentsPhone;
  @override
  Group get group;
  @override // GROUP NAME {YEAR1, YEAR2, YEAR3}
  String get createdBy;
  @override
  @JsonKey(ignore: true)
  _$$StudentModelsImplCopyWith<_$StudentModelsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
