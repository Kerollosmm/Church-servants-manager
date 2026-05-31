// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'points_ledger_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PointsLedgerEntry _$PointsLedgerEntryFromJson(Map<String, dynamic> json) {
  return _PointsLedgerEntry.fromJson(json);
}

/// @nodoc
mixin _$PointsLedgerEntry {
  /// Firestore document ID (auto-generated transaction ID).
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;

  /// Student document ID (parent document).
  @HiveField(1)
  String get studentId => throw _privateConstructorUsedError;

  /// Points change: positive = reward, negative = deduction.
  @HiveField(2)
  int get delta => throw _privateConstructorUsedError;

  /// Running total after this transaction (denormalised for cheap reads).
  @HiveField(3)
  int get runningTotal => throw _privateConstructorUsedError;

  /// Human-readable reason (e.g. 'Perfect attendance – Week 12').
  @HiveField(4)
  String get reason => throw _privateConstructorUsedError;

  /// UID of the servant/admin who recorded this entry.
  @HiveField(5)
  String get issuedByUid => throw _privateConstructorUsedError;

  /// Display name of the issuer (snapshot, not a live reference).
  @HiveField(6)
  String get issuedByName => throw _privateConstructorUsedError;

  /// When this entry was created on the client.
  @HiveField(7)
  @_TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Sync state – pending until written to Firestore.
  @HiveField(8)
  SyncStatus get syncStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PointsLedgerEntryCopyWith<PointsLedgerEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsLedgerEntryCopyWith<$Res> {
  factory $PointsLedgerEntryCopyWith(
    PointsLedgerEntry value,
    $Res Function(PointsLedgerEntry) then,
  ) = _$PointsLedgerEntryCopyWithImpl<$Res, PointsLedgerEntry>;
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String studentId,
    @HiveField(2) int delta,
    @HiveField(3) int runningTotal,
    @HiveField(4) String reason,
    @HiveField(5) String issuedByUid,
    @HiveField(6) String issuedByName,
    @HiveField(7) @_TimestampConverter() DateTime createdAt,
    @HiveField(8) SyncStatus syncStatus,
  });
}

/// @nodoc
class _$PointsLedgerEntryCopyWithImpl<$Res, $Val extends PointsLedgerEntry>
    implements $PointsLedgerEntryCopyWith<$Res> {
  _$PointsLedgerEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = null,
    Object? delta = null,
    Object? runningTotal = null,
    Object? reason = null,
    Object? issuedByUid = null,
    Object? issuedByName = null,
    Object? createdAt = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            studentId: null == studentId
                ? _value.studentId
                : studentId // ignore: cast_nullable_to_non_nullable
                      as String,
            delta: null == delta
                ? _value.delta
                : delta // ignore: cast_nullable_to_non_nullable
                      as int,
            runningTotal: null == runningTotal
                ? _value.runningTotal
                : runningTotal // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedByUid: null == issuedByUid
                ? _value.issuedByUid
                : issuedByUid // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedByName: null == issuedByName
                ? _value.issuedByName
                : issuedByName // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PointsLedgerEntryImplCopyWith<$Res>
    implements $PointsLedgerEntryCopyWith<$Res> {
  factory _$$PointsLedgerEntryImplCopyWith(
    _$PointsLedgerEntryImpl value,
    $Res Function(_$PointsLedgerEntryImpl) then,
  ) = __$$PointsLedgerEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @HiveField(0) String id,
    @HiveField(1) String studentId,
    @HiveField(2) int delta,
    @HiveField(3) int runningTotal,
    @HiveField(4) String reason,
    @HiveField(5) String issuedByUid,
    @HiveField(6) String issuedByName,
    @HiveField(7) @_TimestampConverter() DateTime createdAt,
    @HiveField(8) SyncStatus syncStatus,
  });
}

