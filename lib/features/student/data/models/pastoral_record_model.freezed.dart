// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pastoral_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PastoralRecordModel _$PastoralRecordModelFromJson(Map<String, dynamic> json) {
  return _PastoralRecordModel.fromJson(json);
}

/// @nodoc
mixin _$PastoralRecordModel {
  /// Deterministic document ID: `{studentId}_{timestampMs}`.
  @HiveField(0)
  String get recordId => throw _privateConstructorUsedError;

  /// Student document ID (parent document).
  @HiveField(1)
  String get studentId => throw _privateConstructorUsedError;

  /// Type of visitation (phoneCall, homeVisit, socialMedia).
  @HiveField(2)
  VisitationType get type => throw _privateConstructorUsedError;

  /// Free-text summary of the pastoral visit.
  @HiveField(3)
  String get summary => throw _privateConstructorUsedError;

  /// UID of the servant/admin who made the visit.
  @HiveField(4)
  String get visitedByUid => throw _privateConstructorUsedError;

  /// Display name of the visitor (snapshot, not a live reference).
  @HiveField(5)
  String get visitedByName => throw _privateConstructorUsedError;

  /// When this record was created on the client.
  @HiveField(6)
  @_TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Sync state -- pending until written to Firestore.
  @HiveField(7)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PastoralRecordModelCopyWith<PastoralRecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PastoralRecordModelCopyWith<$Res> {
  factory $PastoralRecordModelCopyWith(
    PastoralRecordModel value,
    $Res Function(PastoralRecordModel) then,
  ) = _$PastoralRecordModelCopyWithImpl<$Res, PastoralRecordModel>;
  @useResult
  $Res call({
    @HiveField(0) String recordId,
    @HiveField(1) String studentId,
    @HiveField(2) VisitationType type,
    @HiveField(3) String summary,
    @HiveField(4) String visitedByUid,
    @HiveField(5) String visitedByName,
    @HiveField(6) @_TimestampConverter() DateTime createdAt,
    @HiveField(7) SyncStatus syncStatus,
  });
}

/// @nodoc
class _$PastoralRecordModelCopyWithImpl<$Res, $Val extends PastoralRecordModel>
    implements $PastoralRecordModelCopyWith<$Res> {
  _$PastoralRecordModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? studentId = null,
    Object? type = null,
    Object? summary = null,
    Object? visitedByUid = null,
    Object? visitedByName = null,
    Object? createdAt = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _value.copyWith(
            recordId: null == recordId
                ? _value.recordId
                : recordId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as VisitationType,
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            visitedByUid: null == visitedByUid
                ? _value.visitedByUid
                : visitedByUid // ignore: cast_nullable_to_non_nullable
                      as String,
            visitedByName: null == visitedByName
                ? _value.visitedByName
                : visitedByName // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$PastoralRecordModelImplCopyWith<$Res>
    implements $PastoralRecordModelCopyWith<$Res> {
  factory _$$PastoralRecordModelImplCopyWith(
    _$PastoralRecordModelImpl value,
    $Res Function(_$PastoralRecordModelImpl) then,
  ) = __$$PastoralRecordModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @HiveField(0) String recordId,
    @HiveField(1) String studentId,
    @HiveField(2) VisitationType type,
    @HiveField(3) String summary,
    @HiveField(4) String visitedByUid,
    @HiveField(5) String visitedByName,
    @HiveField(6) @_TimestampConverter() DateTime createdAt,
    @HiveField(7) SyncStatus syncStatus,
  });
}

/// @nodoc
class __$$PastoralRecordModelImplCopyWithImpl<$Res>
    extends _$PastoralRecordModelCopyWithImpl<$Res, _$PastoralRecordModelImpl>
    implements _$$PastoralRecordModelImplCopyWith<$Res> {
  __$$PastoralRecordModelImplCopyWithImpl(
    _$PastoralRecordModelImpl _value,
    $Res Function(_$PastoralRecordModelImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? studentId = null,
    Object? type = null,
    Object? summary = null,
    Object? visitedByUid = null,
    Object? visitedByName = null,
    Object? createdAt = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _$PastoralRecordModelImpl(
        recordId: null == recordId
            ? _value.recordId
            : recordId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as VisitationType,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        visitedByUid: null == visitedByUid
            ? _value.visitedByUid
            : visitedByUid // ignore: cast_nullable_to_non_nullable
                  as String,
        visitedByName: null == visitedByName
            ? _value.visitedByName
            : visitedByName // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
class _$PastoralRecordModelImpl extends _PastoralRecordModel {
  const _$PastoralRecordModelImpl({
    @HiveField(0) required this.recordId,
    @HiveField(1) required this.studentId,
    @HiveField(2) required this.type,
    @HiveField(3) required this.summary,
    @HiveField(4) required this.visitedByUid,
    @HiveField(5) required this.visitedByName,
    @HiveField(6) @_TimestampConverter() required this.createdAt,
    @HiveField(7) this.syncStatus = SyncStatus.pending,
  }) : super._();

  factory _$PastoralRecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PastoralRecordModelImplFromJson(json);

  /// Deterministic document ID: `{studentId}_{timestampMs}`.
  @override
  @HiveField(0)
  final String recordId;

  /// Student document ID (parent document).
  @override
  @HiveField(1)
  final String studentId;

  /// Type of visitation (phoneCall, homeVisit, socialMedia).
  @override
  @HiveField(2)
  final VisitationType type;

  /// Free-text summary of the pastoral visit.
  @override
  @HiveField(3)
  final String summary;

  /// UID of the servant/admin who made the visit.
  @override
  @HiveField(4)
  final String visitedByUid;

  /// Display name of the visitor (snapshot, not a live reference).
  @override
  @HiveField(5)
  final String visitedByName;

  /// When this record was created on the client.
  @override
  @HiveField(6)
  @_TimestampConverter()
  final DateTime createdAt;

  /// Sync state -- pending until written to Firestore.
  @override
  @JsonKey()
  @HiveField(7)
  final SyncStatus syncStatus;

  @override
  String toString() {
    return 'PastoralRecordModel(recordId: $recordId, studentId: $studentId, type: $type, summary: $summary, visitedByUid: $visitedByUid, visitedByName: $visitedByName, createdAt: $createdAt, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PastoralRecordModelImpl &&
            (identical(other.recordId, recordId) ||
                other.recordId == recordId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.visitedByUid, visitedByUid) ||
                other.visitedByUid == visitedByUid) &&
            (identical(other.visitedByName, visitedByName) ||
                other.visitedByName == visitedByName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    recordId,
    studentId,
    type,
    summary,
    visitedByUid,
    visitedByName,
    createdAt,
    syncStatus,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PastoralRecordModelImplCopyWith<_$PastoralRecordModelImpl> get copyWith =>
      __$$PastoralRecordModelImplCopyWithImpl<_$PastoralRecordModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PastoralRecordModelImplToJson(this);
  }
}

abstract class _PastoralRecordModel extends PastoralRecordModel {
  const factory _PastoralRecordModel({
    @HiveField(0) required final String recordId,
    @HiveField(1) required final String studentId,
    @HiveField(2) required final VisitationType type,
    @HiveField(3) required final String summary,
    @HiveField(4) required final String visitedByUid,
    @HiveField(5) required final String visitedByName,
    @HiveField(6) @_TimestampConverter() required final DateTime createdAt,
    @HiveField(7) final SyncStatus syncStatus,
  }) = _$PastoralRecordModelImpl;
  const _PastoralRecordModel._() : super._();

  factory _PastoralRecordModel.fromJson(Map<String, dynamic> json) =
      _$PastoralRecordModelImpl.fromJson;

  @override
  /// Deterministic document ID: `{studentId}_{timestampMs}`.
  @HiveField(0)
  String get recordId;
  @override
  /// Student document ID (parent document).
  @HiveField(1)
  String get studentId;
  @override
  /// Type of visitation (phoneCall, homeVisit, socialMedia).
  @HiveField(2)
  VisitationType get type;
  @override
  /// Free-text summary of the pastoral visit.
  @HiveField(3)
  String get summary;
  @override
  /// UID of the servant/admin who made the visit.
  @HiveField(4)
  String get visitedByUid;
  @override
  /// Display name of the visitor (snapshot, not a live reference).
  @HiveField(5)
  String get visitedByName;
  @override
  /// When this record was created on the client.
  @HiveField(6)
  @_TimestampConverter()
  DateTime get createdAt;
  @override
  /// Sync state -- pending until written to Firestore.
  @HiveField(7)
  SyncStatus get syncStatus;
  @override
  @JsonKey(ignore: true)
  _$$PastoralRecordModelImplCopyWith<_$PastoralRecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
