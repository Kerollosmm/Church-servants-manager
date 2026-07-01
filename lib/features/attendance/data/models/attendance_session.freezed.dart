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
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AttendanceSessionModel _$AttendanceSessionModelFromJson(
  Map<String, dynamic> json,
) {
  return _AttendanceSessionModel.fromJson(json);
}

/// @nodoc
mixin _$AttendanceSessionModel {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get teamId => throw _privateConstructorUsedError;
  @HiveField(2)
  String? get teamNameSnapshot => throw _privateConstructorUsedError;
  @HiveField(3)
  String? get title => throw _privateConstructorUsedError;
  @HiveField(4)
  String get dateKey => throw _privateConstructorUsedError;
  @HiveField(5)
  @_RequiredTimestampConverter()
  DateTime get startsAt => throw _privateConstructorUsedError;
  @HiveField(6)
  @_RequiredTimestampConverter()
  DateTime get endsAt => throw _privateConstructorUsedError;
  @HiveField(7)
  int get durationMinutes => throw _privateConstructorUsedError;
  @HiveField(8)
  String get createdByUserId => throw _privateConstructorUsedError;
  @HiveField(9)
  String get createdByName => throw _privateConstructorUsedError;
  @HiveField(10)
  @_RequiredTimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(11)
  @_RequiredTimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @HiveField(12)
  bool get isClosed => throw _privateConstructorUsedError;
  @HiveField(13)
  List<String> get studentIdsSnapshot => throw _privateConstructorUsedError;
  @HiveField(14)
  Map<String, String> get studentNameSnapshots =>
      throw _privateConstructorUsedError;
  @HiveField(15)
  int get presentCount => throw _privateConstructorUsedError;
  @HiveField(16)
  int get lateCount => throw _privateConstructorUsedError;
  @HiveField(17)
  int get absentCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttendanceSessionModelCopyWith<AttendanceSessionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceSessionModelCopyWith<$Res> {
  factory $AttendanceSessionModelCopyWith(
    AttendanceSessionModel value,
    $Res Function(AttendanceSessionModel) then,
  ) = _$AttendanceSessionModelCopyWithImpl<$Res, AttendanceSessionModel>;
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String teamId,
    @HiveField(2) String? teamNameSnapshot,
    @HiveField(3) String? title,
    @HiveField(4) String dateKey,
    @HiveField(5) @_RequiredTimestampConverter() DateTime startsAt,
    @HiveField(6) @_RequiredTimestampConverter() DateTime endsAt,
    @HiveField(7) int durationMinutes,
    @HiveField(8) String createdByUserId,
    @HiveField(9) String createdByName,
    @HiveField(10) @_RequiredTimestampConverter() DateTime createdAt,
    @HiveField(11) @_RequiredTimestampConverter() DateTime updatedAt,
    @HiveField(12) bool isClosed,
    @HiveField(13) List<String> studentIdsSnapshot,
    @HiveField(14) Map<String, String> studentNameSnapshots,
    @HiveField(15) int presentCount,
    @HiveField(16) int lateCount,
    @HiveField(17) int absentCount,
  });
}

/// @nodoc
class _$AttendanceSessionModelCopyWithImpl<
  $Res,
  $Val extends AttendanceSessionModel
>
    implements $AttendanceSessionModelCopyWith<$Res> {
  _$AttendanceSessionModelCopyWithImpl(this._value, this._then);

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
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AttendanceSessionModelImplCopyWith<$Res>
    implements $AttendanceSessionModelCopyWith<$Res> {
  factory _$$AttendanceSessionModelImplCopyWith(
    _$AttendanceSessionModelImpl value,
    $Res Function(_$AttendanceSessionModelImpl) then,
  ) = __$$AttendanceSessionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String teamId,
    @HiveField(2) String? teamNameSnapshot,
    @HiveField(3) String? title,
    @HiveField(4) String dateKey,
    @HiveField(5) @_RequiredTimestampConverter() DateTime startsAt,
    @HiveField(6) @_RequiredTimestampConverter() DateTime endsAt,
    @HiveField(7) int durationMinutes,
    @HiveField(8) String createdByUserId,
    @HiveField(9) String createdByName,
    @HiveField(10) @_RequiredTimestampConverter() DateTime createdAt,
    @HiveField(11) @_RequiredTimestampConverter() DateTime updatedAt,
    @HiveField(12) bool isClosed,
    @HiveField(13) List<String> studentIdsSnapshot,
    @HiveField(14) Map<String, String> studentNameSnapshots,
    @HiveField(15) int presentCount,
    @HiveField(16) int lateCount,
    @HiveField(17) int absentCount,
  });
}