/// @nodoc
class __$$PointsLedgerEntryImplCopyWithImpl<$Res>
    extends _$PointsLedgerEntryCopyWithImpl<$Res, _$PointsLedgerEntryImpl>
    implements _$$PointsLedgerEntryImplCopyWith<$Res> {
  __$$PointsLedgerEntryImplCopyWithImpl(
    _$PointsLedgerEntryImpl _value,
    $Res Function(_$PointsLedgerEntryImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = null,
    Object? delta = null,
    Object? runningTotal = null,
    Object? reason = null,
    Object? issuedByUid = null,
    Object? issuedByName = null,
    Object? createdAt = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _$PointsLedgerEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        studentId: null == studentId
            ? _value.studentId
            : studentId // ignore: cast_nullable_to_non_nullable
                  as String,
        delta: null == delta
            ? _value.delta
            : delta // ignore: cast_nullable_to_non_nullable
                  as int,
        runningTotal: null == runningTotal
            ? _value.runningTotal
            : runningTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedByUid: null == issuedByUid
            ? _value.issuedByUid
            : issuedByUid // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedByName: null == issuedByName
            ? _value.issuedByName
            : issuedByName // ignore: cast_nullable_to_non_nullable
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
class _$PointsLedgerEntryImpl extends _PointsLedgerEntry {
  const _$PointsLedgerEntryImpl({
    @HiveField(0) required this.id,
    @HiveField(1) required this.studentId,
    @HiveField(2) required this.delta,
    @HiveField(3) required this.runningTotal,
    @HiveField(4) required this.reason,
    @HiveField(5) required this.issuedByUid,
    @HiveField(6) required this.issuedByName,
    @HiveField(7) @_TimestampConverter() required this.createdAt,
    @HiveField(8) this.syncStatus = SyncStatus.pending,
  }) : super._();

  factory _$PointsLedgerEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsLedgerEntryImplFromJson(json);

  /// Firestore document ID (auto-generated transaction ID).
  @override
  @HiveField(0)
  final String id;

  /// Student document ID (parent document).
  @override
  @HiveField(1)
  final String studentId;

  /// Points change: positive = reward, negative = deduction.
  @override
  @HiveField(2)
  final int delta;

  /// Running total after this transaction (denormalised for cheap reads).
  @override
  @HiveField(3)
  final int runningTotal;

  /// Human-readable reason (e.g. 'Perfect attendance – Week 12').
  @override
  @HiveField(4)
  final String reason;

  /// UID of the servant/admin who recorded this entry.
  @override
  @HiveField(5)
  final String issuedByUid;

  /// Display name of the issuer (snapshot, not a live reference).
  @override
  @HiveField(6)
  final String issuedByName;

  /// When this entry was created on the client.
  @override
  @HiveField(7)
  @_TimestampConverter()
  final DateTime createdAt;

  /// Sync state – pending until written to Firestore.
  @override
  @JsonKey()
  @HiveField(8)
  final SyncStatus syncStatus;

  @override
  String toString() {
    return 'PointsLedgerEntry(id: $id, studentId: $studentId, delta: $delta, runningTotal: $runningTotal, reason: $reason, issuedByUid: $issuedByUid, issuedByName: $issuedByName, createdAt: $createdAt, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsLedgerEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.delta, delta) || other.delta == delta) &&
            (identical(other.runningTotal, runningTotal) ||
                other.runningTotal == runningTotal) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.issuedByUid, issuedByUid) ||
                other.issuedByUid == issuedByUid) &&
            (identical(other.issuedByName, issuedByName) ||
                other.issuedByName == issuedByName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    studentId,
    delta,
    runningTotal,
    reason,
    issuedByUid,
    issuedByName,
    createdAt,
    syncStatus,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsLedgerEntryImplCopyWith<_$PointsLedgerEntryImpl> get copyWith =>
      __$$PointsLedgerEntryImplCopyWithImpl<_$PointsLedgerEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsLedgerEntryImplToJson(this);
  }
}

abstract class _PointsLedgerEntry extends PointsLedgerEntry {
  const factory _PointsLedgerEntry({
    @HiveField(0) required final String id,
    @HiveField(1) required final String studentId,
    @HiveField(2) required final int delta,
    @HiveField(3) required final int runningTotal,
    @HiveField(4) required final String reason,
    @HiveField(5) required final String issuedByUid,
    @HiveField(6) required final String issuedByName,
    @HiveField(7) @_TimestampConverter() required final DateTime createdAt,
    @HiveField(8) final SyncStatus syncStatus,
  }) = _$PointsLedgerEntryImpl;
  const _PointsLedgerEntry._() : super._();

  factory _PointsLedgerEntry.fromJson(Map<String, dynamic> json) =
      _$PointsLedgerEntryImpl.fromJson;

  @override
  /// Firestore document ID (auto-generated transaction ID).
  @HiveField(0)
  String get id;
  @override
  /// Student document ID (parent document).
  @HiveField(1)
  String get studentId;
  @override
  /// Points change: positive = reward, negative = deduction.
  @HiveField(2)
  int get delta;
  @override
  /// Running total after this transaction (denormalised for cheap reads).
  @HiveField(3)
  int get runningTotal;
  @override
  /// Human-readable reason (e.g. 'Perfect attendance – Week 12').
  @HiveField(4)
  String get reason;
  @override
  /// UID of the servant/admin who recorded this entry.
  @HiveField(5)
  String get issuedByUid;
  @override
  /// Display name of the issuer (snapshot, not a live reference).
  @HiveField(6)
  String get issuedByName;
  @override
  /// When this entry was created on the client.
  @HiveField(7)
  @_TimestampConverter()
  DateTime get createdAt;
  @override
  /// Sync state – pending until written to Firestore.
  @HiveField(8)
  SyncStatus get syncStatus;
  @override
  @JsonKey(ignore: true)
  _$$PointsLedgerEntryImplCopyWith<_$PointsLedgerEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
