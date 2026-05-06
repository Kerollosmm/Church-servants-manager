import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/ochre_text_field.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/date_picker_field.dart';
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
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('البيانات الأساسية', style: _sectionTitleStyle(context)),
          AppSpacing.gapMd,
          OchreTextField(
            controller: nameController,
            label: 'الاسم',
            placeholder: 'الاسم بالكامل',
            prefixIcon: Icons.person_outline,
            validator: Validators.validateNameArabic,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: phoneController,
            label: 'رقم الهاتف',
            placeholder: '01xxxxxxxxx',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhoneArabic,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: emailController,
            label: isEditing
                ? 'البريد الإلكتروني (اختياري)'
                : 'البريد الإلكتروني',
            placeholder: 'example@church.com',
            prefixIcon: Icons.email_outlined,
            validator: isEditing
                ? Validators.validateOptionalEmailArabic
                : Validators.validateEmailArabic,
          ),
          if (!isEditing) ...[
            AppSpacing.gapMd,
            OchreTextField(
              controller: passwordController,
              label: 'كلمة المرور',
              placeholder: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: passwordValidator,
            ),
          ],
          AppSpacing.gapMd,
          if (isEditing) ...[
            AppDropdownField<UserRole>(
              fieldKey: const Key('servant_role_field'),
              value: selectedRole,
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
            AppSpacing.gapMd,
          ],
          AppDropdownField<Group>(
            value: selectedGroup,
            labelText: 'السنة الدراسية',
            prefixIcon: Icons.school_outlined,
            items: Group.values
                .map(
                  (group) => DropdownMenuItem(
                    value: group,
                    child: Text(group.displayName),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onGroupChanged(value);
              }
            },
          ),
        ],
      ),
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
    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات إضافية', style: _sectionTitleStyle(context)),
          AppSpacing.gapMd,
          OchreTextField(
            controller: fatherOfConfessionController,
            label: 'أب الاعتراف (اختياري)',
            placeholder: 'القدس أب...',
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
          OchreTextField(
            controller: notesController,
            label: 'ملاحظات (اختياري)',
            placeholder: 'أي ملاحظات إضافية...',
            prefixIcon: Icons.notes_outlined,
            maxLines: 2,
          ),
          AppSpacing.gapMd,
          OchreTextField(
            controller: imageUrlController,
            label: 'رابط الصورة (اختياري)',
            placeholder: 'https://...',
            prefixIcon: Icons.image_outlined,
          ),
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'صلاحية المسؤول: إضافة وتعديل البيانات.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

TextStyle? _sectionTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}
