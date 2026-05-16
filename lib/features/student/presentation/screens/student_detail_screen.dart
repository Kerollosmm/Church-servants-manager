import 'package:cached_network_image/cached_network_image.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentDetailArgs args;

  const StudentDetailScreen({super.key, required this.args});

  bool _canEdit() => const CanMutateStudentUseCase().canUpdate(
    args.actor,
    args.student,
    args.student,
  );

  @override
  Widget build(BuildContext context) {
    final student = args.student;
    final canEdit = _canEdit();
    final canRestore = args.actor.role == UserRole.admin && student.isArchived;
    final canArchive = canEdit && !student.isArchived;

    return BlocListener<StudentDataBloc, StudentDataState>(
      listener: (context, state) {
        if (state is StudentDataError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is StudentDataLoaded &&
            state.mutationStatus == StudentMutationStatus.success &&
            state.mutationOperation != null) {
          Navigator.pop(context, true);
        }
      },
      child: SanctuaryBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('تفاصيل المخدوم'),
            actions: [
              if (canEdit && !student.isArchived)
                IconButton(
                  icon: const Icon(Icons.fact_check_outlined),
                  tooltip: 'الحضور',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      studentAttendance,
                      arguments: StudentAttendanceArgs(
                        actor: args.actor,
                        studentId: student.docID,
                        studentName: student.name,
                        filterTeamId: student.classId,
                      ),
                    );
                  },
                ),
              if (canEdit && !student.isArchived)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'تعديل',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      studentEdit,
                      arguments: StudentEditArgs(
                        actor: args.actor,
                        student: student,
                      ),
                    );
                  },
                ),
              if (canArchive)
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'أرشفة',
                  onPressed: () async {
                    final shouldArchive = await showGenericDialog<bool>(
                      context: context,
                      title: 'أرشفة المخدوم؟',
                      content:
                          'سيتم إخفاء ${student.name} من القوائم النشطة مع الاحتفاظ بالسجل التاريخي.',
                      optionBuilder: () => {'إلغاء': false, 'أرشفة': true},
                    );

                    if (shouldArchive != true) return;
                    if (!context.mounted) return;

                    context.read<StudentDataBloc>().add(
                      StudentDeleted(actor: args.actor, docId: student.docID),
                    );
                  },
                ),
              if (canRestore)
                IconButton(
                  icon: const Icon(Icons.unarchive_outlined),
                  tooltip: 'استعادة',
                  onPressed: () async {
                    final shouldRestore = await showGenericDialog<bool>(
                      context: context,
                      title: 'استعادة المخدوم؟',
                      content:
                          'سيتم استعادة ${student.name} وإرسال بريد إعادة تعيين كلمة المرور للحساب المرتبط إن وجد.',
                      optionBuilder: () => {'إلغاء': false, 'استعادة': true},
                    );

                    if (shouldRestore != true) return;
                    if (!context.mounted) return;

                    context.read<StudentDataBloc>().add(
                      StudentRestored(actor: args.actor, docId: student.docID),
                    );
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _ProfileHeader(
                studentName: student.name,
                group: student.group,
                grade: student.grade,
                imageUrl: student.imageUrl,
              ),
              AppSpacing.gapMd,
              _AttendanceSummary(summary: student.attendanceSummary),
              AppSpacing.gapMd,
              _InfoSection(
                title: 'البيانات الشخصية',
                children: [
                  _InfoRow(label: 'الاسم الكامل', value: student.name),
                  _InfoRow(label: 'المجموعة', value: student.group.displayName),
                  _InfoRow(label: 'الفريق', value: _optional(student.teamName)),
                  _InfoRow(label: 'الصف', value: 'الصف ${student.grade}'),
                  _InfoRow(
                    label: 'المرحلة التعليمية',
                    value: student.educationStage.displayName,
                  ),
                  _InfoRow(
                    label: 'تاريخ الميلاد',
                    value: _formatDate(student.birthdate),
                  ),
                  _InfoRow(
                    label: 'أب الاعتراف',
                    value: _optional(student.fatherOfConfession),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              _InfoSection(
                title: 'بيانات التواصل',
                children: [
                  _InfoRow(label: 'الموبايل', value: _optional(student.mobile)),
                  _InfoRow(
                    label: 'هاتف الأم',
                    value: _optional(student.motherPhone),
                  ),
                  _InfoRow(
                    label: 'هاتف الأب',
                    value: _optional(student.fatherPhone),
                  ),
                  _InfoRow(label: 'العنوان', value: _optional(student.address)),
                ],
              ),
              AppSpacing.gapMd,
              _InfoSection(
                title: 'بيانات إضافية',
                children: [
                  _InfoRow(
                    label: 'المدرسة / الكلية',
                    value: _optional(student.school),
                  ),
                  _InfoRow(label: 'ملاحظات', value: _optional(student.notes)),
                ],
              ),
              AppSpacing.gapMd,
              AppInfoBanner(
                icon: student.isArchived
                    ? Icons.archive_outlined
                    : Icons.cloud_done,
                message: student.isArchived
                    ? 'هذا المخدوم مؤرشف حاليا.'
                    : canEdit
                    ? 'صلاحيات الإدارة: ${_roleLabel(args.actor.role)}'
                    : 'عرض فقط',
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  static String _optional(String? value) =>
      value == null || value.isEmpty ? '--' : value;

  static String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'مسؤول';
      case UserRole.servant:
        return 'خادم';
      case UserRole.student:
        return 'مخدوم';
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String studentName;
  final Group group;
  final int grade;
  final String? imageUrl;

  const _ProfileHeader({
    required this.studentName,
    required this.group,
    required this.grade,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return OchreCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المجموعة ${group.displayName} • الصف $grade',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  final Map<String, dynamic>? summary;

  const _AttendanceSummary({this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary?['totalSessions'] as int? ?? 0;
    final present = summary?['totalPresent'] as int? ?? 0;
    final percentage = total > 0 ? (present / total) : 0.0;
    final streak = summary?['streak'] as int? ?? 0;

    return OchreCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'نسبة الحضور',
                value: '${(percentage * 100).toStringAsFixed(0)}%',
                child: CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            const VerticalDivider(width: 32, indent: 8, endIndent: 8),
            Expanded(
              child: _SummaryStat(
                label: 'إجمالي الحضور',
                value: '$present',
                subtitle: 'من أصل $total حصة',
              ),
            ),
            const VerticalDivider(width: 32, indent: 8, endIndent: 8),
            Expanded(
              child: _SummaryStat(
                label: 'التتابع الحالي',
                value: '$streak',
                subtitle: 'حصص متتالية',
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Widget? child;
  final IconData? icon;
  final Color? iconColor;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.subtitle,
    this.child,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (child != null) ...[
          SizedBox(height: 50, width: 50, child: child),
          const SizedBox(height: 8),
        ] else if (icon != null) ...[
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
        ],
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return OchreCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
