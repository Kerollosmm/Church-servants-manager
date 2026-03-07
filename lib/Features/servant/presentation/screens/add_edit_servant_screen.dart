import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_managment_system/core/widgets/form/date_picker_field.dart';
import 'package:church_managment_system/core/widgets/form/form_section_card.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditServantScreen extends StatefulWidget {
  final ServantEditArgs args;

  const AddEditServantScreen({super.key, required this.args});

  @override
  State<AddEditServantScreen> createState() => _AddEditServantScreenState();
}

class _AddEditServantScreenState extends State<AddEditServantScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _fatherOfConfession;
  late final TextEditingController _notes;
  late final TextEditingController _imageUrl;

  DateTime? _birthdate;
  late Group _selectedGroup;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    final servant = widget.args.servant;

    _name = TextEditingController(text: servant?.name ?? '');
    _phone = TextEditingController(text: servant?.phone ?? '');
    _email = TextEditingController(text: servant?.email ?? '');
    _password = TextEditingController();
    _fatherOfConfession = TextEditingController(
      text: servant?.fatherOfConfession ?? '',
    );
    _notes = TextEditingController(text: servant?.notes ?? '');
    _imageUrl = TextEditingController(text: servant?.imageUrl ?? '');
    _birthdate = servant?.birthdate;
    _selectedRole = servant?.role ?? UserRole.servant;

    // Determine group from teamName or default
    _selectedGroup = Group.values.firstWhere(
      (g) => g.name == servant?.teamName,
      orElse: () => Group.year1,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _fatherOfConfession.dispose();
    _notes.dispose();
    _imageUrl.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final actor = widget.args.actor;
    final isEditing = widget.args.isEditing;
    final existing = widget.args.servant;

    final uid = existing?.uid;
    final docId = existing?.docID ?? 'temp';

    final servant = ServantModel(
      uid: uid,
      docID: docId,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      role: isEditing ? _selectedRole : UserRole.servant,
      teamName: _selectedGroup.name,
      fatherOfConfession: _fatherOfConfession.text.trim().isEmpty
          ? null
          : _fatherOfConfession.text.trim(),
      birthdate: _birthdate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    final cubit = context.read<ServantDataCubit>();
    if (isEditing) {
      cubit.updateServant(actor: actor, servant: servant);
    } else {
      cubit.createServant(
        actor: actor,
        servant: servant,
        email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
        password: _password.text.isNotEmpty ? _password.text : null,
      );
    }
  }

  TextStyle? _sectionTitleStyle(ThemeData theme) {
    return theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: labelText, prefixIcon: Icon(icon)),
      validator: validator,
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.args.isEditing;
    final theme = Theme.of(context);

    return BlocListener<ServantDataCubit, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataOperationSuccess) {
          Navigator.pop(context);
        } else if (state is ServantDataError) {
          AppSnackbars.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'تعديل خادم' : 'إضافة خادم',
          ), // Edit/Add Servant
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                FormSectionCard(
                  title: 'بيانات الخادم',
                  titleStyle: _sectionTitleStyle(theme),
                  children: [
                    _buildTextField(
                      controller: _name,
                      labelText: 'الاسم',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    AppSpacing.gapMd,
                    _buildTextField(
                      controller: _phone,
                      labelText: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    AppSpacing.gapMd,
                    _buildTextField(
                      controller: _email,
                      labelText: isEditing
                          ? 'البريد الإلكتروني (اختياري)'
                          : 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      validator: isEditing
                          ? null
                          : (v) => v == null || v.trim().isEmpty
                                ? 'مطلوب لإنشاء حساب'
                                : null,
                    ),
                    if (!isEditing) ...[
                      AppSpacing.gapMd,
                      _buildTextField(
                        controller: _password,
                        labelText: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6
                            ? 'يجب أن تكون 6 أحرف على الأقل'
                            : null,
                      ),
                    ],
                    if (isEditing) ...[
                      AppSpacing.gapMd,
                      DropdownButtonFormField<UserRole>(
                        key: const Key('servant_role_field'),
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'الدور',
                          prefixIcon: Icon(Icons.security_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.servant,
                            child: Text('خادم'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.student,
                            child: Text('مخدوم'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text('مسؤول'),
                          ),
                        ],
                        onChanged: (role) {
                          if (role == null) return;
                          setState(() => _selectedRole = role);
                        },
                      ),
                    ],
                    AppSpacing.gapMd,
                    DropdownButtonFormField<Group>(
                      initialValue: _selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'السنة الدراسية',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: Group.values
                          .map(
                            (g) =>
                                DropdownMenuItem(value: g, child: Text(g.name)),
                          )
                          .toList(growable: false),
                      onChanged: (g) {
                        if (g == null) return;
                        setState(() {
                          _selectedGroup = g;
                        });
                      },
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                FormSectionCard(
                  title: 'بيانات إضافية',
                  titleStyle: _sectionTitleStyle(theme),
                  children: [
                    _buildTextField(
                      controller: _fatherOfConfession,
                      labelText: 'أب الاعتراف (اختياري)',
                      icon: Icons.church_outlined,
                    ),
                    AppSpacing.gapMd,
                    DatePickerField(
                      label: 'تاريخ الميلاد (اختياري)',
                      buttonLabel: 'اختيار',
                      value: _birthdate,
                      onPressed: _pickBirthdate,
                    ),
                    AppSpacing.gapMd,
                    _buildTextField(
                      controller: _notes,
                      labelText: 'ملاحظات (اختياري)',
                      icon: Icons.notes_outlined,
                      maxLines: 2,
                    ),
                    AppSpacing.gapMd,
                    _buildTextField(
                      controller: _imageUrl,
                      labelText: 'رابط الصورة (اختياري)',
                      icon: Icons.image_outlined,
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
                ),
                AppSpacing.gapMd,
                FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    isEditing ? 'حفظ التعديلات' : 'إنشاء خادم',
                  ), // Save/Create
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
