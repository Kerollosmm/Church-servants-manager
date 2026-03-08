import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:church_management_system/core/widgets/form/date_picker_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:flutter/material.dart';

class ServantPrimaryDetailsSection extends StatelessWidget {
  const ServantPrimaryDetailsSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.isEditing,
    required this.selectedRole,
    required this.selectedGroup,
    required this.onRoleChanged,
    required this.onGroupChanged,
    required this.requiredField,
    required this.passwordValidator,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isEditing;
  final UserRole selectedRole;
  final Group selectedGroup;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<Group> onGroupChanged;
  final String? Function(String?) requiredField;
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormSectionCard(
      title: 'بيانات الخادم',
      titleStyle: _sectionTitleStyle(theme),
      children: [
        AppTextFormField(
          controller: nameController,
          labelText: 'الاسم',
          prefixIcon: Icons.person_outline,
          validator: requiredField,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: phoneController,
          labelText: 'رقم الهاتف',
          prefixIcon: Icons.phone_outlined,
          validator: requiredField,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: emailController,
          labelText: isEditing ? 'البريد الإلكتروني (اختياري)' : 'البريد الإلكتروني',
          prefixIcon: Icons.email_outlined,
          validator: isEditing ? null : requiredField,
        ),
        if (!isEditing) ...[
          AppSpacing.gapMd,
          AppTextFormField(
            controller: passwordController,
            labelText: 'كلمة المرور',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: passwordValidator,
          ),
        ],
        if (isEditing) ...[
          AppSpacing.gapMd,
          AppDropdownField<UserRole>(
            fieldKey: const Key('servant_role_field'),
            initialValue: selectedRole,
            labelText: 'الدور',
            prefixIcon: Icons.security_outlined,
            items: const [
              DropdownMenuItem(value: UserRole.servant, child: Text('خادم')),
              DropdownMenuItem(value: UserRole.student, child: Text('مخدوم')),
              DropdownMenuItem(value: UserRole.admin, child: Text('مسؤول')),
            ],
            onChanged: (value) {
              if (value != null) {
                onRoleChanged(value);
              }
            },
          ),
        ],
        AppSpacing.gapMd,
        AppDropdownField<Group>(
          initialValue: selectedGroup,
          labelText: 'السنة الدراسية',
          prefixIcon: Icons.school_outlined,
          items: Group.values
              .map((group) => DropdownMenuItem(value: group, child: Text(group.name)))
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onGroupChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class ServantSecondaryDetailsSection extends StatelessWidget {
  const ServantSecondaryDetailsSection({
    super.key,
    required this.fatherOfConfessionController,
    required this.notesController,
    required this.imageUrlController,
    required this.birthdate,
    required this.onPickBirthdate,
  });

  final TextEditingController fatherOfConfessionController;
  final TextEditingController notesController;
  final TextEditingController imageUrlController;
  final DateTime? birthdate;
  final VoidCallback onPickBirthdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormSectionCard(
      title: 'بيانات إضافية',
      titleStyle: _sectionTitleStyle(theme),
      children: [
        AppTextFormField(
          controller: fatherOfConfessionController,
          labelText: 'أب الاعتراف (اختياري)',
          prefixIcon: Icons.church_outlined,
        ),
        AppSpacing.gapMd,
        DatePickerField(
          label: 'تاريخ الميلاد (اختياري)',
          buttonLabel: 'اختيار',
          value: birthdate,
          onPressed: onPickBirthdate,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: notesController,
          labelText: 'ملاحظات (اختياري)',
          prefixIcon: Icons.notes_outlined,
          maxLines: 2,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: imageUrlController,
          labelText: 'رابط الصورة (اختياري)',
          prefixIcon: Icons.image_outlined,
        ),
        AppSpacing.gapMd,
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: AppRadius.mdRadius,
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  'صلاحية المسؤول: إضافة/تعديل/حذف',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle? _sectionTitleStyle(ThemeData theme) {
  return theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}