/// @nodoc
class __$$AttendanceSessionModelImplCopyWithImpl<$Res>
    extends
        _$AttendanceSessionModelCopyWithImpl<$Res, _$AttendanceSessionModelImpl>
    implements _$$AttendanceSessionModelImplCopyWith<$Res> {
  __$$AttendanceSessionModelImplCopyWithImpl(
    _$AttendanceSessionModelImpl _value,
    $Res Function(_$AttendanceSessionModelImpl) _then,
  ) : super(_value, _then);

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
    return _then(
      _$AttendanceSessionModelImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceSessionModelImpl extends _AttendanceSessionModel {
  const _$AttendanceSessionModelImpl({
    @HiveField(0) required this.id,
    @HiveField(1) required this.teamId,
    @HiveField(2) this.teamNameSnapshot,
    @HiveField(3) this.title,
    @HiveField(4) required this.dateKey,
    @HiveField(5) @_RequiredTimestampConverter() required this.startsAt,
    @HiveField(6) @_RequiredTimestampConverter() required this.endsAt,
    @HiveField(7) required this.durationMinutes,
    @HiveField(8) required this.createdByUserId,
    @HiveField(9) required this.createdByName,
    @HiveField(10) @_RequiredTimestampConverter() required this.createdAt,
    @HiveField(11) @_RequiredTimestampConverter() required this.updatedAt,
    @HiveField(12) this.isClosed = false,
    @HiveField(13) final List<String> studentIdsSnapshot = const <String>[],
    @HiveField(14)
    final Map<String, String> studentNameSnapshots = const <String, String>{},
    @HiveField(15) this.presentCount = 0,
    @HiveField(16) this.lateCount = 0,
    @HiveField(17) this.absentCount = 0,
  }) : _studentIdsSnapshot = studentIdsSnapshot,
       _studentNameSnapshots = studentNameSnapshots,
       super._();

  factory _$AttendanceSessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceSessionModelImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String teamId;
  @override
  @HiveField(2)
  final String? teamNameSnapshot;
  @override
  @HiveField(3)
  final String? title;
  @override
  @HiveField(4)
  final String dateKey;
  @override
  @HiveField(5)
  @_RequiredTimestampConverter()
  final DateTime startsAt;
  @override
  @HiveField(6)
  @_RequiredTimestampConverter()
  final DateTime endsAt;
  @override
  @HiveField(7)
  final int durationMinutes;
  @override
  @HiveField(8)
  final String createdByUserId;
  @override
  @HiveField(9)
  final String createdByName;
  @override
  @HiveField(10)
  @_RequiredTimestampConverter()
  final DateTime createdAt;
  @override
  @HiveField(11)
  @_RequiredTimestampConverter()
  final DateTime updatedAt;
  @override
  @JsonKey()
  @HiveField(12)
  final bool isClosed;
  final List<String> _studentIdsSnapshot;
  @override
  @JsonKey()
  @HiveField(13)
  List<String> get studentIdsSnapshot {
    if (_studentIdsSnapshot is EqualUnmodifiableListView)
      return _studentIdsSnapshot;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_studentIdsSnapshot);
  }

  final Map<String, String> _studentNameSnapshots;
  @override
  @JsonKey()
  @HiveField(14)
  Map<String, String> get studentNameSnapshots {
    if (_studentNameSnapshots is EqualUnmodifiableMapView)
      return _studentNameSnapshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_studentNameSnapshots);
  }

  @override
  @JsonKey()
  @HiveField(15)
  final int presentCount;
  @override
  @JsonKey()
  @HiveField(16)
  final int lateCount;
  @override
  @JsonKey()
  @HiveField(17)
  final int absentCount;

  @override
  String toString() {
    return 'AttendanceSessionModel(id: $id, teamId: $teamId, teamNameSnapshot: $teamNameSnapshot, title: $title, dateKey: $dateKey, startsAt: $startsAt, endsAt: $endsAt, durationMinutes: $durationMinutes, createdByUserId: $createdByUserId, createdByName: $createdByName, createdAt: $createdAt, updatedAt: $updatedAt, isClosed: $isClosed, studentIdsSnapshot: $studentIdsSnapshot, studentNameSnapshots: $studentNameSnapshots, presentCount: $presentCount, lateCount: $lateCount, absentCount: $absentCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceSessionModelImpl &&
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
            const DeepCollectionEquality().equals(
              other._studentIdsSnapshot,
              _studentIdsSnapshot,
            ) &&
            const DeepCollectionEquality().equals(
              other._studentNameSnapshots,
              _studentNameSnapshots,
            ) &&
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
    absentCount,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceSessionModelImplCopyWith<_$AttendanceSessionModelImpl>
  get copyWith =>
      __$$AttendanceSessionModelImplCopyWithImpl<_$AttendanceSessionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceSessionModelImplToJson(this);
  }
}

