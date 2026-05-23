import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'pastoral_record_model.freezed.dart';
part 'pastoral_record_model.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

/// A single pastoral care visitation record.
///
/// Stored at: /Students/{studentId}/PastoralRecords/{recordId}
///
/// Rules:
/// - Immutable after creation (delete/update only via Admin SDK).
/// - [recordId] is deterministic: `{studentId}_{timestampMs}`.
/// - [type] must be one of: phoneCall, homeVisit, socialMedia.
@freezed
@HiveType(typeId: 35)
class PastoralRecordModel with _$PastoralRecordModel {
  const PastoralRecordModel._();

  const factory PastoralRecordModel({
    /// Deterministic document ID: `{studentId}_{timestampMs}`.
    @HiveField(0) required String recordId,

    /// Student document ID (parent document).
    @HiveField(1) required String studentId,

    /// Type of visitation (phoneCall, homeVisit, socialMedia).
    @HiveField(2) required VisitationType type,

    /// Free-text summary of the pastoral visit.
    @HiveField(3) required String summary,

    /// UID of the servant/admin who made the visit.
    @HiveField(4) required String visitedByUid,

    /// Display name of the visitor (snapshot, not a live reference).
    @HiveField(5) required String visitedByName,

    /// When this record was created on the client.
    @HiveField(6) @_TimestampConverter() required DateTime createdAt,

    /// Sync state -- pending until written to Firestore.
    @HiveField(7) @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _PastoralRecordModel;

  factory PastoralRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PastoralRecordModelFromJson(json);

  factory PastoralRecordModel.fromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return PastoralRecordModel.fromJson({
      ...data,
      'recordId': data['recordId'] as String? ?? docId,
      'studentId': data['studentId'] as String? ?? '',
      'type': data['type'] as String? ?? 'phoneCall',
      'summary': data['summary'] as String? ?? '',
      'visitedByUid': data['visitedByUid'] as String? ?? '',
      'visitedByName': data['visitedByName'] as String? ?? '',
      'syncStatus': data['syncStatus'] as String? ?? 'pending',
    });
  }

  Map<String, dynamic> toMap() => toJson();

  /// Generates a deterministic record ID from studentId and timestamp.
  static String generateRecordId(String studentId, DateTime timestamp) {
    return '${studentId}_${timestamp.millisecondsSinceEpoch}';
  }
}
