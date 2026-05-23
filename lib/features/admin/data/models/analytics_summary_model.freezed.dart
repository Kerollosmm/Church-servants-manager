// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AnalyticsSummaryModel _$AnalyticsSummaryModelFromJson(
    Map<String, dynamic> json) {
  return _AnalyticsSummaryModel.fromJson(json);
}

/// @nodoc
mixin _$AnalyticsSummaryModel {
  /// Sector document ID.
  @HiveField(0)
  String get sectorId => throw _privateConstructorUsedError;

  /// Total students enrolled in this sector.
  @HiveField(1)
  int get totalStudentsCount => throw _privateConstructorUsedError;

  /// Average attendance rate (0.0 – 1.0).
  @HiveField(2)
  double get averageAttendanceRate => throw _privateConstructorUsedError;

  /// Number of pending pastoral visitations.
  @HiveField(3)
  int get pendingVisitationsCount => throw _privateConstructorUsedError;

  /// Top active servants as `{servantName: sessionCount}`.
  ///
  /// Stored as `Map<String, dynamic>` for Hive / JSON compatibility.
  /// Use [topActiveServantsTyped] for a typed `Map<String, int>` view.
  @HiveField(4)
  Map<String, dynamic> get topActiveServants =>
      throw _privateConstructorUsedError;

  /// When these stats were last computed server-side.
  @HiveField(5)
  @_TimestampConverter()
  DateTime get lastComputedAt => throw _privateConstructorUsedError;

  /// Client-side timestamp for cooldown enforcement (not in Firestore doc).
  @HiveField(6)
  @_TimestampConverter()
  DateTime get fetchedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnalyticsSummaryModelCopyWith<AnalyticsSummaryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsSummaryModelCopyWith<$Res> {
  factory $AnalyticsSummaryModelCopyWith(AnalyticsSummaryModel value,
          $Res Function(AnalyticsSummaryModel) then) =
      _$AnalyticsSummaryModelCopyWithImpl<$Res, AnalyticsSummaryModel>;
  @useResult
  $Res call(
      {@HiveField(0) String sectorId,
      @HiveField(1) int totalStudentsCount,
      @HiveField(2) double averageAttendanceRate,
      @HiveField(3) int pendingVisitationsCount,
      @HiveField(4) Map<String, dynamic> topActiveServants,
      @HiveField(5) @_TimestampConverter() DateTime lastComputedAt,
      @HiveField(6) @_TimestampConverter() DateTime fetchedAt});
}

/// @nodoc
class _$AnalyticsSummaryModelCopyWithImpl<$Res,
        $Val extends AnalyticsSummaryModel>
    implements $AnalyticsSummaryModelCopyWith<$Res> {
  _$AnalyticsSummaryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectorId = null,
    Object? totalStudentsCount = null,
    Object? averageAttendanceRate = null,
    Object? pendingVisitationsCount = null,
    Object? topActiveServants = null,
    Object? lastComputedAt = null,
    Object? fetchedAt = null,
  }) {
    return _then(_value.copyWith(
      sectorId: null == sectorId
          ? _value.sectorId
          : sectorId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudentsCount: null == totalStudentsCount
          ? _value.totalStudentsCount
          : totalStudentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      averageAttendanceRate: null == averageAttendanceRate
          ? _value.averageAttendanceRate
          : averageAttendanceRate // ignore: cast_nullable_to_non_nullable
              as double,
      pendingVisitationsCount: null == pendingVisitationsCount
          ? _value.pendingVisitationsCount
          : pendingVisitationsCount // ignore: cast_nullable_to_non_nullable
              as int,
      topActiveServants: null == topActiveServants
          ? _value.topActiveServants
          : topActiveServants // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      lastComputedAt: null == lastComputedAt
          ? _value.lastComputedAt
          : lastComputedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fetchedAt: null == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnalyticsSummaryModelImplCopyWith<$Res>
    implements $AnalyticsSummaryModelCopyWith<$Res> {
  factory _$$AnalyticsSummaryModelImplCopyWith(
          _$AnalyticsSummaryModelImpl value,
          $Res Function(_$AnalyticsSummaryModelImpl) then) =
      __$$AnalyticsSummaryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String sectorId,
      @HiveField(1) int totalStudentsCount,
      @HiveField(2) double averageAttendanceRate,
      @HiveField(3) int pendingVisitationsCount,
      @HiveField(4) Map<String, dynamic> topActiveServants,
      @HiveField(5) @_TimestampConverter() DateTime lastComputedAt,
      @HiveField(6) @_TimestampConverter() DateTime fetchedAt});
}

/// @nodoc
class __$$AnalyticsSummaryModelImplCopyWithImpl<$Res>
    extends _$AnalyticsSummaryModelCopyWithImpl<$Res,
        _$AnalyticsSummaryModelImpl>
    implements _$$AnalyticsSummaryModelImplCopyWith<$Res> {
  __$$AnalyticsSummaryModelImplCopyWithImpl(_$AnalyticsSummaryModelImpl _value,
      $Res Function(_$AnalyticsSummaryModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectorId = null,
    Object? totalStudentsCount = null,
    Object? averageAttendanceRate = null,
    Object? pendingVisitationsCount = null,
    Object? topActiveServants = null,
    Object? lastComputedAt = null,
    Object? fetchedAt = null,
  }) {
    return _then(_$AnalyticsSummaryModelImpl(
      sectorId: null == sectorId
          ? _value.sectorId
          : sectorId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStudentsCount: null == totalStudentsCount
          ? _value.totalStudentsCount
          : totalStudentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      averageAttendanceRate: null == averageAttendanceRate
          ? _value.averageAttendanceRate
          : averageAttendanceRate // ignore: cast_nullable_to_non_nullable
              as double,
      pendingVisitationsCount: null == pendingVisitationsCount
          ? _value.pendingVisitationsCount
          : pendingVisitationsCount // ignore: cast_nullable_to_non_nullable
              as int,
      topActiveServants: null == topActiveServants
          ? _value._topActiveServants
          : topActiveServants // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      lastComputedAt: null == lastComputedAt
          ? _value.lastComputedAt
          : lastComputedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fetchedAt: null == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalyticsSummaryModelImpl extends _AnalyticsSummaryModel {
  const _$AnalyticsSummaryModelImpl(
      {@HiveField(0) required this.sectorId,
      @HiveField(1) this.totalStudentsCount = 0,
      @HiveField(2) this.averageAttendanceRate = 0.0,
      @HiveField(3) this.pendingVisitationsCount = 0,
      @HiveField(4) final Map<String, dynamic> topActiveServants = const {},
      @HiveField(5) @_TimestampConverter() required this.lastComputedAt,
      @HiveField(6) @_TimestampConverter() required this.fetchedAt})
      : _topActiveServants = topActiveServants,
        super._();

  factory _$AnalyticsSummaryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalyticsSummaryModelImplFromJson(json);

  /// Sector document ID.
  @override
  @HiveField(0)
  final String sectorId;

  /// Total students enrolled in this sector.
  @override
  @JsonKey()
  @HiveField(1)
  final int totalStudentsCount;

  /// Average attendance rate (0.0 – 1.0).
  @override
  @JsonKey()
  @HiveField(2)
  final double averageAttendanceRate;

  /// Number of pending pastoral visitations.
  @override
  @JsonKey()
  @HiveField(3)
  final int pendingVisitationsCount;

  /// Top active servants as `{servantName: sessionCount}`.
  ///
  /// Stored as `Map<String, dynamic>` for Hive / JSON compatibility.
  /// Use [topActiveServantsTyped] for a typed `Map<String, int>` view.
  final Map<String, dynamic> _topActiveServants;

  /// Top active servants as `{servantName: sessionCount}`.
  ///
  /// Stored as `Map<String, dynamic>` for Hive / JSON compatibility.
  /// Use [topActiveServantsTyped] for a typed `Map<String, int>` view.
  @override
  @JsonKey()
  @HiveField(4)
  Map<String, dynamic> get topActiveServants {
    if (_topActiveServants is EqualUnmodifiableMapView)
      return _topActiveServants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_topActiveServants);
  }

  /// When these stats were last computed server-side.
  @override
  @HiveField(5)
  @_TimestampConverter()
  final DateTime lastComputedAt;

  /// Client-side timestamp for cooldown enforcement (not in Firestore doc).
  @override
  @HiveField(6)
  @_TimestampConverter()
  final DateTime fetchedAt;

  @override
  String toString() {
    return 'AnalyticsSummaryModel(sectorId: $sectorId, totalStudentsCount: $totalStudentsCount, averageAttendanceRate: $averageAttendanceRate, pendingVisitationsCount: $pendingVisitationsCount, topActiveServants: $topActiveServants, lastComputedAt: $lastComputedAt, fetchedAt: $fetchedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsSummaryModelImpl &&
            (identical(other.sectorId, sectorId) ||
                other.sectorId == sectorId) &&
            (identical(other.totalStudentsCount, totalStudentsCount) ||
                other.totalStudentsCount == totalStudentsCount) &&
            (identical(other.averageAttendanceRate, averageAttendanceRate) ||
                other.averageAttendanceRate == averageAttendanceRate) &&
            (identical(
                    other.pendingVisitationsCount, pendingVisitationsCount) ||
                other.pendingVisitationsCount == pendingVisitationsCount) &&
            const DeepCollectionEquality()
                .equals(other._topActiveServants, _topActiveServants) &&
            (identical(other.lastComputedAt, lastComputedAt) ||
                other.lastComputedAt == lastComputedAt) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sectorId,
      totalStudentsCount,
      averageAttendanceRate,
      pendingVisitationsCount,
      const DeepCollectionEquality().hash(_topActiveServants),
      lastComputedAt,
      fetchedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsSummaryModelImplCopyWith<_$AnalyticsSummaryModelImpl>
      get copyWith => __$$AnalyticsSummaryModelImplCopyWithImpl<
          _$AnalyticsSummaryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalyticsSummaryModelImplToJson(
      this,
    );
  }
}

abstract class _AnalyticsSummaryModel extends AnalyticsSummaryModel {
  const factory _AnalyticsSummaryModel(
      {@HiveField(0) required final String sectorId,
      @HiveField(1) final int totalStudentsCount,
      @HiveField(2) final double averageAttendanceRate,
      @HiveField(3) final int pendingVisitationsCount,
      @HiveField(4) final Map<String, dynamic> topActiveServants,
      @HiveField(5)
      @_TimestampConverter()
      required final DateTime lastComputedAt,
      @HiveField(6)
      @_TimestampConverter()
      required final DateTime fetchedAt}) = _$AnalyticsSummaryModelImpl;
  const _AnalyticsSummaryModel._() : super._();

  factory _AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) =
      _$AnalyticsSummaryModelImpl.fromJson;

  @override

  /// Sector document ID.
  @HiveField(0)
  String get sectorId;
  @override

  /// Total students enrolled in this sector.
  @HiveField(1)
  int get totalStudentsCount;
  @override

  /// Average attendance rate (0.0 – 1.0).
  @HiveField(2)
  double get averageAttendanceRate;
  @override

  /// Number of pending pastoral visitations.
  @HiveField(3)
  int get pendingVisitationsCount;
  @override

  /// Top active servants as `{servantName: sessionCount}`.
  ///
  /// Stored as `Map<String, dynamic>` for Hive / JSON compatibility.
  /// Use [topActiveServantsTyped] for a typed `Map<String, int>` view.
  @HiveField(4)
  Map<String, dynamic> get topActiveServants;
  @override

  /// When these stats were last computed server-side.
  @HiveField(5)
  @_TimestampConverter()
  DateTime get lastComputedAt;
  @override

  /// Client-side timestamp for cooldown enforcement (not in Firestore doc).
  @HiveField(6)
  @_TimestampConverter()
  DateTime get fetchedAt;
  @override
  @JsonKey(ignore: true)
  _$$AnalyticsSummaryModelImplCopyWith<_$AnalyticsSummaryModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
