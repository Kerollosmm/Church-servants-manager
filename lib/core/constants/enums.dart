import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 11)
enum UserRole {
  @HiveField(0)
  servant,
  @HiveField(1)
  student,
  @HiveField(2)
  admin,
}

@HiveType(typeId: 12)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
  @HiveField(2)
  late,
}

@HiveType(typeId: 13)
enum EducationStage {
  @HiveField(0)
  preparatory,
  @HiveField(1)
  highSchool,
  @HiveField(2)
  college,
}

@HiveType(typeId: 14)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  synced,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 15)
enum Group {
  @HiveField(0)
  year1,
  @HiveField(1)
  year2,
  @HiveField(2)
  year3,
}

extension GroupDisplayName on Group {
  String get displayName {
    switch (this) {
      case Group.year1:
        return 'السنة الأولى';
      case Group.year2:
        return 'السنة الثانية';
      case Group.year3:
        return 'السنة الثالثة';
    }
  }
}

extension EducationStageDisplayName on EducationStage {
  String get displayName {
    switch (this) {
      case EducationStage.preparatory:
        return 'إعدادي';
      case EducationStage.highSchool:
        return 'ثانوي';
      case EducationStage.college:
        return 'جامعة';
    }
  }
}

@HiveType(typeId: 16)
enum VisitationType {
  @HiveField(0)
  phoneCall,
  @HiveField(1)
  homeVisit,
  @HiveField(2)
  socialMedia,
}

extension VisitationTypeDisplayName on VisitationType {
  String get displayName {
    switch (this) {
      case VisitationType.phoneCall:
        return 'مكالمة هاتفية';
      case VisitationType.homeVisit:
        return 'زيارة منزلية';
      case VisitationType.socialMedia:
        return 'وسائل التواصل الاجتماعي';
    }
  }
}
