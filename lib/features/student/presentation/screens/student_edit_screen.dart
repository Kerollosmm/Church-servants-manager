import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class StudentEditScreen extends StatefulWidget {
  final StudentEditArgs args;

  const StudentEditScreen({super.key, required this.args});

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _teamName;
  late final TextEditingController _motherPhone;
  late final TextEditingController _fatherPhone;
  late final TextEditingController _school;
  late final TextEditingController _address;
  late final TextEditingController _fatherOfConfession;
  late final TextEditingController _notes;
  late final TextEditingController _imageUrl;

  late Group _group;
  late EducationStage _educationStage;
  late int _grade;
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    final student = widget.args.student;

    _name = TextEditingController(text: student?.name ?? '');
    _mobile = TextEditingController(text: student?.mobile ?? '');
    _teamName = TextEditingController(text: student?.teamName ?? 'Team A');
    _motherPhone = TextEditingController(text: student?.motherPhone ?? '');
    _fatherPhone = TextEditingController(text: student?.fatherPhone ?? '');
    _school = TextEditingController(text: student?.school ?? '');
    _address = TextEditingController(text: student?.address ?? '');
    _fatherOfConfession = TextEditingController(
      text: student?.fatherOfConfession ?? '',
    );
    _notes = TextEditingController(text: student?.notes ?? '');
    _imageUrl = TextEditingController(text: student?.imageUrl ?? '');

    final actor = widget.args.actor;

    if (actor.role == UserRole.servant && actor.groupId != null) {
      _group = Group.values.firstWhere(
        (g) => g.name == actor.groupId,
        orElse: () => Group.year1,
      );
    } else {
      _group = student?.group ?? Group.year1;
    }

    _educationStage = student?.educationStage ?? EducationStage.preparatory;
    _grade = student?.grade ?? 1;
    _birthdate = student?.birthdate;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _teamName.dispose();
    _motherPhone.dispose();
    _fatherPhone.dispose();
    _school.dispose();
    _address.dispose();
    _fatherOfConfession.dispose();
    _notes.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String _classIdForGroup(Group group) => group.name; // year1/year2/year3

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 14, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
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
    final existing = widget.args.student;

    final uid = existing?.uid ?? _uuid.v4();
    final docId = existing?.docID ?? 'temp';

    final classId = _classIdForGroup(_group);

    final student = StudentModel(
      uid: uid,
      docID: docId,
      name: _name.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      role: UserRole.student,
      mobile: _mobile.text.trim(),
      group: _group,
      teamName: _teamName.text.trim(),
      motherPhone: _motherPhone.text.trim(),
      fatherPhone: _fatherPhone.text.trim(),
      grade: _grade,
      educationStage: _educationStage,
      school: _school.text.trim().isEmpty ? null : _school.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      birthdate: _birthdate,
      fatherOfConfession: _fatherOfConfession.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      classId: classId,
    );

    final bloc = context.read<StudentDataBloc>();
    if (isEditing) {
      bloc.add(StudentUpdated(actor: actor, student: student));
    } else {
      bloc.add(StudentCreated(actor: actor, student: student));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final actor = widget.args.actor;
    final isTeacher = actor.role == UserRole.servant;
    final isEditing = widget.args.isEditing;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Info',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobile,
                        decoration: const InputDecoration(
                          labelText: 'Mobile',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _teamName,
                        decoration: const InputDecoration(
                          labelText: 'Team Name',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<Group>(
                        initialSelection: _group,
                        enabled: !isTeacher,
                        dropdownMenuEntries: Group.values
                            .map(
                              (g) => DropdownMenuEntry(
                                value: g,
                                label: g.name,
                              ),
                            )
                            .toList(),
                        onSelected: (g) {
                          if (g == null) return;
                          setState(() => _group = g);
                        },
                        label: Text(isTeacher ? 'Group (Assigned)' : 'Group'),
                        leadingIcon: const Icon(Icons.school_outlined),
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<EducationStage>(
                        initialSelection: _educationStage,
                        dropdownMenuEntries: EducationStage.values
                            .map(
                              (s) => DropdownMenuEntry(
                                value: s,
                                label: s.name,
                              ),
                            )
                            .toList(),
                        onSelected: (s) {
                          if (s == null) return;
                          setState(() => _educationStage = s);
                        },
                        label: const Text('Education Stage'),
                        leadingIcon: const Icon(Icons.badge_outlined),
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<int>(
                        initialSelection: _grade,
                        dropdownMenuEntries: List.generate(
                          12,
                          (i) => DropdownMenuEntry(
                            value: i + 1,
                            label: 'Grade ${i + 1}',
                          ),
                        ),
                        onSelected: (g) {
                          if (g == null) return;
                          setState(() => _grade = g);
                        },
                        label: const Text('Grade'),
                        leadingIcon: const Icon(Icons.numbers_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Contacts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _motherPhone,
                        decoration: const InputDecoration(
                          labelText: 'Mother Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fatherPhone,
                        decoration: const InputDecoration(
                          labelText: 'Father Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Other Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fatherOfConfession,
                        decoration: const InputDecoration(
                          labelText: 'Father of Confession',
                          prefixIcon: Icon(Icons.church_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _school,
                        decoration: const InputDecoration(
                          labelText: 'School / College (optional)',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'Address (optional)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Birthdate (optional)',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              child: Text(
                                _birthdate == null
                                    ? '—'
                                    : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _pickBirthdate,
                            child: const Text('Pick'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isTeacher
                                    ? 'Teacher scope enforced: ${actor.groupId ?? 'not assigned'}'
                                    : 'Admin access: full CRUD',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                label: Text(isEditing ? 'Save Changes' : 'Create Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
