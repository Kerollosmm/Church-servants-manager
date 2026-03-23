import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:church_management_system/core/widgets/form/date_picker_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:flutter/material.dart';

class ServantPersonalInfoForm extends StatelessWidget {
  const ServantPersonalInfoForm({
    super.key,
    required this.nameController,
    required this.fatherOfConfessionController,
    required this.selectedRole,
    required this.selectedGroup,
    required this.birthdate,
    required this.isEditing,
    required this.onRoleChanged,
    required this.onGroupChanged,
    required this.onPickBirthdate,
  });

  final TextEditingController nameController;
  final TextEditingController fatherOfConfessionController;
  final UserRole selectedRole;
  final Group selectedGroup;
  final DateTime? birthdate;
  final bool isEditing;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<Group> onGroupChanged;
  final VoidCallback onPickBirthdate;

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      title: 'البيانات الأساسية',
      titleStyle: _sectionTitleStyle(context),
      children: [
        AppTextFormField(
          controller: nameController,
          labelText: 'الاسم',
          prefixIcon: Icons.person_outline,
          validator: Validators.validateNameArabic,
        ),
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
              .map(
                (group) =>
                    DropdownMenuItem(value: group, child: Text(group.name)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              onGroupChanged(value);
            }
          },
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
          controller: fatherOfConfessionController,
          labelText: 'أب الاعتراف (اختياري)',
          prefixIcon: Icons.church_outlined,
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
