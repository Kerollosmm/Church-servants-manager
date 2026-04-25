// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendanceSession _$AttendanceSessionFromJson(Map<String, dynamic> json) {
  return _AttendanceSession.fromJson(json);
}

/// @nodoc
mixin _$AttendanceSession {
  String get id => throw _privateConstructorUsedError;
  String get teamId => throw _privateConstructorUsedError;
  String? get teamNameSnapshot => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String get dateKey => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get startsAt => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get endsAt => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  String get createdByUserId => throw _privateConstructorUsedError;
  String get createdByName => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @_RequiredTimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  bool get isClosed => throw _privateConstructorUsedError;
  List<String> get studentIdsSnapshot => throw _privateConstructorUsedError;
  Map<String, String> get studentNameSnapshots =>
      throw _privateConstructorUsedError;
  int get presentCount => throw _privateConstructorUsedError;
  int get lateCount => throw _privateConstructorUsedError;
  int get absentCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceSessionCopyWith<AttendanceSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceSessionCopyWith<$Res> {
  factory $AttendanceSessionCopyWith(
          AttendanceSession value, $Res Function(AttendanceSession) then) =
      _$AttendanceSessionCopyWithImpl<$Res, AttendanceSession>;
  @useResult
  $Res call(
      {String id,
      String teamId,
      String? teamNameSnapshot,
      String? title,
      String dateKey,
      @_RequiredTimestampConverter() DateTime startsAt,
      @_RequiredTimestampConverter() DateTime endsAt,
      int durationMinutes,
      String createdByUserId,
      String createdByName,
      @_RequiredTimestampConverter() DateTime createdAt,
      @_RequiredTimestampConverter() DateTime updatedAt,
      bool isClosed,
      List<String> studentIdsSnapshot,
      Map<String, String> studentNameSnapshots,
      int presentCount,
      int lateCount,
      int absentCount});
}

/// @nodoc
class _$AttendanceSessionCopyWithImpl<$Res, $Val extends AttendanceSession>
    implements $AttendanceSessionCopyWith<$Res> {
  _$AttendanceSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teamId = null,
    Object? teamNameSnapshot = freezed,
    Object? title = freezed,
    Object? dateKey = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? durationMinutes = null,
    Object? createdByUserId = null,
    Object? createdByName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isClosed = null,
    Object? studentIdsSnapshot = null,
    Object? studentNameSnapshots = null,
    Object? presentCount = null,
    Object? lateCount = null,
    Object? absentCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      teamNameSnapshot: freezed == teamNameSnapshot
          ? _value.teamNameSnapshot
          : teamNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      dateKey: null == dateKey
          ? _value.dateKey
          : dateKey // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      createdByUserId: null == createdByUserId
          ? _value.createdByUserId
          : createdByUserId // ignore: cast_nullable_to_non_nullable
              as String,
      createdByName: null == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
      studentIdsSnapshot: null == studentIdsSnapshot
          ? _value.studentIdsSnapshot
          : studentIdsSnapshot // ignore: cast_nullable_to_non_nullable
              as List<String>,
      studentNameSnapshots: null == studentNameSnapshots
          ? _value.studentNameSnapshots
          : studentNameSnapshots // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      presentCount: null == presentCount
          ? _value.presentCount
          : presentCount // ignore: cast_nullable_to_non_nullable
              as int,
      lateCount: null == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceSessionImplCopyWith<$Res>
    implements $AttendanceSessionCopyWith<$Res> {
  factory _$$AttendanceSessionImplCopyWith(_$AttendanceSessionImpl value,
          $Res Function(_$AttendanceSessionImpl) then) =
      __$$AttendanceSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String teamId,
      String? teamNameSnapshot,
      String? title,
      String dateKey,
      @_RequiredTimestampConverter() DateTime startsAt,
      @_RequiredTimestampConverter() DateTime endsAt,
      int durationMinutes,
      String createdByUserId,
      String createdByName,
      @_RequiredTimestampConverter() DateTime createdAt,
      @_RequiredTimestampConverter() DateTime updatedAt,
      bool isClosed,
      List<String> studentIdsSnapshot,
      Map<String, String> studentNameSnapshots,
      int presentCount,
      int lateCount,
      int absentCount});
}

