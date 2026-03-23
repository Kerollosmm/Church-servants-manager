import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:church_management_system/core/widgets/form/date_picker_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:flutter/material.dart';

class StudentContactForm extends StatelessWidget {
  const StudentContactForm({
    super.key,
    required this.motherPhoneController,
    required this.fatherPhoneController,
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

  final TextEditingController motherPhoneController;
  final TextEditingController fatherPhoneController;
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

    return FormSectionCard(
      title: 'بيانات التواصل والإضافات',
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
      children: [
        AppTextFormField(
          controller: motherPhoneController,
          labelText: 'هاتف الأم',
          prefixIcon: Icons.phone_outlined,
          validator: Validators.validatePhoneArabic,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: fatherPhoneController,
          labelText: 'هاتف الأب',
          prefixIcon: Icons.phone_outlined,
          validator: Validators.validatePhoneArabic,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: fatherOfConfessionController,
          labelText: 'أب الاعتراف',
          prefixIcon: Icons.church_outlined,
          validator: Validators.validateNameArabic,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: schoolController,
          labelText: 'المدرسة / الكلية (اختياري)',
          prefixIcon: Icons.school_outlined,
        ),
        AppSpacing.gapMd,
        AppTextFormField(
          controller: addressController,
          labelText: 'العنوان (اختياري)',
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
    );
  }
}
