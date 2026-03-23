import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_contact_form.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_personal_info_form.dart';
import 'package:flutter/material.dart';

class ServantEditFormSections extends StatelessWidget {
  const ServantEditFormSections({
    super.key,
    required this.nameController,
    required this.fatherOfConfessionController,
    required this.selectedRole,
    required this.selectedGroup,
    required this.birthdate,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.notesController,
    required this.imageUrlController,
    required this.isEditing,
    required this.onRoleChanged,
    required this.onGroupChanged,
    required this.onPickBirthdate,
    required this.passwordValidator,
  });

  final TextEditingController nameController;
  final TextEditingController fatherOfConfessionController;
  final UserRole selectedRole;
  final Group selectedGroup;
  final DateTime? birthdate;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController notesController;
  final TextEditingController imageUrlController;
  final bool isEditing;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<Group> onGroupChanged;
  final VoidCallback onPickBirthdate;
  final String? Function(String?) passwordValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServantPersonalInfoForm(
          nameController: nameController,
          fatherOfConfessionController: fatherOfConfessionController,
          selectedRole: selectedRole,
          selectedGroup: selectedGroup,
          birthdate: birthdate,
          isEditing: isEditing,
          onRoleChanged: onRoleChanged,
          onGroupChanged: onGroupChanged,
          onPickBirthdate: onPickBirthdate,
        ),
        AppSpacing.gapMd,
        ServantContactForm(
          phoneController: phoneController,
          emailController: emailController,
          passwordController: passwordController,
          notesController: notesController,
          imageUrlController: imageUrlController,
          isEditing: isEditing,
          passwordValidator: passwordValidator,
        ),
      ],
    );
  }
}
