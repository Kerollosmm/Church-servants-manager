enum UserRole { servant, student, admin }

enum AttendanceStatus { present, absent, late }

enum EducationStage { preparatory, highSchool, college }

enum Group { year1, year2, year3 }

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
