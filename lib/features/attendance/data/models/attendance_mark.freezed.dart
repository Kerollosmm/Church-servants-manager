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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendanceMark _$AttendanceMarkFromJson(Map<String, dynamic> json) {
  return _AttendanceMark.fromJson(json);
}

/// @nodoc
mixin _$AttendanceMark {
  /// The student document ID (used as the Firestore mark document ID).
  @HiveField(0)
  String get studentId => throw _privateConstructorUsedError;

  /// The student's display name captured at mark time.
  @HiveField(1)
  String get studentNameSnapshot => throw _privateConstructorUsedError;

  /// Optional UID of the student's auth account (null if student has no account).
  @HiveField(2)
  String? get studentUid => throw _privateConstructorUsedError;

  /// The attendance status of the student.
  @HiveField(3)
  @AttendanceMarkStatusJsonConverter()
  AttendanceMarkStatus get status => throw _privateConstructorUsedError;

  /// UID of the servant/admin who created this mark.
  @HiveField(4)
  String get markedByUserId => throw _privateConstructorUsedError;

  /// Name of the servant/admin who created this mark.
  @HiveField(5)
  String get markedByName => throw _privateConstructorUsedError;

  /// Device-side timestamp when the mark was first created.
  @HiveField(6)
  @_RequiredTimestampConverter()
  DateTime get markedAt => throw _privateConstructorUsedError;

  /// Device-side timestamp of the last update to this mark.
  @HiveField(7)
  @_RequiredTimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Server-side timestamp set by Firestore on write (nullable).
  @HiveField(8)
  @FirestoreTimestampConverter()
  DateTime? get serverUpdatedAt => throw _privateConstructorUsedError;

  /// Optional note added by the servant when marking.
  @HiveField(9)
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceMarkCopyWith<AttendanceMark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceMarkCopyWith<$Res> {
  factory $AttendanceMarkCopyWith(
          AttendanceMark value, $Res Function(AttendanceMark) then) =
      _$AttendanceMarkCopyWithImpl<$Res, AttendanceMark>;
  @useResult
  $Res call(
      {@HiveField(0) String studentId,
      @HiveField(1) String studentNameSnapshot,
      @HiveField(2) String? studentUid,
      @HiveField(3)
      @AttendanceMarkStatusJsonConverter()
      AttendanceMarkStatus status,
      @HiveField(4) String markedByUserId,
      @HiveField(5) String markedByName,
      @HiveField(6) @_RequiredTimestampConverter() DateTime markedAt,
      @HiveField(7) @_RequiredTimestampConverter() DateTime updatedAt,
      @HiveField(8) @FirestoreTimestampConverter() DateTime? serverUpdatedAt,
      @HiveField(9) String? note});
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
    Object? studentUid = freezed,
    Object? status = null,
    Object? markedByUserId = null,
    Object? markedByName = null,
    Object? markedAt = null,
    Object? updatedAt = null,
    Object? serverUpdatedAt = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentNameSnapshot: null == studentNameSnapshot
          ? _value.studentNameSnapshot
          : studentNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      studentUid: freezed == studentUid
          ? _value.studentUid
          : studentUid // ignore: cast_nullable_to_non_nullable
              as String?,
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
      serverUpdatedAt: freezed == serverUpdatedAt
          ? _value.serverUpdatedAt
          : serverUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceMarkImplCopyWith<$Res>
    implements $AttendanceMarkCopyWith<$Res> {
  factory _$$AttendanceMarkImplCopyWith(_$AttendanceMarkImpl value,
          $Res Function(_$AttendanceMarkImpl) then) =
      __$$AttendanceMarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String studentId,
      @HiveField(1) String studentNameSnapshot,
      @HiveField(2) String? studentUid,
      @HiveField(3)
      @AttendanceMarkStatusJsonConverter()
      AttendanceMarkStatus status,
      @HiveField(4) String markedByUserId,
      @HiveField(5) String markedByName,
      @HiveField(6) @_RequiredTimestampConverter() DateTime markedAt,
      @HiveField(7) @_RequiredTimestampConverter() DateTime updatedAt,
      @HiveField(8) @FirestoreTimestampConverter() DateTime? serverUpdatedAt,
      @HiveField(9) String? note});
}

