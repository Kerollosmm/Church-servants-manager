import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:flutter/material.dart';

class ServantContactForm extends StatelessWidget {
  const ServantContactForm({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.notesController,
    required this.imageUrlController,
    required this.isEditing,
    required this.passwordValidator,
  });

  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController notesController;
  final TextEditingController imageUrlController;
  final bool isEditing;
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      title: 'بيانات التواصل والملاحظات',
      titleStyle: _sectionTitleStyle(context),
      children: [
        AppTextFormField(
          controller: phoneController,
          labelText: 'رقم الهاتف',
          prefixIcon: Icons.phone_outlined,
          validator: Validators.validatePhoneArabic,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: emailController,
          labelText: isEditing
              ? 'البريد الإلكتروني (اختياري)'
              : 'البريد الإلكتروني',
          prefixIcon: Icons.email_outlined,
          validator: isEditing
              ? Validators.validateOptionalEmailArabic
              : Validators.validateEmailArabic,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  TextStyle? _sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
    );
  }
}
