import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'analytics_summary_model.freezed.dart';
part 'analytics_summary_model.g.dart';

typedef _TimestampConverter = RequiredFirestoreTimestampConverter;

/// Pre-aggregated analytics for a single sector.
///
/// Stored at: /SectorsAnalytics/{sectorId}
///
/// The [fetchedAt] field is client-only — it tracks when this snapshot was
/// last pulled from Firestore so the repository can enforce a 1-hour cooldown
/// before making another read.
@freezed
@HiveType(typeId: 40)
class AnalyticsSummaryModel with _$AnalyticsSummaryModel {
  const AnalyticsSummaryModel._();

  const factory AnalyticsSummaryModel({
    /// Sector document ID.
    @HiveField(0) required String sectorId,

    /// Total students enrolled in this sector.
    @HiveField(1) @Default(0) int totalStudentsCount,

    /// Average attendance rate (0.0 – 1.0).
    @HiveField(2) @Default(0.0) double averageAttendanceRate,

    /// Number of pending pastoral visitations.
    @HiveField(3) @Default(0) int pendingVisitationsCount,

    /// Top active servants as `{servantName: sessionCount}`.
    ///
    /// Stored as `Map<String, dynamic>` for Hive / JSON compatibility.
    /// Use [topActiveServantsTyped] for a typed `Map<String, int>` view.
    @HiveField(4) @Default({}) Map<String, dynamic> topActiveServants,

    /// When these stats were last computed server-side.
    @HiveField(5) @_TimestampConverter() required DateTime lastComputedAt,

    /// Client-side timestamp for cooldown enforcement (not in Firestore doc).
    @HiveField(6) @_TimestampConverter() required DateTime fetchedAt,
  }) = _AnalyticsSummaryModel;

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSummaryModelFromJson(json);

  /// Creates an instance from a Firestore document.
  factory AnalyticsSummaryModel.fromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AnalyticsSummaryModel.fromJson({
      ...data,
      'sectorId': docId,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Serializes to a Firestore-compatible map (excludes client-only [fetchedAt]).
  Map<String, dynamic> toMap() {
    final json = toJson();
    json.remove('fetchedAt');
    return json;
  }

  /// Typed view of [topActiveServants] — values cast to `int`.
  Map<String, int> get topActiveServantsTyped {
    return topActiveServants.map(
      (key, value) => MapEntry(key, value is int ? value : 0),
    );
  }
}
