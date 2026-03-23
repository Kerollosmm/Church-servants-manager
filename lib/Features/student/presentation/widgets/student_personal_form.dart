import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:flutter/material.dart';

class StudentPersonalForm extends StatelessWidget {
  const StudentPersonalForm({
    super.key,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.actorRole,
    required this.isEditing,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final UserRole actorRole;
  final bool isEditing;
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  bool get _canEditRole => isEditing && actorRole == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormSectionCard(
      title: 'البيانات الشخصية',
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
      children: [
        AppTextFormField(
          controller: nameController,
          labelText: 'الاسم الكامل',
          prefixIcon: Icons.person_outline,
          validator: Validators.validateNameArabic,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: mobileController,
          labelText: 'رقم الهاتف',
          prefixIcon: Icons.phone_outlined,
          validator: Validators.validatePhoneArabic,
        ),
        if (!isEditing) ...[
          AppSpacing.gapMd,
          AppTextFormField(
            controller: emailController,
            labelText: 'البريد الإلكتروني',
            prefixIcon: Icons.email_outlined,
            validator: Validators.validateEmailArabic,
          ),
          AppSpacing.gapMd,
          AppTextFormField(
            controller: passwordController,
            labelText: 'كلمة المرور',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            validator: Validators.validatePasswordArabic,
          ),
        ],
        if (_canEditRole) ...[
          AppSpacing.gapMd,
          AppDropdownField<UserRole>(
            fieldKey: const Key('student_role_field'),
            initialValue: selectedRole,
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
      ],
    );
  }
}
