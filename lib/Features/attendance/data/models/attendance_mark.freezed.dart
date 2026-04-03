// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_mark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AttendanceMark _$AttendanceMarkFromJson(Map<String, dynamic> json) {
  return _AttendanceMark.fromJson(json);
}

/// @nodoc
mixin _$AttendanceMark {
  String get studentId => throw _privateConstructorUsedError;
  String get studentNameSnapshot => throw _privateConstructorUsedError;
  @AttendanceMarkStatusJsonConverter()
  AttendanceMarkStatus get status => throw _privateConstructorUsedError;
  String get markedByUserId => throw _privateConstructorUsedError;
  String get markedByName => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get markedAt => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceMarkCopyWith<AttendanceMark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceMarkCopyWith<$Res> {
  factory $AttendanceMarkCopyWith(
    AttendanceMark value,
    $Res Function(AttendanceMark) then,
  ) = _$AttendanceMarkCopyWithImpl<$Res, AttendanceMark>;
  @useResult
  $Res call({
    String studentId,
    String studentNameSnapshot,
    @AttendanceMarkStatusJsonConverter() AttendanceMarkStatus status,
    String markedByUserId,
    String markedByName,
    @_RequiredTimestampConverter() DateTime markedAt,
    @_RequiredTimestampConverter() DateTime updatedAt,
    String? note,
  });
}

/// @nodoc
class _$AttendanceMarkCopyWithImpl<$Res, $Val extends AttendanceMark>
    implements $AttendanceMarkCopyWith<$Res> {
  _$AttendanceMarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentNameSnapshot = null,
    Object? status = null,
    Object? markedByUserId = null,
    Object? markedByName = null,
    Object? markedAt = null,
    Object? updatedAt = null,
    Object? note = freezed,
  }) {
    return _then(
      _value.copyWith(
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentNameSnapshot: null == studentNameSnapshot
                ? _value.studentNameSnapshot
                : studentNameSnapshot // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as AttendanceMarkStatus,
            markedByUserId: null == markedByUserId
                ? _value.markedByUserId
                : markedByUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            markedByName: null == markedByName
                ? _value.markedByName
                : markedByName // ignore: cast_nullable_to_non_nullable
                      as String,
            markedAt: null == markedAt
                ? _value.markedAt
                : markedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AttendanceMarkImplCopyWith<$Res>
    implements $AttendanceMarkCopyWith<$Res> {
  factory _$$AttendanceMarkImplCopyWith(
    _$AttendanceMarkImpl value,
    $Res Function(_$AttendanceMarkImpl) then,
  ) = __$$AttendanceMarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String studentId,
    String studentNameSnapshot,
    @AttendanceMarkStatusJsonConverter() AttendanceMarkStatus status,
    String markedByUserId,
    String markedByName,
    @_RequiredTimestampConverter() DateTime markedAt,
    @_RequiredTimestampConverter() DateTime updatedAt,
    String? note,
  });
}

/// @nodoc
class __$$AttendanceMarkImplCopyWithImpl<$Res>
    extends _$AttendanceMarkCopyWithImpl<$Res, _$AttendanceMarkImpl>
    implements _$$AttendanceMarkImplCopyWith<$Res> {
  __$$AttendanceMarkImplCopyWithImpl(
    _$AttendanceMarkImpl _value,
    $Res Function(_$AttendanceMarkImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentNameSnapshot = null,
    Object? status = null,
    Object? markedByUserId = null,
    Object? markedByName = null,
    Object? markedAt = null,
    Object? updatedAt = null,
    Object? note = freezed,
  }) {
    return _then(
      _$AttendanceMarkImpl(
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentNameSnapshot: null == studentNameSnapshot
            ? _value.studentNameSnapshot
            : studentNameSnapshot // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AttendanceMarkStatus,
        markedByUserId: null == markedByUserId
            ? _value.markedByUserId
            : markedByUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        markedByName: null == markedByName
            ? _value.markedByName
            : markedByName // ignore: cast_nullable_to_non_nullable
                  as String,
        markedAt: null == markedAt
            ? _value.markedAt
            : markedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceMarkImpl extends _AttendanceMark {
  const _$AttendanceMarkImpl({
    required this.studentId,
    required this.studentNameSnapshot,
    @AttendanceMarkStatusJsonConverter() required this.status,
    required this.markedByUserId,
    required this.markedByName,
    @_RequiredTimestampConverter() required this.markedAt,
    @_RequiredTimestampConverter() required this.updatedAt,
    this.note,
  }) : super._();

  factory _$AttendanceMarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceMarkImplFromJson(json);

  @override
  final String studentId;
  @override
  final String studentNameSnapshot;
  @override
  @AttendanceMarkStatusJsonConverter()
  final AttendanceMarkStatus status;
  @override
  final String markedByUserId;
  @override
  final String markedByName;
  @override
  @_RequiredTimestampConverter()
  final DateTime markedAt;
  @override
  @_RequiredTimestampConverter()
  final DateTime updatedAt;
  @override
  final String? note;

  @override
  String toString() {
    return 'AttendanceMark(studentId: $studentId, studentNameSnapshot: $studentNameSnapshot, status: $status, markedByUserId: $markedByUserId, markedByName: $markedByName, markedAt: $markedAt, updatedAt: $updatedAt, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceMarkImpl &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentNameSnapshot, studentNameSnapshot) ||
                other.studentNameSnapshot == studentNameSnapshot) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.markedByUserId, markedByUserId) ||
                other.markedByUserId == markedByUserId) &&
            (identical(other.markedByName, markedByName) ||
                other.markedByName == markedByName) &&
            (identical(other.markedAt, markedAt) ||
                other.markedAt == markedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    studentId,
    studentNameSnapshot,
    status,
    markedByUserId,
    markedByName,
    markedAt,
    updatedAt,
    note,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceMarkImplCopyWith<_$AttendanceMarkImpl> get copyWith =>
      __$$AttendanceMarkImplCopyWithImpl<_$AttendanceMarkImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceMarkImplToJson(this);
  }
}

abstract class _AttendanceMark extends AttendanceMark {
  const factory _AttendanceMark({
    required final String studentId,
    required final String studentNameSnapshot,
    @AttendanceMarkStatusJsonConverter()
    required final AttendanceMarkStatus status,
    required final String markedByUserId,
    required final String markedByName,
    @_RequiredTimestampConverter() required final DateTime markedAt,
    @_RequiredTimestampConverter() required final DateTime updatedAt,
    final String? note,
  }) = _$AttendanceMarkImpl;
  const _AttendanceMark._() : super._();

  factory _AttendanceMark.fromJson(Map<String, dynamic> json) =
      _$AttendanceMarkImpl.fromJson;

  @override
  String get studentId;
  @override
  String get studentNameSnapshot;
  @override
  @AttendanceMarkStatusJsonConverter()
  AttendanceMarkStatus get status;
  @override
  String get markedByUserId;
  @override
  String get markedByName;
  @override
  @_RequiredTimestampConverter()
  DateTime get markedAt;
  @override
  @_RequiredTimestampConverter()
  DateTime get updatedAt;
  @override
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceMarkImplCopyWith<_$AttendanceMarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