abstract class _AttendanceSessionModel extends AttendanceSessionModel {
  const factory _AttendanceSessionModel({
    @HiveField(0) required final String id,
    @HiveField(1) required final String teamId,
    @HiveField(2) final String? teamNameSnapshot,
    @HiveField(3) final String? title,
    @HiveField(4) required final String dateKey,
    @HiveField(5)
    @_RequiredTimestampConverter()
    required final DateTime startsAt,
    @HiveField(6) @_RequiredTimestampConverter() required final DateTime endsAt,
    @HiveField(7) required final int durationMinutes,
    @HiveField(8) required final String createdByUserId,
    @HiveField(9) required final String createdByName,
    @HiveField(10)
    @_RequiredTimestampConverter()
    required final DateTime createdAt,
    @HiveField(11)
    @_RequiredTimestampConverter()
    required final DateTime updatedAt,
    @HiveField(12) final bool isClosed,
    @HiveField(13) final List<String> studentIdsSnapshot,
    @HiveField(14) final Map<String, String> studentNameSnapshots,
    @HiveField(15) final int presentCount,
    @HiveField(16) final int lateCount,
    @HiveField(17) final int absentCount,
  }) = _$AttendanceSessionModelImpl;
  const _AttendanceSessionModel._() : super._();

  factory _AttendanceSessionModel.fromJson(Map<String, dynamic> json) =
      _$AttendanceSessionModelImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get teamId;
  @override
  @HiveField(2)
  String? get teamNameSnapshot;
  @override
  @HiveField(3)
  String? get title;
  @override
  @HiveField(4)
  String get dateKey;
  @override
  @HiveField(5)
  @_RequiredTimestampConverter()
  DateTime get startsAt;
  @override
  @HiveField(6)
  @_RequiredTimestampConverter()
  DateTime get endsAt;
  @override
  @HiveField(7)
  int get durationMinutes;
  @override
  @HiveField(8)
  String get createdByUserId;
  @override
  @HiveField(9)
  String get createdByName;
  @override
  @HiveField(10)
  @_RequiredTimestampConverter()
  DateTime get createdAt;
  @override
  @HiveField(11)
  @_RequiredTimestampConverter()
  DateTime get updatedAt;
  @override
  @HiveField(12)
  bool get isClosed;
  @override
  @HiveField(13)
  List<String> get studentIdsSnapshot;
  @override
  @HiveField(14)
  Map<String, String> get studentNameSnapshots;
  @override
  @HiveField(15)
  int get presentCount;
  @override
  @HiveField(16)
  int get lateCount;
  @override
  @HiveField(17)
  int get absentCount;
  @override
  @JsonKey(ignore: true)
  _$$AttendanceSessionModelImplCopyWith<_$AttendanceSessionModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
