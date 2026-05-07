import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/ochre_text_field.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_menu_field.dart';
import 'package:church_management_system/core/widgets/form/date_picker_field.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_cubit.dart';
import 'package:flutter/material.dart';

class StudentBasicsSection extends StatelessWidget {
  const StudentBasicsSection({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.actorRole,
    required this.isEditing,
    required this.selectedRole,
    required this.group,
    required this.educationStage,
    required this.grade,
    required this.teamsState,
    required this.onRoleChanged,
    required this.onGroupChanged,
    required this.onTeamChanged,
    required this.onEducationStageChanged,
    required this.onGradeChanged,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final UserRole actorRole;
  final bool isEditing;
  final UserRole selectedRole;
  final Group group;
  final EducationStage educationStage;
  final int grade;
  final StudentFormTeamsState teamsState;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<Group> onGroupChanged;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<EducationStage> onEducationStageChanged;
  final ValueChanged<int> onGradeChanged;

  bool get _isTeacher => actorRole == UserRole.servant;
  bool get _canEditRole => isEditing && actorRole == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات المخدوم', style: _sectionTitleStyle(theme)),
          AppSpacing.gapMd,
          OchreTextField(
            controller: nameController,
            label: 'الاسم الكامل',
            prefixIcon: Icons.person_outline,
            validator: Validators.validateNameArabic,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: mobileController,
            label: 'رقم الهاتف',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhoneArabic,
          ),
          if (!isEditing) ...[
            AppSpacing.gapMd,
            OchreTextField(
              controller: emailController,
              label: 'البريد الإلكتروني',
              prefixIcon: Icons.email_outlined,
              validator: Validators.validateEmailArabic,
            ),
            AppSpacing.gapMd,
            OchreTextField(
              controller: passwordController,
              label: 'كلمة المرور',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.validatePasswordArabic,
            ),
          ],
          if (_canEditRole) ...[
            AppSpacing.gapMd,
            AppDropdownField<UserRole>(
              fieldKey: const Key('student_role_field'),
              value: selectedRole,
              labelText: 'الدور',
              prefixIcon: Icons.security_outlined,
              items: const [
                DropdownMenuItem(value: UserRole.student, child: Text('مخدوم')),
                DropdownMenuItem(value: UserRole.servant, child: Text('خادم')),
              ],
              onChanged: (role) {
                if (role != null) {
                  onRoleChanged(role);
                }
              },
            ),
          ],
          AppSpacing.gapMd,
          AppDropdownMenuField<Group>(
            initialSelection: group,
            enabled: !_isTeacher,
            dropdownMenuEntries: Group.values
                .map(
                  (value) =>
                      DropdownMenuEntry(value: value, label: value.displayName),
                )
                .toList(growable: false),
            onSelected: (value) {
              if (value != null) {
                onGroupChanged(value);
              }
            },
            label: Text(_isTeacher ? 'المجموعة (مخصصة)' : 'المجموعة'),
            leadingIcon: Icons.school_outlined,
          ),
          AppSpacing.gapMd,
          if (teamsState.isLoading) ...[
            const LinearProgressIndicator(),
            AppSpacing.gapMd,
          ],
          if (teamsState.errorMessage != null) ...[
            Text(
              teamsState.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapMd,
          ],
          AppDropdownField<String>(
            fieldKey: const Key('student_team_field'),
            value: teamsState.selectedTeamId,
            labelText: 'الفريق',
            prefixIcon: Icons.group_outlined,
            items: teamsState.teams
                .map(
                  (team) => DropdownMenuItem<String>(
                    value: team.id,
                    child: Text(team.name),
                  ),
                )
                .toList(growable: false),
            onChanged: teamsState.isLoading || teamsState.teams.isEmpty
                ? null
                : onTeamChanged,
            validator: (value) {
              if (teamsState.isLoading) {
                return null;
              }
              if (teamsState.teams.isEmpty) {
                return 'لا توجد فرق متاحة لهذه المجموعة';
              }
              if (value == null || value.isEmpty) {
                return 'اختيار الفريق مطلوب';
              }
              return null;
            },
          ),
          AppSpacing.gapMd,
          AppDropdownMenuField<EducationStage>(
            initialSelection: educationStage,
            dropdownMenuEntries: EducationStage.values
                .map(
                  (value) =>
                      DropdownMenuEntry(value: value, label: value.displayName),
                )
                .toList(growable: false),
            onSelected: (value) {
              if (value != null) {
                onEducationStageChanged(value);
              }
            },
            label: const Text('المرحلة التعليمية'),
            leadingIcon: Icons.badge_outlined,
          ),
          AppSpacing.gapMd,
          AppDropdownMenuField<int>(
            initialSelection: grade,
            dropdownMenuEntries: List.generate(
              12,
              (index) => DropdownMenuEntry(
                value: index + 1,
                label: 'الصف ${index + 1}',
              ),
            ),
            onSelected: (value) {
              if (value != null) {
                onGradeChanged(value);
              }
            },
            label: const Text('الصف'),
            leadingIcon: Icons.numbers_outlined,
          ),
        ],
      ),
    );
  }
}

class StudentFamilySection extends StatelessWidget {
  const StudentFamilySection({
    super.key,
    required this.motherPhoneController,
    required this.fatherPhoneController,
  });

  final TextEditingController motherPhoneController;
  final TextEditingController fatherPhoneController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات الأسرة', style: _sectionTitleStyle(theme)),
          AppSpacing.gapMd,
          OchreTextField(
            controller: motherPhoneController,
            label: 'هاتف الأم',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhoneArabic,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: fatherPhoneController,
            label: 'هاتف الأب',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhoneArabic,
          ),
        ],
      ),
    );
  }
}

class StudentAdditionalSection extends StatelessWidget {
  const StudentAdditionalSection({
    super.key,
    required this.fatherOfConfessionController,
    required this.schoolController,
    required this.addressController,
    required this.notesController,
    required this.imageUrlController,
    required this.birthdate,
    required this.isTeacher,
    required this.actorGroupLabel,
    required this.onPickBirthdate,
  });

  final TextEditingController fatherOfConfessionController;
  final TextEditingController schoolController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final TextEditingController imageUrlController;
  final DateTime? birthdate;
  final bool isTeacher;
  final String actorGroupLabel;
  final VoidCallback onPickBirthdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات إضافية', style: _sectionTitleStyle(theme)),
          AppSpacing.gapMd,
          OchreTextField(
            controller: fatherOfConfessionController,
            label: 'أب الاعتراف *',
            prefixIcon: Icons.church_outlined,
            validator: Validators.validateNameArabic,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: schoolController,
            label: 'المدرسة / الكلية (اختياري)',
            prefixIcon: Icons.school_outlined,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: addressController,
            label: 'العنوان (اختياري)',
            prefixIcon: Icons.location_on_outlined,
          ),
          AppSpacing.gapMd,
          DatePickerField(
            label: 'تاريخ الميلاد (اختياري)',
            buttonLabel: 'اختيار',
            value: birthdate,
            onPressed: onPickBirthdate,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: notesController,
            label: 'ملاحظات (اختياري)',
            prefixIcon: Icons.notes_outlined,
            maxLines: 2,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: imageUrlController,
            label: 'رابط الصورة (اختياري)',
            prefixIcon: Icons.image_outlined,
          ),
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    isTeacher
                        ? 'نطاق الخادم مفعل: $actorGroupLabel'
                        : 'صلاحيات المسؤول: إضافة/تعديل/حذف كاملة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _sectionTitleStyle(ThemeData theme) {
  return theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}
