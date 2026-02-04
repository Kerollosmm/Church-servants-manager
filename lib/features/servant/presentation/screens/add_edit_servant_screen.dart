import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class AddEditServantScreen extends StatefulWidget {
  final ServantEditArgs args;

  const AddEditServantScreen({super.key, required this.args});

  @override
  State<AddEditServantScreen> createState() => _AddEditServantScreenState();
}

class _AddEditServantScreenState extends State<AddEditServantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _teamName;
  late final TextEditingController _fatherOfConfession;
  late final TextEditingController _notes;
  late final TextEditingController _imageUrl;

  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    final servant = widget.args.servant;

    _name = TextEditingController(text: servant?.name ?? '');
    _phone = TextEditingController(text: servant?.phone ?? '');
    _email = TextEditingController(text: servant?.email ?? '');
    _teamName = TextEditingController(text: servant?.teamName ?? 'Team A');
    _fatherOfConfession = TextEditingController(
      text: servant?.fatherOfConfession ?? '',
    );
    _notes = TextEditingController(text: servant?.notes ?? '');
    _imageUrl = TextEditingController(text: servant?.imageUrl ?? '');
    _birthdate = servant?.birthdate;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _teamName.dispose();
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

    final uid = existing?.uid ?? _uuid.v4();
    final docId = existing?.docID ?? 'temp';

    final servant = ServantModel(
      uid: uid,
      docID: docId,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      role: UserRole.servant,
      teamName: _teamName.text.trim(),
      fatherOfConfession: _fatherOfConfession.text.trim().isEmpty
          ? null
          : _fatherOfConfession.text.trim(),
      birthdate: _birthdate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    final bloc = context.read<ServantDataBloc>();
    if (isEditing) {
      bloc.add(ServantUpdated(actor: actor, servant: servant));
    } else {
      bloc.add(ServantCreated(actor: actor, servant: servant));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.args.isEditing;
    final theme = Theme.of(context);

    return BlocListener<ServantDataBloc, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataOperationSuccess) {
          Navigator.pop(context);
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات الخادم', // Servant Info
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'الاسم', // Name
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'مطلوب'
                              : null, // Required
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف', // Phone
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText:
                                'البريد الإلكتروني (اختياري)', // Email (optional)
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _teamName,
                          decoration: const InputDecoration(
                            labelText: 'المجموعة', // Team
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات إضافية', // Other Details
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _fatherOfConfession,
                          decoration: const InputDecoration(
                            labelText:
                                'أب الاعتراف (اختياري)', // Father of Confession
                            prefixIcon: Icon(Icons.church_outlined),
                          ),
                        ),
                        AppSpacing.gapMd,
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText:
                                      'تاريخ الميلاد (اختياري)', // Birthdate
                                  prefixIcon: Icon(Icons.cake_outlined),
                                ),
                                child: Text(
                                  _birthdate == null
                                      ? '—'
                                      : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            AppSpacing.gapSm,
                            FilledButton(
                              onPressed: _pickBirthdate,
                              child: const Text('اختيار'), // Pick
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _notes,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (اختياري)', // Notes
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 2,
                        ),
                        AppSpacing.gapMd,
                        TextFormField(
                          controller: _imageUrl,
                          decoration: const InputDecoration(
                            labelText: 'رابط الصورة (اختياري)', // Image URL
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
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
                              Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                              ),
                              AppSpacing.gapSm,
                              Expanded(
                                child: Text(
                                  'صلاحية المسؤول: إضافة/تعديل/حذف', // Admin access
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
                  ),
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
