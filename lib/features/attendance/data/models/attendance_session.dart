import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_session.freezed.dart';
part 'attendance_session.g.dart';

typedef _RequiredTimestampConverter = RequiredFirestoreTimestampConverter;

// ignore_for_file: invalid_annotation_target

@freezed
class AttendanceSession with _$AttendanceSession {
  const AttendanceSession._();

  const factory AttendanceSession({
    required String id,
    required String teamId,
    String? teamNameSnapshot,
    String? title,
    required String dateKey,
    @_RequiredTimestampConverter() required DateTime startsAt,
    @_RequiredTimestampConverter() required DateTime endsAt,
    required int durationMinutes,
    required String createdByUserId,
    required String createdByName,
    @_RequiredTimestampConverter() required DateTime createdAt,
    @_RequiredTimestampConverter() required DateTime updatedAt,
    @Default(false) bool isClosed,
    @Default(<String>[]) List<String> studentIdsSnapshot,
    @Default(<String, String>{}) Map<String, String> studentNameSnapshots,
    @Default(0) int presentCount,
    @Default(0) int lateCount,
    @Default(0) int absentCount,
  }) = _AttendanceSession;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSessionFromJson(json);

  factory AttendanceSession.fromMap(Map<String, dynamic> data, String docId) {
    String? readString(String key) {
      final value = data[key];
      if (value == null) return null;
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    int readInt(String key, {int fallback = 0}) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? fallback;
      return fallback;
    }

    bool readBool(String key, {bool fallback = false}) {
      final value = data[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return fallback;
    }

    List<String> readStringList(String key) {
      final value = data[key];
      if (value is! Iterable) return const <String>[];
      final ids = <String>[];
      for (final item in value) {
        final normalized = item?.toString().trim() ?? '';
        if (normalized.isEmpty || ids.contains(normalized)) continue;
        ids.add(normalized);
      }
      return ids;
    }

    Map<String, String> readStringMap(String key) {
      final value = data[key];
      if (value is! Map) return const <String, String>{};
      final normalized = <String, String>{};
      value.forEach((mapKey, mapValue) {
        final normalizedKey = mapKey?.toString().trim() ?? '';
        final normalizedValue = mapValue?.toString().trim() ?? '';
        if (normalizedKey.isEmpty || normalizedValue.isEmpty) return;
        normalized[normalizedKey] = normalizedValue;
      });
      return normalized;
    }

    final converter = const FirestoreTimestampConverter();
    final startsAt =
        converter.fromJson(data['startsAt']) ??
        converter.fromJson(data['createdAt']) ??
        DateTime.now();
    final durationMinutes = readInt('durationMinutes', fallback: 30);
    final endsAt =
        converter.fromJson(data['endsAt']) ??
        startsAt.add(Duration(minutes: durationMinutes));

    return AttendanceSession.fromJson({
      ...data,
      'id': readString('id') ?? docId,
      'teamId': readString('teamId') ?? '',
      'teamNameSnapshot': readString('teamNameSnapshot'),
      'title': readString('title'),
      'dateKey': readString('dateKey') ?? buildDateKey(startsAt),
      'startsAt': startsAt,
      'endsAt': endsAt,
      'durationMinutes': durationMinutes <= 0 ? 30 : durationMinutes,
      'createdByUserId': readString('createdByUserId') ?? '',
      'createdByName': readString('createdByName') ?? '',
      'createdAt': converter.fromJson(data['createdAt']) ?? startsAt,
      'updatedAt': converter.fromJson(data['updatedAt']) ?? startsAt,
      'isClosed': readBool('isClosed'),
      'studentIdsSnapshot': readStringList('studentIdsSnapshot'),
      'studentNameSnapshots': readStringMap('studentNameSnapshots'),
      'presentCount': readInt('presentCount'),
      'lateCount': readInt('lateCount'),
      'absentCount': readInt('absentCount'),
    });
  }

  bool isOpenAt(DateTime now) {
    return !isClosed && !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  bool isEffectivelyClosedAt(DateTime now) {
    return isClosed || !now.isBefore(endsAt);
  }

  static String buildDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
