// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsSummaryModelAdapter extends TypeAdapter<AnalyticsSummaryModel> {
  @override
  final int typeId = 40;

  @override
  AnalyticsSummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsSummaryModel(
      sectorId: fields[0] as String,
      totalStudentsCount: fields[1] as int,
      averageAttendanceRate: fields[2] as double,
      pendingVisitationsCount: fields[3] as int,
      topActiveServants: (fields[4] as Map).cast<String, int>(),
      lastComputedAt: fields[5] as DateTime,
      fetchedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsSummaryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.sectorId)
      ..writeByte(1)
      ..write(obj.totalStudentsCount)
      ..writeByte(2)
      ..write(obj.averageAttendanceRate)
      ..writeByte(3)
      ..write(obj.pendingVisitationsCount)
      ..writeByte(4)
      ..write(obj.topActiveServants)
      ..writeByte(5)
      ..write(obj.lastComputedAt)
      ..writeByte(6)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnalyticsSummaryModelImpl _$$AnalyticsSummaryModelImplFromJson(
  Map<String, dynamic> json,
) => _$AnalyticsSummaryModelImpl(
  sectorId: json['sectorId'] as String,
  totalStudentsCount: (json['totalStudentsCount'] as num?)?.toInt() ?? 0,
  averageAttendanceRate:
      (json['averageAttendanceRate'] as num?)?.toDouble() ?? 0.0,
  pendingVisitationsCount:
      (json['pendingVisitationsCount'] as num?)?.toInt() ?? 0,
  topActiveServants:
      (json['topActiveServants'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  lastComputedAt: const RequiredFirestoreTimestampConverter().fromJson(
    json['lastComputedAt'],
  ),
  fetchedAt: const RequiredFirestoreTimestampConverter().fromJson(
    json['fetchedAt'],
  ),
);

Map<String, dynamic> _$$AnalyticsSummaryModelImplToJson(
  _$AnalyticsSummaryModelImpl instance,
) => <String, dynamic>{
  'sectorId': instance.sectorId,
  'totalStudentsCount': instance.totalStudentsCount,
  'averageAttendanceRate': instance.averageAttendanceRate,
  'pendingVisitationsCount': instance.pendingVisitationsCount,
  'topActiveServants': instance.topActiveServants,
  'lastComputedAt': const RequiredFirestoreTimestampConverter().toJson(
    instance.lastComputedAt,
  ),
  'fetchedAt': const RequiredFirestoreTimestampConverter().toJson(
    instance.fetchedAt,
  ),
};
