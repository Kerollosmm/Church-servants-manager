import 'package:church_management_system/core/constants/enums.dart';

class Student {
  final String uid;
  final String docID;
  final String name;
  final String? imageUrl;
  final UserRole role;
  final String mobile;
  final Group group;
  final String teamName;
  final String motherPhone;
  final String fatherPhone;
  final int grade;
  final EducationStage educationStage;
  final String? school;
  final String? address;
  final DateTime? birthdate;
  final String fatherOfConfession;
  final String? notes;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedByUserId;
  final String? archiveReason;
  final DateTime? restoredAt;
  final String? restoredByUserId;
  final String? classId;
  final Map<String, dynamic>? attendanceSummary;
  final SyncStatus syncStatus;
  final DateTime? clientUpdatedAt;
  final String? sectorId;
  final bool needsVisitation;
  final DateTime? lastAbsentDate;

  const Student({
    required this.uid,
    required this.docID,
    required this.name,
    this.imageUrl,
    required this.role,
    required this.mobile,
    required this.group,
    required this.teamName,
    required this.motherPhone,
    required this.fatherPhone,
    required this.grade,
    required this.educationStage,
    this.school,
    this.address,
    this.birthdate,
    required this.fatherOfConfession,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.archivedByUserId,
    this.archiveReason,
    this.restoredAt,
    this.restoredByUserId,
    this.classId,
    this.attendanceSummary,
    this.syncStatus = SyncStatus.synced,
    this.clientUpdatedAt,
    this.sectorId,
    this.needsVisitation = false,
    this.lastAbsentDate,
  });

  bool get isActive => !isArchived;

  bool get isOverdueForVisitation {
    if (!needsVisitation) return false;
    if (lastAbsentDate == null) return false;
    return DateTime.now().difference(lastAbsentDate!).inDays > 7;
  }

  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
        mobile.trim().isNotEmpty &&
        motherPhone.trim().isNotEmpty &&
        fatherPhone.trim().isNotEmpty &&
        fatherOfConfession.trim().isNotEmpty &&
        (classId?.trim().isNotEmpty ?? false);
  }

  Student copyWith({
    String? uid,
    String? docID,
    String? name,
    String? imageUrl,
    UserRole? role,
    String? mobile,
    Group? group,
    String? teamName,
    String? motherPhone,
    String? fatherPhone,
    int? grade,
    EducationStage? educationStage,
    String? school,
    String? address,
    DateTime? birthdate,
    String? fatherOfConfession,
    String? notes,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedByUserId,
    String? archiveReason,
    DateTime? restoredAt,
    String? restoredByUserId,
    String? classId,
    Map<String, dynamic>? attendanceSummary,
    SyncStatus? syncStatus,
    DateTime? clientUpdatedAt,
    String? sectorId,
    bool? needsVisitation,
    DateTime? lastAbsentDate,
  }) {
    return Student(
      uid: uid ?? this.uid,
      docID: docID ?? this.docID,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      role: role ?? this.role,
      mobile: mobile ?? this.mobile,
      group: group ?? this.group,
      teamName: teamName ?? this.teamName,
      motherPhone: motherPhone ?? this.motherPhone,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      grade: grade ?? this.grade,
      educationStage: educationStage ?? this.educationStage,
      school: school ?? this.school,
      address: address ?? this.address,
      birthdate: birthdate ?? this.birthdate,
      fatherOfConfession: fatherOfConfession ?? this.fatherOfConfession,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedByUserId: archivedByUserId ?? this.archivedByUserId,
      archiveReason: archiveReason ?? this.archiveReason,
      restoredAt: restoredAt ?? this.restoredAt,
      restoredByUserId: restoredByUserId ?? this.restoredByUserId,
      classId: classId ?? this.classId,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      syncStatus: syncStatus ?? this.syncStatus,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      sectorId: sectorId ?? this.sectorId,
      needsVisitation: needsVisitation ?? this.needsVisitation,
      lastAbsentDate: lastAbsentDate ?? this.lastAbsentDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          docID == other.docID &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          role == other.role &&
          mobile == other.mobile &&
          group == other.group &&
          teamName == other.teamName &&
          motherPhone == other.motherPhone &&
          fatherPhone == other.fatherPhone &&
          grade == other.grade &&
          educationStage == other.educationStage &&
          school == other.school &&
          address == other.address &&
          birthdate == other.birthdate &&
          fatherOfConfession == other.fatherOfConfession &&
          notes == other.notes &&
          isArchived == other.isArchived &&
          archivedAt == other.archivedAt &&
          archivedByUserId == other.archivedByUserId &&
          archiveReason == other.archiveReason &&
          restoredAt == other.restoredAt &&
          restoredByUserId == other.restoredByUserId &&
          classId == other.classId &&
          syncStatus == other.syncStatus &&
          clientUpdatedAt == other.clientUpdatedAt &&
          sectorId == other.sectorId &&
          needsVisitation == other.needsVisitation &&
          lastAbsentDate == other.lastAbsentDate;

  @override
  int get hashCode =>
      uid.hashCode ^
      docID.hashCode ^
      name.hashCode ^
      imageUrl.hashCode ^
      role.hashCode ^
      mobile.hashCode ^
      group.hashCode ^
      teamName.hashCode ^
      motherPhone.hashCode ^
      fatherPhone.hashCode ^
      grade.hashCode ^
      educationStage.hashCode ^
      school.hashCode ^
      address.hashCode ^
      birthdate.hashCode ^
      fatherOfConfession.hashCode ^
      notes.hashCode ^
      isArchived.hashCode ^
      archivedAt.hashCode ^
      archivedByUserId.hashCode ^
      archiveReason.hashCode ^
      restoredAt.hashCode ^
      restoredByUserId.hashCode ^
      classId.hashCode ^
      syncStatus.hashCode ^
      clientUpdatedAt.hashCode ^
      sectorId.hashCode ^
      needsVisitation.hashCode ^
      lastAbsentDate.hashCode;
}
