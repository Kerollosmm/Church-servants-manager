import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_edit_controllers.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_edit_form_sections.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_edit_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditServantForm extends StatefulWidget {
  const AddEditServantForm({super.key, required this.args});

  final ServantEditArgs args;

  @override
  State<AddEditServantForm> createState() => _AddEditServantFormState();
}

class _AddEditServantFormState extends State<AddEditServantForm> {
  final _formKey = GlobalKey<FormState>();

  late final ServantEditControllers _controllers;
  late Group _selectedGroup;
  late UserRole _selectedRole;
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    final servant = widget.args.servant;
    _controllers = ServantEditControllers.fromServant(servant);
    _birthdate = servant?.birthdate;
    _selectedRole = servant?.role ?? UserRole.servant;
    _selectedGroup = Group.values.firstWhere(
      (value) => value.name == servant?.teamName,
      orElse: () => Group.year1,
    );
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 25, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: now,
      initialDate: initial,
    );
    if (selected != null) {
      setState(() => _birthdate = selected);
    }
  }

  String? _passwordValidator(String? value) {
    return value == null || value.length < 6
        ? 'يجب أن تكون 6 أحرف على الأقل'
        : null;
  }

  String? _nullableTrimmed(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final actor = widget.args.actor;
    final isEditing = widget.args.isEditing;
    final existing = widget.args.servant;
    final servant = ServantModel(
      uid: existing?.uid,
      docID: existing?.docID ?? 'temp',
      name: _controllers.name.text.trim(),
      phone: _nullableTrimmed(_controllers.phone.text),
      email: _nullableTrimmed(_controllers.email.text),
      imageUrl: _nullableTrimmed(_controllers.imageUrl.text),
      role: isEditing ? _selectedRole : UserRole.servant,
      teamName: _selectedGroup.name,
      fatherOfConfession: _nullableTrimmed(
        _controllers.fatherOfConfession.text,
      ),
      birthdate: _birthdate,
      notes: _nullableTrimmed(_controllers.notes.text),
    );

    final cubit = context.read<ServantDataCubit>();
    if (isEditing) {
      cubit.updateServant(actor: actor, servant: servant);
      return;
    }

    cubit.createServant(
      actor: actor,
      servant: servant,
      email: _nullableTrimmed(_controllers.email.text),
      password: _nullableTrimmed(_controllers.password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ServantEditFormSections(
            nameController: _controllers.name,
            fatherOfConfessionController: _controllers.fatherOfConfession,
            selectedRole: _selectedRole,
            selectedGroup: _selectedGroup,
            birthdate: _birthdate,
            phoneController: _controllers.phone,
            emailController: _controllers.email,
            passwordController: _controllers.password,
            notesController: _controllers.notes,
            imageUrlController: _controllers.imageUrl,
            isEditing: widget.args.isEditing,
            onRoleChanged: (value) {
              setState(() => _selectedRole = value);
            },
            onGroupChanged: (value) {
              setState(() => _selectedGroup = value);
            },
            onPickBirthdate: _pickBirthdate,
            passwordValidator: _passwordValidator,
          ),
          AppSpacing.gapMd,
          ServantEditSubmitButton(
            isEditing: widget.args.isEditing,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
