import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_attendance_summary.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_bio_section.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentDetailView extends StatelessWidget {
  const StudentDetailView({super.key, required this.args});

  final StudentDetailArgs args;

  bool get _canEdit =>
      const CanMutateStudentUseCase()(args.actor, args.student);

  Future<void> _openAttendance(BuildContext context) async {
    await Navigator.pushNamed(
      context,
      studentAttendance,
      arguments: StudentAttendanceArgs(
        actor: args.actor,
        studentId: args.student.docID,
        studentName: args.student.name,
        filterTeamId: args.student.classId,
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.pushNamed(
      context,
      studentEdit,
      arguments: StudentEditArgs(actor: args.actor, student: args.student),
    );
  }

  Future<void> _archiveStudent(BuildContext context) async {
    final shouldDelete = await showGenericDialog<bool>(
      context: context,
      title: 'أرشفة المخدوم؟',
      content:
          'سيتم إخفاء ${args.student.name} من القوائم النشطة مع الاحتفاظ بالسجل التاريخي.',
      optionBuilder: () => {'إلغاء': false, 'أرشفة': true},
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }

    context.read<StudentDataBloc>().add(
      StudentDeleted(actor: args.actor, docId: args.student.docID),
    );
  }

  Future<void> _restoreStudent(BuildContext context) async {
    final shouldRestore = await showGenericDialog<bool>(
      context: context,
      title: 'استعادة المخدوم؟',
      content:
          'سيتم استعادة ${args.student.name} وإرسال بريد إعادة تعيين كلمة المرور للحساب المرتبط إن وجد.',
      optionBuilder: () => {'إلغاء': false, 'استعادة': true},
    );
    if (shouldRestore != true || !context.mounted) {
      return;
    }

    context.read<StudentDataBloc>().add(
      StudentRestored(actor: args.actor, docId: args.student.docID),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = args.student;
    final canRestore = args.actor.role == UserRole.admin && student.isArchived;
    final canArchive = _canEdit && !student.isArchived;

    return BlocListener<StudentDataBloc, StudentDataState>(
      listener: (context, state) {
        if (state is StudentDataError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is StudentDataLoaded &&
            state.mutationStatus == StudentMutationStatus.success &&
            state.successMessage != null &&
            (state.successMessage!.contains('أرشفة') ||
                state.successMessage!.contains('استعادة'))) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Details'),
          actions: [
            if (_canEdit && !student.isArchived)
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: 'Attendance',
                onPressed: () => _openAttendance(context),
              ),
            if (_canEdit && !student.isArchived)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => _openEditor(context),
              ),
            if (canArchive)
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archive',
                onPressed: () => _archiveStudent(context),
              ),
            if (canRestore)
              IconButton(
                icon: const Icon(Icons.unarchive_outlined),
                tooltip: 'Restore',
                onPressed: () => _restoreStudent(context),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            StudentProfileHeader(student: student),
            AppSpacing.gapMd,
            StudentBioSection(student: student),
            AppSpacing.gapMd,
            StudentAttendanceSummary(
              student: student,
              actorRole: args.actor.role,
              canEdit: _canEdit,
            ),
          ],
        ),
      ),
    );
  }
}
