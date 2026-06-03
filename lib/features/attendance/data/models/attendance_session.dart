import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';

part 'attendance_session.freezed.dart';
part 'attendance_session.g.dart';

typedef _RequiredTimestampConverter = RequiredFirestoreTimestampConverter;

// ignore_for_file: invalid_annotation_target

@freezed
class AttendanceSessionModel with _$AttendanceSessionModel {
  const AttendanceSessionModel._();

  const factory AttendanceSessionModel({
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
  }) = _AttendanceSessionModel;

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSessionModelFromJson(json);

  factory AttendanceSessionModel.fromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
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
        (converter.fromJson(data['startsAt']) ??
                converter.fromJson(data['createdAt']) ??
                DateTime.now())
            .toUtc();
    final durationMinutes = readInt('durationMinutes', fallback: 30);
    final endsAt =
        (converter.fromJson(data['endsAt']) ??
                startsAt.add(Duration(minutes: durationMinutes)))
            .toUtc();

    return AttendanceSessionModel.fromJson({
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

      'createdAt': ((converter.fromJson(data['createdAt']) ?? startsAt))
          .toUtc(),
      'updatedAt': ((converter.fromJson(data['updatedAt']) ?? startsAt))
          .toUtc(),
      'isClosed': readBool('isClosed'),
      'studentIdsSnapshot': readStringList('studentIdsSnapshot'),
      'studentNameSnapshots': readStringMap('studentNameSnapshots'),
      'presentCount': readInt('presentCount'),
      'lateCount': readInt('lateCount'),
      'absentCount': readInt('absentCount'),
    });
  }

  bool isOpenAt(DateTime now) {
    return !isClosed &&
        !now.toUtc().isBefore(startsAt) &&
        now.toUtc().isBefore(endsAt);
  }

  bool isEffectivelyClosedAt(DateTime now) {
    return isClosed || !now.toUtc().isBefore(endsAt);
  }

  static String buildDateKey(DateTime date) {
    return date.toUtc().toIso8601String().substring(0, 10);
  }

  Map<String, dynamic> toMap() {
    return toJson()..remove('id');
  }

  AttendanceSession toDomain() {
    return AttendanceSession(
      id: id,
      teamId: teamId,
      teamNameSnapshot: teamNameSnapshot,
      title: title,
      dateKey: dateKey,
      startsAt: startsAt,
      endsAt: endsAt,
      durationMinutes: durationMinutes,
      createdByUserId: createdByUserId,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isClosed: isClosed,
      studentIdsSnapshot: studentIdsSnapshot,
      studentNameSnapshots: studentNameSnapshots,
      presentCount: presentCount,
      lateCount: lateCount,
      absentCount: absentCount,
    );
  }

  factory AttendanceSessionModel.fromDomain(AttendanceSession session) {
    return AttendanceSessionModel(
      id: session.id,
      teamId: session.teamId,
      teamNameSnapshot: session.teamNameSnapshot,
      title: session.title,
      dateKey: session.dateKey,
      startsAt: session.startsAt,
      endsAt: session.endsAt,
      durationMinutes: session.durationMinutes,
      createdByUserId: session.createdByUserId,
      createdByName: session.createdByName,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      isClosed: session.isClosed,
      studentIdsSnapshot: session.studentIdsSnapshot,
      studentNameSnapshots: session.studentNameSnapshots,
      presentCount: session.presentCount,
      lateCount: session.lateCount,
      absentCount: session.absentCount,
    );
  }
}