/// @nodoc
class __$$AttendanceSessionImplCopyWithImpl<$Res>
    extends _$AttendanceSessionCopyWithImpl<$Res, _$AttendanceSessionImpl>
    implements _$$AttendanceSessionImplCopyWith<$Res> {
  __$$AttendanceSessionImplCopyWithImpl(_$AttendanceSessionImpl _value,
      $Res Function(_$AttendanceSessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? teamId = null,
    Object? teamNameSnapshot = freezed,
    Object? title = freezed,
    Object? dateKey = null,
    Object? startsAt = null,
    Object? endsAt = null,
    Object? durationMinutes = null,
    Object? createdByUserId = null,
    Object? createdByName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isClosed = null,
    Object? studentIdsSnapshot = null,
    Object? studentNameSnapshots = null,
    Object? presentCount = null,
    Object? lateCount = null,
    Object? absentCount = null,
  }) {
    return _then(_$AttendanceSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      teamNameSnapshot: freezed == teamNameSnapshot
          ? _value.teamNameSnapshot
          : teamNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      dateKey: null == dateKey
          ? _value.dateKey
          : dateKey // ignore: cast_nullable_to_non_nullable
              as String,
      startsAt: null == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      createdByUserId: null == createdByUserId
          ? _value.createdByUserId
          : createdByUserId // ignore: cast_nullable_to_non_nullable
              as String,
      createdByName: null == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
      studentIdsSnapshot: null == studentIdsSnapshot
          ? _value._studentIdsSnapshot
          : studentIdsSnapshot // ignore: cast_nullable_to_non_nullable
              as List<String>,
      studentNameSnapshots: null == studentNameSnapshots
          ? _value._studentNameSnapshots
          : studentNameSnapshots // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      presentCount: null == presentCount
          ? _value.presentCount
          : presentCount // ignore: cast_nullable_to_non_nullable
              as int,
      lateCount: null == lateCount
          ? _value.lateCount
          : lateCount // ignore: cast_nullable_to_non_nullable
              as int,
      absentCount: null == absentCount
          ? _value.absentCount
          : absentCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceSessionImpl extends _AttendanceSession {
  const _$AttendanceSessionImpl(
      {required this.id,
      required this.teamId,
      this.teamNameSnapshot,
      this.title,
      required this.dateKey,
      @_RequiredTimestampConverter() required this.startsAt,
      @_RequiredTimestampConverter() required this.endsAt,
      required this.durationMinutes,
      required this.createdByUserId,
      required this.createdByName,
      @_RequiredTimestampConverter() required this.createdAt,
      @_RequiredTimestampConverter() required this.updatedAt,
      this.isClosed = false,
      final List<String> studentIdsSnapshot = const <String>[],
      final Map<String, String> studentNameSnapshots = const <String, String>{},
      this.presentCount = 0,
      this.lateCount = 0,
      this.absentCount = 0})
      : _studentIdsSnapshot = studentIdsSnapshot,
        _studentNameSnapshots = studentNameSnapshots,
        super._();

  factory _$AttendanceSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String teamId;
  @override
  final String? teamNameSnapshot;
  @override
  final String? title;
  @override
  final String dateKey;
  @override
  @_RequiredTimestampConverter()
  final DateTime startsAt;
  @override
  @_RequiredTimestampConverter()
  final DateTime endsAt;
  @override
  final int durationMinutes;
  @override
  final String createdByUserId;
  @override
  final String createdByName;
  @override
  @_RequiredTimestampConverter()
  final DateTime createdAt;
  @override
  @_RequiredTimestampConverter()
  final DateTime updatedAt;
  @override
  @JsonKey()
  final bool isClosed;
  final List<String> _studentIdsSnapshot;
  @override
  @JsonKey()
  List<String> get studentIdsSnapshot {
    if (_studentIdsSnapshot is EqualUnmodifiableListView)
      return _studentIdsSnapshot;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_studentIdsSnapshot);
  }

  final Map<String, String> _studentNameSnapshots;
  @override
  @JsonKey()
  Map<String, String> get studentNameSnapshots {
    if (_studentNameSnapshots is EqualUnmodifiableMapView)
      return _studentNameSnapshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_studentNameSnapshots);
  }

  @override
  @JsonKey()
  final int presentCount;
  @override
  @JsonKey()
  final int lateCount;
  @override
  @JsonKey()
  final int absentCount;

  @override
  String toString() {
    return 'AttendanceSession(id: $id, teamId: $teamId, teamNameSnapshot: $teamNameSnapshot, title: $title, dateKey: $dateKey, startsAt: $startsAt, endsAt: $endsAt, durationMinutes: $durationMinutes, createdByUserId: $createdByUserId, createdByName: $createdByName, createdAt: $createdAt, updatedAt: $updatedAt, isClosed: $isClosed, studentIdsSnapshot: $studentIdsSnapshot, studentNameSnapshots: $studentNameSnapshots, presentCount: $presentCount, lateCount: $lateCount, absentCount: $absentCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.teamNameSnapshot, teamNameSnapshot) ||
                other.teamNameSnapshot == teamNameSnapshot) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dateKey, dateKey) || other.dateKey == dateKey) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.createdByUserId, createdByUserId) ||
                other.createdByUserId == createdByUserId) &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isClosed, isClosed) ||
                other.isClosed == isClosed) &&
            const DeepCollectionEquality()
                .equals(other._studentIdsSnapshot, _studentIdsSnapshot) &&
            const DeepCollectionEquality()
                .equals(other._studentNameSnapshots, _studentNameSnapshots) &&
            (identical(other.presentCount, presentCount) ||
                other.presentCount == presentCount) &&
            (identical(other.lateCount, lateCount) ||
                other.lateCount == lateCount) &&
            (identical(other.absentCount, absentCount) ||
                other.absentCount == absentCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      teamId,
      teamNameSnapshot,
      title,
      dateKey,
      startsAt,
      endsAt,
      durationMinutes,
      createdByUserId,
      createdByName,
      createdAt,
      updatedAt,
      isClosed,
      const DeepCollectionEquality().hash(_studentIdsSnapshot),
      const DeepCollectionEquality().hash(_studentNameSnapshots),
      presentCount,
      lateCount,
      absentCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceSessionImplCopyWith<_$AttendanceSessionImpl> get copyWith =>
      __$$AttendanceSessionImplCopyWithImpl<_$AttendanceSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceSessionImplToJson(
      this,
    );
  }
}

