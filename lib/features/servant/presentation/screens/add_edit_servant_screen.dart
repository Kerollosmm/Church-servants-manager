import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/ochre_button.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_edit_form_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditServantScreen extends StatefulWidget {
  const AddEditServantScreen({super.key, required this.args});

  final ServantEditArgs args;

  @override
  State<AddEditServantScreen> createState() => _AddEditServantScreenState();
}

class _AddEditServantScreenState extends State<AddEditServantScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _ServantEditControllers _controllers;
  late Group _selectedGroup;
  late UserRole _selectedRole;
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    final servant = widget.args.servant;
    _controllers = _ServantEditControllers.fromServant(servant);
    _birthdate = servant?.birthdate;
    _selectedRole = servant?.role ?? UserRole.servant;
    _selectedGroup = Group.values.firstWhere(
      (v) => v.name == servant?.teamName,
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

    final servant = Servant(
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

    final cubit = context.read<ServantDataBloc>();
    if (isEditing) {
      cubit.add(ServantUpdateRequested(actor: actor, servant: servant));
      return;
    }

    final email = _controllers.email.text.trim();
    final password = _controllers.password.text.trim();
    if (email.isEmpty) {
      AppSnackbars.showError(context, 'البريد الإلكتروني مطلوب.');
      return;
    }
    if (password.isEmpty) {
      AppSnackbars.showError(context, 'كلمة المرور مطلوبة.');
      return;
    }

    cubit.add(
      ServantCreateRequested(
        actor: actor,
        servant: servant,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تجاهل التعديلات؟'),
            content: const Text(
              'لديك تغييرات غير محفوظة. هل تريد حقاً الخروج؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('بقاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تجاهل'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.args.isEditing;
    final servant = widget.args.servant;

    return BlocListener<ServantDataBloc, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataLoaded &&
            state.mutationStatus == ServantMutationStatus.success) {
          Navigator.pop(context);
        } else if (state is ServantDataError) {
          AppSnackbars.showError(context, state.message);
        } else if (state is ServantDataLoaded &&
            state.mutationStatus == ServantMutationStatus.failure &&
            state.feedbackMessage != null) {
          AppSnackbars.showError(context, state.feedbackMessage!);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (!_controllers.hasChanges(
            servant,
            _birthdate,
            _selectedRole,
            _selectedGroup,
          )) {
            Navigator.pop(context);
            return;
          }
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              isEditing ? 'تعديل خادم' : 'إضافة خادم',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: SanctuaryBackground(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    ServantPrimaryDetailsSection(
                      nameController: _controllers.name,
                      phoneController: _controllers.phone,
                      emailController: _controllers.email,
                      passwordController: _controllers.password,
                      isEditing: isEditing,
                      selectedRole: _selectedRole,
                      selectedGroup: _selectedGroup,
                      onRoleChanged: (value) {
                        setState(() => _selectedRole = value);
                      },
                      onGroupChanged: (value) {
                        setState(() => _selectedGroup = value);
                      },
                      passwordValidator: _passwordValidator,
                    ),
                    AppSpacing.gapMd,
                    ServantSecondaryDetailsSection(
                      fatherOfConfessionController:
                          _controllers.fatherOfConfession,
                      notesController: _controllers.notes,
                      imageUrlController: _controllers.imageUrl,
                      birthdate: _birthdate,
                      onPickBirthdate: _pickBirthdate,
                    ),
                    AppSpacing.gapLg,
                    BlocBuilder<ServantDataBloc, ServantDataState>(
                      buildWhen: (prev, curr) {
                        if (prev.runtimeType != curr.runtimeType) return true;
                        if (curr is ServantDataLoaded &&
                            prev is ServantDataLoaded) {
                          return prev.mutationStatus != curr.mutationStatus;
                        }
                        return true;
                      },
                      builder: (context, state) {
                        final isSubmitting =
                            state is ServantDataLoading ||
                            (state is ServantDataLoaded &&
                                state.mutationStatus ==
                                    ServantMutationStatus.inProgress);
                        return OchreButton(
                          text: isEditing ? 'حفظ التعديلات' : 'إنشاء خادم',
                          icon: isEditing ? Icons.save_outlined : Icons.add,
                          isLoading: isSubmitting,
                          onPressed: isSubmitting ? null : _submit,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServantEditControllers {
  _ServantEditControllers({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.fatherOfConfession,
    required this.notes,
    required this.imageUrl,
  });

  factory _ServantEditControllers.fromServant(Servant? servant) {
    return _ServantEditControllers(
      name: TextEditingController(text: servant?.name ?? ''),
      phone: TextEditingController(text: servant?.phone ?? ''),
      email: TextEditingController(text: servant?.email ?? ''),
      password: TextEditingController(),
      fatherOfConfession: TextEditingController(
        text: servant?.fatherOfConfession ?? '',
      ),
      notes: TextEditingController(text: servant?.notes ?? ''),
      imageUrl: TextEditingController(text: servant?.imageUrl ?? ''),
    );
  }

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController fatherOfConfession;
  final TextEditingController notes;
  final TextEditingController imageUrl;

  bool hasChanges(
    Servant? servant,
    DateTime? birthdate,
    UserRole selectedRole,
    Group selectedGroup,
  ) {
    if (servant == null) {
      return name.text.isNotEmpty ||
          phone.text.isNotEmpty ||
          email.text.isNotEmpty ||
          password.text.isNotEmpty ||
          fatherOfConfession.text.isNotEmpty ||
          notes.text.isNotEmpty ||
          imageUrl.text.isNotEmpty ||
          birthdate != null ||
          selectedRole != UserRole.servant ||
          selectedGroup != Group.year1;
    }

    return name.text.trim() != servant.name ||
        phone.text.trim() != (servant.phone ?? '') ||
        email.text.trim() != (servant.email ?? '') ||
        fatherOfConfession.text.trim() != (servant.fatherOfConfession ?? '') ||
        notes.text.trim() != (servant.notes ?? '') ||
        imageUrl.text.trim() != (servant.imageUrl ?? '') ||
        birthdate != servant.birthdate ||
        selectedRole != servant.role ||
        selectedGroup.name != servant.teamName;
  }

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    fatherOfConfession.dispose();
    notes.dispose();
    imageUrl.dispose();
  }
}
