import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'points_ledger_entry.freezed.dart';
part 'points_ledger_entry.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

/// A single transaction in a student's points ledger.
///
/// Stored at: /Students/{studentId}/PointsLedger/{transactionId}
///
/// Rules:
/// - Immutable after creation (delete/update only via Admin SDK).
/// - [delta] is positive for rewards, negative for deductions.
/// - [runningTotal] is denormalised to avoid expensive aggregation queries.
@freezed
@HiveType(typeId: 30)
class PointsLedgerEntry with _$PointsLedgerEntry {
  const PointsLedgerEntry._();

  const factory PointsLedgerEntry({
    /// Firestore document ID (auto-generated transaction ID).
    @HiveField(0) required String id,

    /// Student document ID (parent document).
    @HiveField(1) required String studentId,

    /// Points change: positive = reward, negative = deduction.
    @HiveField(2) required int delta,

    /// Running total after this transaction (denormalised for cheap reads).
    @HiveField(3) required int runningTotal,

    /// Human-readable reason (e.g. 'Perfect attendance – Week 12').
    @HiveField(4) required String reason,

    /// UID of the servant/admin who recorded this entry.
    @HiveField(5) required String issuedByUid,

    /// Display name of the issuer (snapshot, not a live reference).
    @HiveField(6) required String issuedByName,

    /// When this entry was created on the client.
    @HiveField(7) @_TimestampConverter() required DateTime createdAt,

    /// Sync state – pending until written to Firestore.
    @HiveField(8) @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _PointsLedgerEntry;

  factory PointsLedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$PointsLedgerEntryFromJson(json);

  factory PointsLedgerEntry.fromMap(Map<String, dynamic> data, String docId) {
    return PointsLedgerEntry.fromJson({
      ...data,
      'id': data['id'] as String? ?? docId,
      'studentId': data['studentId'] as String? ?? '',
      'delta': (data['delta'] as num?)?.toInt() ?? 0,
      'runningTotal': (data['runningTotal'] as num?)?.toInt() ?? 0,
      'reason': data['reason'] as String? ?? '',
      'issuedByUid': data['issuedByUid'] as String? ?? '',
      'issuedByName': data['issuedByName'] as String? ?? '',
      'syncStatus': data['syncStatus'] as String? ?? 'pending',
    });
  }

  Map<String, dynamic> toMap() => toJson();

  bool get isReward => delta > 0;
}
