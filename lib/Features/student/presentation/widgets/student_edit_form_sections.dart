import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_cubit.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_academic_form.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_contact_form.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_personal_form.dart';
import 'package:flutter/material.dart';

class StudentEditFormSections extends StatelessWidget {
  const StudentEditFormSections({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.motherPhoneController,
    required this.fatherPhoneController,
    required this.schoolController,
    required this.addressController,
    required this.fatherOfConfessionController,
    required this.notesController,
    required this.imageUrlController,
    required this.actorRole,
    required this.isEditing,
    required this.selectedRole,
    required this.group,
    required this.educationStage,
    required this.grade,
    required this.birthdate,
    required this.teamsState,
    required this.actorGroupLabel,
    required this.onRoleChanged,
    required this.onGroupChanged,
    required this.onTeamChanged,
    required this.onEducationStageChanged,
    required this.onGradeChanged,
    required this.onPickBirthdate,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController motherPhoneController;
  final TextEditingController fatherPhoneController;
  final TextEditingController schoolController;
  final TextEditingController addressController;
  final TextEditingController fatherOfConfessionController;
  final TextEditingController notesController;
  final TextEditingController imageUrlController;
  final UserRole actorRole;
  final bool isEditing;
  final UserRole selectedRole;
  final Group group;
  final EducationStage educationStage;
  final int grade;
  final DateTime? birthdate;
  final StudentFormTeamsState teamsState;
  final String actorGroupLabel;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<Group> onGroupChanged;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<EducationStage> onEducationStageChanged;
  final ValueChanged<int> onGradeChanged;
  final VoidCallback onPickBirthdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentPersonalForm(
          nameController: nameController,
          mobileController: mobileController,
          emailController: emailController,
          passwordController: passwordController,
          actorRole: actorRole,
          isEditing: isEditing,
          selectedRole: selectedRole,
          onRoleChanged: onRoleChanged,
        ),
        AppSpacing.gapMd,
        StudentAcademicForm(
          actorRole: actorRole,
          group: group,
          educationStage: educationStage,
          grade: grade,
          teamsState: teamsState,
          onGroupChanged: onGroupChanged,
          onTeamChanged: onTeamChanged,
          onEducationStageChanged: onEducationStageChanged,
          onGradeChanged: onGradeChanged,
        ),
        AppSpacing.gapMd,
        StudentContactForm(
          motherPhoneController: motherPhoneController,
          fatherPhoneController: fatherPhoneController,
          fatherOfConfessionController: fatherOfConfessionController,
          schoolController: schoolController,
          addressController: addressController,
          notesController: notesController,
          imageUrlController: imageUrlController,
          birthdate: birthdate,
          // In this domain, UserRole.servant corresponds to a "teacher" role
          // in the StudentContactForm context (isTeacher flag).
          isTeacher: actorRole == UserRole.servant,
          actorGroupLabel: actorGroupLabel,
          onPickBirthdate: onPickBirthdate,
        ),
      ],
    );
  }
}