abstract class _AttendanceSession extends AttendanceSession {
  const factory _AttendanceSession(
      {required final String id,
      required final String teamId,
      final String? teamNameSnapshot,
      final String? title,
      required final String dateKey,
      @_RequiredTimestampConverter() required final DateTime startsAt,
      @_RequiredTimestampConverter() required final DateTime endsAt,
      required final int durationMinutes,
      required final String createdByUserId,
      required final String createdByName,
      @_RequiredTimestampConverter() required final DateTime createdAt,
      @_RequiredTimestampConverter() required final DateTime updatedAt,
      final bool isClosed,
      final List<String> studentIdsSnapshot,
      final Map<String, String> studentNameSnapshots,
      final int presentCount,
      final int lateCount,
      final int absentCount}) = _$AttendanceSessionImpl;
  const _AttendanceSession._() : super._();

  factory _AttendanceSession.fromJson(Map<String, dynamic> json) =
      _$AttendanceSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get teamId;
  @override
  String? get teamNameSnapshot;
  @override
  String? get title;
  @override
  String get dateKey;
  @override
  @_RequiredTimestampConverter()
  DateTime get startsAt;
  @override
  @_RequiredTimestampConverter()
  DateTime get endsAt;
  @override
  int get durationMinutes;
  @override
  String get createdByUserId;
  @override
  String get createdByName;
  @override
  @_RequiredTimestampConverter()
  DateTime get createdAt;
  @override
  @_RequiredTimestampConverter()
  DateTime get updatedAt;
  @override
  bool get isClosed;
  @override
  List<String> get studentIdsSnapshot;
  @override
  Map<String, String> get studentNameSnapshots;
  @override
  int get presentCount;
  @override
  int get lateCount;
  @override
  int get absentCount;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceSessionImplCopyWith<_$AttendanceSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