/// @nodoc
class __$$AttendanceMarkImplCopyWithImpl<$Res>
    extends _$AttendanceMarkCopyWithImpl<$Res, _$AttendanceMarkImpl>
    implements _$$AttendanceMarkImplCopyWith<$Res> {
  __$$AttendanceMarkImplCopyWithImpl(
      _$AttendanceMarkImpl _value, $Res Function(_$AttendanceMarkImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentId = null,
    Object? studentNameSnapshot = null,
    Object? studentUid = freezed,
    Object? status = null,
    Object? markedByUserId = null,
    Object? markedByName = null,
    Object? markedAt = null,
    Object? updatedAt = null,
    Object? serverUpdatedAt = freezed,
    Object? note = freezed,
  }) {
    return _then(_$AttendanceMarkImpl(
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentNameSnapshot: null == studentNameSnapshot
          ? _value.studentNameSnapshot
          : studentNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      studentUid: freezed == studentUid
          ? _value.studentUid
          : studentUid // ignore: cast_nullable_to_non_nullable
              as String?,
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
      serverUpdatedAt: freezed == serverUpdatedAt
          ? _value.serverUpdatedAt
          : serverUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceMarkImpl extends _AttendanceMark {
  const _$AttendanceMarkImpl(
      {@HiveField(0) required this.studentId,
      @HiveField(1) required this.studentNameSnapshot,
      @HiveField(2) this.studentUid,
      @HiveField(3) @AttendanceMarkStatusJsonConverter() required this.status,
      @HiveField(4) required this.markedByUserId,
      @HiveField(5) required this.markedByName,
      @HiveField(6) @_RequiredTimestampConverter() required this.markedAt,
      @HiveField(7) @_RequiredTimestampConverter() required this.updatedAt,
      @HiveField(8) @FirestoreTimestampConverter() this.serverUpdatedAt,
      @HiveField(9) this.note})
      : super._();

  factory _$AttendanceMarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceMarkImplFromJson(json);

  /// The student document ID (used as the Firestore mark document ID).
  @override
  @HiveField(0)
  final String studentId;

  /// The student's display name captured at mark time.
  @override
  @HiveField(1)
  final String studentNameSnapshot;

  /// Optional UID of the student's auth account (null if student has no account).
  @override
  @HiveField(2)
  final String? studentUid;

  /// The attendance status of the student.
  @override
  @HiveField(3)
  @AttendanceMarkStatusJsonConverter()
  final AttendanceMarkStatus status;

  /// UID of the servant/admin who created this mark.
  @override
  @HiveField(4)
  final String markedByUserId;

  /// Name of the servant/admin who created this mark.
  @override
  @HiveField(5)
  final String markedByName;

  /// Device-side timestamp when the mark was first created.
  @override
  @HiveField(6)
  @_RequiredTimestampConverter()
  final DateTime markedAt;

  /// Device-side timestamp of the last update to this mark.
  @override
  @HiveField(7)
  @_RequiredTimestampConverter()
  final DateTime updatedAt;

  /// Server-side timestamp set by Firestore on write (nullable).
  @override
  @HiveField(8)
  @FirestoreTimestampConverter()
  final DateTime? serverUpdatedAt;

  /// Optional note added by the servant when marking.
  @override
  @HiveField(9)
  final String? note;

  @override
  String toString() {
    return 'AttendanceMark(studentId: $studentId, studentNameSnapshot: $studentNameSnapshot, studentUid: $studentUid, status: $status, markedByUserId: $markedByUserId, markedByName: $markedByName, markedAt: $markedAt, updatedAt: $updatedAt, serverUpdatedAt: $serverUpdatedAt, note: $note)';
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
            (identical(other.studentUid, studentUid) ||
                other.studentUid == studentUid) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.markedByUserId, markedByUserId) ||
                other.markedByUserId == markedByUserId) &&
            (identical(other.markedByName, markedByName) ||
                other.markedByName == markedByName) &&
            (identical(other.markedAt, markedAt) ||
                other.markedAt == markedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.serverUpdatedAt, serverUpdatedAt) ||
                other.serverUpdatedAt == serverUpdatedAt) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      studentId,
      studentNameSnapshot,
      studentUid,
      status,
      markedByUserId,
      markedByName,
      markedAt,
      updatedAt,
      serverUpdatedAt,
      note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceMarkImplCopyWith<_$AttendanceMarkImpl> get copyWith =>
      __$$AttendanceMarkImplCopyWithImpl<_$AttendanceMarkImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceMarkImplToJson(
      this,
    );
  }
}

abstract class _AttendanceMark extends AttendanceMark {
  const factory _AttendanceMark(
      {@HiveField(0) required final String studentId,
      @HiveField(1) required final String studentNameSnapshot,
      @HiveField(2) final String? studentUid,
      @HiveField(3)
      @AttendanceMarkStatusJsonConverter()
      required final AttendanceMarkStatus status,
      @HiveField(4) required final String markedByUserId,
      @HiveField(5) required final String markedByName,
      @HiveField(6)
      @_RequiredTimestampConverter()
      required final DateTime markedAt,
      @HiveField(7)
      @_RequiredTimestampConverter()
      required final DateTime updatedAt,
      @HiveField(8)
      @FirestoreTimestampConverter()
      final DateTime? serverUpdatedAt,
      @HiveField(9) final String? note}) = _$AttendanceMarkImpl;
  const _AttendanceMark._() : super._();

  factory _AttendanceMark.fromJson(Map<String, dynamic> json) =
      _$AttendanceMarkImpl.fromJson;

  @override

  /// The student document ID (used as the Firestore mark document ID).
  @HiveField(0)
  String get studentId;
  @override

  /// The student's display name captured at mark time.
  @HiveField(1)
  String get studentNameSnapshot;
  @override

  /// Optional UID of the student's auth account (null if student has no account).
  @HiveField(2)
  String? get studentUid;
  @override

  /// The attendance status of the student.
  @HiveField(3)
  @AttendanceMarkStatusJsonConverter()
  AttendanceMarkStatus get status;
  @override

  /// UID of the servant/admin who created this mark.
  @HiveField(4)
  String get markedByUserId;
  @override

  /// Name of the servant/admin who created this mark.
  @HiveField(5)
  String get markedByName;
  @override

  /// Device-side timestamp when the mark was first created.
  @HiveField(6)
  @_RequiredTimestampConverter()
  DateTime get markedAt;
  @override

  /// Device-side timestamp of the last update to this mark.
  @HiveField(7)
  @_RequiredTimestampConverter()
  DateTime get updatedAt;
  @override

  /// Server-side timestamp set by Firestore on write (nullable).
  @HiveField(8)
  @FirestoreTimestampConverter()
  DateTime? get serverUpdatedAt;
  @override

  /// Optional note added by the servant when marking.
  @HiveField(9)
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceMarkImplCopyWith<_$AttendanceMarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
