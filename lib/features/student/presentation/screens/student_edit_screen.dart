import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_cubit.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_edit_form_sections.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentEditScreen extends StatefulWidget {
  const StudentEditScreen({super.key, required this.args});

  final StudentEditArgs args;

  @override
  State<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends State<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _StudentEditControllers _controllers;
  late Group _group;
  late EducationStage _educationStage;
  late int _grade;
  late UserRole _selectedRole;
  DateTime? _birthdate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final student = widget.args.student;
    final actor = widget.args.actor;
    _controllers = _StudentEditControllers.fromStudent(student);
    _group = _resolveInitialGroup(actor: actor, student: student);
    _educationStage = student?.educationStage ?? EducationStage.preparatory;
    _grade = student?.grade ?? 1;
    _selectedRole = student?.role ?? UserRole.student;
    _birthdate = student?.birthdate;
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Group _resolveInitialGroup({
    required AuthUser actor,
    required StudentModel? student,
  }) {
    if (actor.role == UserRole.servant && actor.groupId != null) {
      return Group.values.firstWhere(
        (value) => value.name == actor.groupId,
        orElse: () => Group.year1,
      );
    }
    return student?.group ?? Group.year1;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 14, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: initial,
    );
    if (selected != null && mounted) {
      setState(() => _birthdate = selected);
    }
  }

  TeamModel? _findSelectedTeam(List<TeamModel> teams, String selectedTeamId) {
    for (final team in teams) {
      if (team.id == selectedTeamId) {
        return team;
      }
    }
    return null;
  }

  void _submit(StudentFormTeamsState teamsState) {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedTeamId = teamsState.selectedTeamId;
    if (selectedTeamId == null || selectedTeamId.isEmpty) {
      AppSnackbars.showInfo(context, 'الرجاء اختيار فريق.');
      return;
    }

    final selectedTeam = _findSelectedTeam(teamsState.teams, selectedTeamId);
    if (selectedTeam == null) {
      AppSnackbars.showInfo(context, 'الرجاء اختيار فريق صالح.');
      return;
    }

    final actor = widget.args.actor;
    final isEditing = widget.args.isEditing;
    final existing = widget.args.student;
    final targetRole = isEditing && actor.role == UserRole.admin
        ? _selectedRole
        : UserRole.student;

    if (isEditing &&
        existing != null &&
        existing.role != targetRole &&
        targetRole == UserRole.servant &&
        (existing.uid).trim().isEmpty) {
      AppSnackbars.showError(
        context,
        'لا يمكن ترقية المخدوم بدون حساب مستخدم مرتبط.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final mappedGroup = Group.values.firstWhere(
      (value) => value.name == selectedTeam.groupId,
      orElse: () => _group,
    );

    final student = StudentModel(
      uid: existing?.uid ?? '',
      docID: existing?.docID ?? '',
      name: _controllers.name.text.trim(),
      imageUrl: _nullableTrimmed(_controllers.imageUrl.text),
      role: targetRole,
      mobile: _controllers.mobile.text.trim(),
      group: mappedGroup,
      teamName: selectedTeam.name,
      motherPhone: _controllers.motherPhone.text.trim(),
      fatherPhone: _controllers.fatherPhone.text.trim(),
      grade: _grade,
      educationStage: _educationStage,
      school: _nullableTrimmed(_controllers.school.text),
      address: _nullableTrimmed(_controllers.address.text),
      birthdate: _birthdate,
      fatherOfConfession: _controllers.fatherOfConfession.text.trim(),
      notes: _nullableTrimmed(_controllers.notes.text),
      classId: selectedTeam.id,
    );

    final bloc = context.read<StudentDataBloc>();
    if (isEditing) {
      bloc.add(StudentUpdated(actor: actor, student: student));
      return;
    }

    bloc.add(
      StudentCreated(
        actor: actor,
        student: student,
        email: _nullableTrimmed(_controllers.email.text),
        password: _nullableTrimmed(_controllers.password.text),
      ),
    );
  }

  String? _nullableTrimmed(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _handleGroupChanged(Group group) {
    final actor = widget.args.actor;
    setState(() => _group = group);
    context.read<StudentFormTeamsCubit>().loadTeamsForGroup(
      actor: actor,
      groupId: group.name,
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
    final actor = widget.args.actor;
    final isEditing = widget.args.isEditing;
    final student = widget.args.student;

    return BlocProvider(
      create: (context) =>
          StudentFormTeamsCubit(teamRepository: getIt<TeamRepository>())
            ..loadTeamsForGroup(
              actor: actor,
              groupId: _group.name,
              preferredTeamId: student?.classId,
              preferredTeamName: student?.teamName,
              currentSelection: student?.classId,
            ),
      child: BlocListener<StudentDataBloc, StudentDataState>(
        listener: (context, state) {
          if (state is StudentDataLoaded &&
              state.mutationStatus == StudentMutationStatus.success &&
              state.successMessage != null) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              AppSnackbars.showSuccess(context, state.successMessage!);
              Navigator.pop(context);
            }
          } else if (state is StudentDataError) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              AppSnackbars.showError(context, state.message);
            }
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (!_controllers.hasChanges(student, _birthdate, _selectedRole)) {
              Navigator.pop(context);
              return;
            }
            final shouldPop = await _showExitConfirmation();
            if (shouldPop && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'تعديل مخدوم' : 'إضافة مخدوم'),
            ),
            body: SafeArea(
              child: BlocBuilder<StudentFormTeamsCubit, StudentFormTeamsState>(
                builder: (context, teamsState) {
                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        StudentBasicsSection(
                          nameController: _controllers.name,
                          mobileController: _controllers.mobile,
                          emailController: _controllers.email,
                          passwordController: _controllers.password,
                          actorRole: actor.role,
                          isEditing: isEditing,
                          selectedRole: _selectedRole,
                          group: _group,
                          educationStage: _educationStage,
                          grade: _grade,
                          teamsState: teamsState,
                          onRoleChanged: (role) {
                            setState(() => _selectedRole = role);
                          },
                          onGroupChanged: _handleGroupChanged,
                          onTeamChanged: context
                              .read<StudentFormTeamsCubit>()
                              .selectTeam,
                          onEducationStageChanged: (value) {
                            setState(() => _educationStage = value);
                          },
                          onGradeChanged: (value) {
                            setState(() => _grade = value);
                          },
                        ),
                        AppSpacing.gapMd,
                        StudentFamilySection(
                          motherPhoneController: _controllers.motherPhone,
                          fatherPhoneController: _controllers.fatherPhone,
                        ),
                        AppSpacing.gapMd,
                        StudentAdditionalSection(
                          fatherOfConfessionController:
                              _controllers.fatherOfConfession,
                          schoolController: _controllers.school,
                          addressController: _controllers.address,
                          notesController: _controllers.notes,
                          imageUrlController: _controllers.imageUrl,
                          birthdate: _birthdate,
                          isTeacher: actor.role == UserRole.servant,
                          actorGroupLabel: actor.groupId ?? 'غير مخصص',
                          onPickBirthdate: _pickBirthdate,
                        ),
                        AppSpacing.gapMd,
                        FilledButton.icon(
                          key: const Key('submit_student_button'),
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(teamsState),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  isEditing ? Icons.save_outlined : Icons.add,
                                ),
                          label: Text(
                            isEditing ? 'حفظ التعديلات' : 'إنشاء مخدوم',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentEditControllers {
  _StudentEditControllers({
    required this.name,
    required this.mobile,
    required this.email,
    required this.password,
    required this.motherPhone,
    required this.fatherPhone,
    required this.school,
    required this.address,
    required this.fatherOfConfession,
    required this.notes,
    required this.imageUrl,
  });

  factory _StudentEditControllers.fromStudent(StudentModel? student) {
    return _StudentEditControllers(
      name: TextEditingController(text: student?.name ?? ''),
      mobile: TextEditingController(text: student?.mobile ?? ''),
      email: TextEditingController(),
      password: TextEditingController(),
      motherPhone: TextEditingController(text: student?.motherPhone ?? ''),
      fatherPhone: TextEditingController(text: student?.fatherPhone ?? ''),
      school: TextEditingController(text: student?.school ?? ''),
      address: TextEditingController(text: student?.address ?? ''),
      fatherOfConfession: TextEditingController(
        text: student?.fatherOfConfession ?? '',
      ),
      notes: TextEditingController(text: student?.notes ?? ''),
      imageUrl: TextEditingController(text: student?.imageUrl ?? ''),
    );
  }

  final TextEditingController name;
  final TextEditingController mobile;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController motherPhone;
  final TextEditingController fatherPhone;
  final TextEditingController school;
  final TextEditingController address;
  final TextEditingController fatherOfConfession;
  final TextEditingController notes;
  final TextEditingController imageUrl;

  bool hasChanges(
    StudentModel? student,
    DateTime? birthdate,
    UserRole selectedRole,
  ) {
    if (student == null) {
      return name.text.isNotEmpty ||
          mobile.text.isNotEmpty ||
          email.text.isNotEmpty ||
          password.text.isNotEmpty ||
          motherPhone.text.isNotEmpty ||
          fatherPhone.text.isNotEmpty ||
          school.text.isNotEmpty ||
          address.text.isNotEmpty ||
          fatherOfConfession.text.isNotEmpty ||
          notes.text.isNotEmpty ||
          imageUrl.text.isNotEmpty ||
          birthdate != null;
    }

    return name.text.trim() != student.name ||
        mobile.text.trim() != student.mobile ||
        motherPhone.text.trim() != student.motherPhone ||
        fatherPhone.text.trim() != student.fatherPhone ||
        school.text.trim() != (student.school ?? '') ||
        address.text.trim() != (student.address ?? '') ||
        fatherOfConfession.text.trim() != student.fatherOfConfession ||
        notes.text.trim() != (student.notes ?? '') ||
        imageUrl.text.trim() != (student.imageUrl ?? '') ||
        birthdate != student.birthdate ||
        selectedRole != student.role;
  }

  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    password.dispose();
    motherPhone.dispose();
    fatherPhone.dispose();
    school.dispose();
    address.dispose();
    fatherOfConfession.dispose();
    notes.dispose();
    imageUrl.dispose();
  }
}
