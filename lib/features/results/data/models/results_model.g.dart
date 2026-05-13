// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResultsModelAdapter extends TypeAdapter<ResultsModel> {
  @override
  final int typeId = 21;

  @override
  ResultsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResultsModel(
      studentId: fields[0] as String,
      termId: fields[1] as String,
      score: fields[2] as double,
      notes: fields[3] as String?,
      groupId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResultsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.termId)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.groupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
