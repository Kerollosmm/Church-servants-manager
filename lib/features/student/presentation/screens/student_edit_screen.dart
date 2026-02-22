import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/utils/validators.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentEditScreen extends StatefulWidget {
  final StudentEditArgs args;

  const StudentEditScreen({super.key, required this.args});

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _password;
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
  late UserRole _selectedRole;
  DateTime? _birthdate;
  late final TeamRepository _teamRepository;
  List<TeamModel> _teams = const <TeamModel>[];
  String? _selectedTeamId;
  bool _isLoadingTeams = false;

  @override
  void initState() {
    super.initState();
    final student = widget.args.student;
    final actor = widget.args.actor;

    _name = TextEditingController(text: student?.name ?? '');
    _mobile = TextEditingController(text: student?.mobile ?? '');
    _email = TextEditingController();
    _password = TextEditingController();
    _motherPhone = TextEditingController(text: student?.motherPhone ?? '');
    _fatherPhone = TextEditingController(text: student?.fatherPhone ?? '');
    _school = TextEditingController(text: student?.school ?? '');
    _address = TextEditingController(text: student?.address ?? '');
    _fatherOfConfession = TextEditingController(
      text: student?.fatherOfConfession ?? '',
    );
    _notes = TextEditingController(text: student?.notes ?? '');
    _imageUrl = TextEditingController(text: student?.imageUrl ?? '');

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
    _selectedRole = student?.role ?? UserRole.student;
    _birthdate = student?.birthdate;

    _teamRepository = context.read<TeamRepository>();
    _loadTeamsForGroup(
      _group.name,
      preferredTeamId: student?.classId,
      preferredTeamName: student?.teamName,
      currentSelection: student?.classId,
    );
  }

  Future<void> _loadTeamsForGroup(
    String groupId, {
    String? preferredTeamId,
    String? preferredTeamName,
    String? currentSelection,
  }) async {
    setState(() => _isLoadingTeams = true);

    try {
      final actor = widget.args.actor;
      final assignedTeamIds = actor.effectiveAssignedTeamIds.toSet();
      final teamsFromRepo = await _teamRepository.getTeamsByGroup(groupId);
      var visibleTeams = teamsFromRepo;

      if (actor.role == UserRole.servant && assignedTeamIds.isNotEmpty) {
        visibleTeams = teamsFromRepo
            .where((team) => assignedTeamIds.contains(team.id))
            .toList(growable: false);
      }

      final validTeamIds = visibleTeams.map((team) => team.id).toSet();
      String? resolvedTeamId;

      if (preferredTeamId != null && validTeamIds.contains(preferredTeamId)) {
        resolvedTeamId = preferredTeamId;
      }
      if (resolvedTeamId == null &&
          preferredTeamName != null &&
          preferredTeamName.isNotEmpty) {
        for (final team in visibleTeams) {
          if (team.name.trim() == preferredTeamName.trim()) {
            resolvedTeamId = team.id;
            break;
          }
        }
      }
      if (resolvedTeamId == null &&
          currentSelection != null &&
          validTeamIds.contains(currentSelection)) {
        resolvedTeamId = currentSelection;
      }
      if (resolvedTeamId == null &&
          actor.role == UserRole.servant &&
          assignedTeamIds.length == 1 &&
          validTeamIds.contains(actor.effectiveAssignedTeamIds.first)) {
        resolvedTeamId = actor.effectiveAssignedTeamIds.first;
      }

      if (!mounted) return;
      setState(() {
        _teams = visibleTeams;
        _selectedTeamId = resolvedTeamId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _teams = const <TeamModel>[];
        _selectedTeamId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load teams: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    _motherPhone.dispose();
    _fatherPhone.dispose();
    _school.dispose();
    _address.dispose();
    _fatherOfConfession.dispose();
    _notes.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 14, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2012),
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
    final selectedTeamId = _selectedTeamId;
    final selectedRole = isEditing && actor.role == UserRole.admin
        ? _selectedRole
        : UserRole.student;

    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a team.')));
      return;
    }

    TeamModel? selectedTeam;
    for (final team in _teams) {
      if (team.id == selectedTeamId) {
        selectedTeam = team;
        break;
      }
    }
    if (selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid team.')),
      );
      return;
    }
    final normalizedSelectedTeam = selectedTeam;

    final mappedGroup = Group.values.firstWhere(
      (value) => value.name == normalizedSelectedTeam.groupId,
      orElse: () => _group,
    );

    final uid = existing?.uid ?? '';
    final docId = existing?.docID ?? '';

    if (isEditing &&
        existing != null &&
        existing.role != selectedRole &&
        selectedRole == UserRole.servant &&
        uid.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot promote student without linked user account.'),
        ),
      );
      return;
    }

    final student = StudentModel(
      uid: uid,
      docID: docId,
      name: _name.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      role: selectedRole,
      mobile: _mobile.text.trim(),
      group: mappedGroup,
      teamName: normalizedSelectedTeam.name,
      motherPhone: _motherPhone.text.trim(),
      fatherPhone: _fatherPhone.text.trim(),
      grade: _grade,
      educationStage: _educationStage,
      school: _school.text.trim().isEmpty ? null : _school.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      birthdate: _birthdate,
      fatherOfConfession: _fatherOfConfession.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      classId: normalizedSelectedTeam.id,
    );

    final bloc = context.read<StudentDataBloc>();
    if (isEditing) {
      bloc.add(StudentUpdated(actor: actor, student: student));
    } else {
      bloc.add(
        StudentCreated(
          actor: actor,
          student: student,
          email: _email.text.trim().isNotEmpty ? _email.text.trim() : null,
          password: _password.text.isNotEmpty ? _password.text : null,
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required Widget prefixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText, prefixIcon: prefixIcon),
      validator: validator,
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = widget.args.actor;
    final isTeacher = actor.role == UserRole.servant;
    final isEditing = widget.args.isEditing;

    final theme = Theme.of(context);

    return BlocListener<StudentDataBloc, StudentDataState>(
      listener: (context, state) {
        if (state is StudentDataOperationSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.pop(context);
        } else if (state is StudentDataError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Student' : 'Add Student')),
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
                          'Student Info',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _name,
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.validateName,
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _mobile,
                          labelText: 'Mobile',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: Validators.validatePhone,
                        ),
                        if (!isEditing) ...[
                          AppSpacing.gapMd,
                          _buildTextField(
                            controller: _email,
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'مطلوب لإنشاء حساب'
                                : null,
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'يجب أن تكون 6 أحرف على الأقل'
                                : null,
                          ),
                        ],
                        if (isEditing && actor.role == UserRole.admin) ...[
                          AppSpacing.gapMd,
                          DropdownButtonFormField<UserRole>(
                            key: const Key('student_role_field'),
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              prefixIcon: Icon(Icons.security_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: UserRole.student,
                                child: Text('student'),
                              ),
                              DropdownMenuItem(
                                value: UserRole.servant,
                                child: Text('servant'),
                              ),
                            ],
                            onChanged: (role) {
                              if (role == null) return;
                              setState(() => _selectedRole = role);
                            },
                          ),
                        ],
                        AppSpacing.gapMd,
                        DropdownMenu<Group>(
                          initialSelection: _group,
                          enabled: !isTeacher,
                          dropdownMenuEntries: Group.values
                              .map(
                                (g) =>
                                    DropdownMenuEntry(value: g, label: g.name),
                              )
                              .toList(),
                          onSelected: (g) {
                            if (g == null) return;
                            setState(() {
                              _group = g;
                              _selectedTeamId = null;
                            });
                            _loadTeamsForGroup(g.name);
                          },
                          label: Text(isTeacher ? 'Group (Assigned)' : 'Group'),
                          leadingIcon: const Icon(Icons.school_outlined),
                        ),
                        AppSpacing.gapMd,
                        if (_isLoadingTeams) ...[
                          const LinearProgressIndicator(),
                          AppSpacing.gapMd,
                        ],
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'team-field-${_group.name}-${_selectedTeamId ?? 'none'}-${_teams.length}',
                          ),
                          initialValue: _selectedTeamId,
                          decoration: const InputDecoration(
                            labelText: 'Team',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                          items: _teams
                              .map(
                                (team) => DropdownMenuItem<String>(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _isLoadingTeams || _teams.isEmpty
                              ? null
                              : (teamId) {
                                  setState(() => _selectedTeamId = teamId);
                                },
                          validator: (value) {
                            if (_isLoadingTeams) return null;
                            if (_teams.isEmpty) {
                              return 'No teams available for this group';
                            }
                            if (value == null || value.isEmpty) {
                              return 'Team is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapMd,
                        DropdownMenu<EducationStage>(
                          initialSelection: _educationStage,
                          dropdownMenuEntries: EducationStage.values
                              .map(
                                (s) =>
                                    DropdownMenuEntry(value: s, label: s.name),
                              )
                              .toList(),
                          onSelected: (s) {
                            if (s == null) return;
                            setState(() => _educationStage = s);
                          },
                          label: const Text('Education Stage'),
                          leadingIcon: const Icon(Icons.badge_outlined),
                        ),
                        AppSpacing.gapMd,
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
                AppSpacing.gapMd,
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Contacts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _motherPhone,
                          labelText: 'Mother Phone',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: Validators.validatePhone,
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _fatherPhone,
                          labelText: 'Father Phone',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          validator: Validators.validatePhone,
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
                          'Other Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _fatherOfConfession,
                          labelText: 'Father of Confession',
                          prefixIcon: const Icon(Icons.church_outlined),
                          validator: Validators.validateName,
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _school,
                          labelText: 'School / College (optional)',
                          prefixIcon: const Icon(Icons.school_outlined),
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _address,
                          labelText: 'Address (optional)',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        AppSpacing.gapMd,
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            AppSpacing.gapSm,
                            FilledButton(
                              onPressed: _pickBirthdate,
                              child: const Text('Pick'),
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _notes,
                          labelText: 'Notes (optional)',
                          prefixIcon: const Icon(Icons.notes_outlined),
                          maxLines: 2,
                        ),
                        AppSpacing.gapMd,
                        _buildTextField(
                          controller: _imageUrl,
                          labelText: 'Image URL (optional)',
                          prefixIcon: const Icon(Icons.image_outlined),
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
                                  isTeacher
                                      ? 'Teacher scope enforced: ${actor.groupId ?? 'not assigned'}'
                                      : 'Admin access: full CRUD',
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
                  key: const Key('submit_student_button'),
                  onPressed: _submit,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Save Changes' : 'Create Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
