// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 11;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.servant;
      case 1:
        return UserRole.student;
      case 2:
        return UserRole.admin;
      default:
        return UserRole.servant;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.servant:
        writer.writeByte(0);
        break;
      case UserRole.student:
        writer.writeByte(1);
        break;
      case UserRole.admin:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 12;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.present;
      case 1:
        return AttendanceStatus.absent;
      case 2:
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(1);
        break;
      case AttendanceStatus.late:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EducationStageAdapter extends TypeAdapter<EducationStage> {
  @override
  final int typeId = 13;

  @override
  EducationStage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EducationStage.preparatory;
      case 1:
        return EducationStage.highSchool;
      case 2:
        return EducationStage.college;
      default:
        return EducationStage.preparatory;
    }
  }

  @override
  void write(BinaryWriter writer, EducationStage obj) {
    switch (obj) {
      case EducationStage.preparatory:
        writer.writeByte(0);
        break;
      case EducationStage.highSchool:
        writer.writeByte(1);
        break;
      case EducationStage.college:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 14;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.synced;
      case 2:
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        break;
      case SyncStatus.synced:
        writer.writeByte(1);
        break;
      case SyncStatus.failed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 15;

  @override
  Group read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Group.year1;
      case 1:
        return Group.year2;
      case 2:
        return Group.year3;
      default:
        return Group.year1;
    }
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    switch (obj) {
      case Group.year1:
        writer.writeByte(0);
        break;
      case Group.year2:
        writer.writeByte(1);
        break;
      case Group.year3:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VisitationTypeAdapter extends TypeAdapter<VisitationType> {
  @override
  final int typeId = 16;

  @override
  VisitationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VisitationType.phoneCall;
      case 1:
        return VisitationType.homeVisit;
      case 2:
        return VisitationType.socialMedia;
      default:
        return VisitationType.phoneCall;
    }
  }

  @override
  void write(BinaryWriter writer, VisitationType obj) {
    switch (obj) {
      case VisitationType.phoneCall:
        writer.writeByte(0);
        break;
      case VisitationType.homeVisit:
        writer.writeByte(1);
        break;
      case VisitationType.socialMedia:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
