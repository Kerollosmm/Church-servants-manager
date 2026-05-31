import 'package:cached_network_image/cached_network_image.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentDetailArgs args;

  const StudentDetailScreen({super.key, required this.args});

  bool _canEdit() => const CanMutateStudentUseCase().canUpdate(
    args.actor,
    args.student,
    args.student,
  );

  String _getGradeText(int grade, EducationStage stage) {
    final gradeWords = {
      1: 'الأول',
      2: 'الثاني',
      3: 'الثالث',
      4: 'الرابع',
      5: 'الخامس',
      6: 'السادس',
    };
    final gradeWord = gradeWords[grade] ?? grade.toString();
    return 'الصف $gradeWord ${stage.displayName}';
  }

  String _formatArabicDate(DateTime? date) {
    if (date == null) return '--';
    final months = {
      1: 'يناير',
      2: 'فبراير',
      3: 'مارس',
      4: 'أبريل',
      5: 'مايو',
      6: 'يونيو',
      7: 'يوليو',
      8: 'أغسطس',
      9: 'سبتمبر',
      10: 'أكتوبر',
      11: 'نوفمبر',
      12: 'ديسمبر',
    };
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    Widget? subtitleWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (subtitleWidget != null)
            subtitleWidget
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.primary.withValues(alpha: 0.05),
    );
  }

  Widget _buildProfileCard(BuildContext context, Student student) {
    final canEdit = _canEdit();
    final canRestore = args.actor.role == UserRole.admin && student.isArchived;
    final canArchive = canEdit && !student.isArchived;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child:
                        student.imageUrl != null && student.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: student.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildAvatarPlaceholder(student.name),
                          )
                        : _buildAvatarPlaceholder(student.name),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Student Name
          Text(
            student.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Grade Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _getGradeText(student.grade, student.educationStage),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons Row
          Row(
            children: [
              // Archive / Restore Button
              if (canArchive || canRestore)
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      if (canArchive) {
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
                          StudentDeleted(
                            actor: args.actor,
                            docId: student.docID,
                          ),
                        );
                      } else if (canRestore) {
                        final shouldRestore = await showGenericDialog<bool>(
                          context: context,
                          title: 'استعادة المخدوم؟',
                          content:
                              'سيتم استعادة ${student.name} وإرسال بريد إعادة تعيين كلمة المرور للحساب المرتبط إن وجد.',
                          optionBuilder: () => {
                            'إلغاء': false,
                            'استعادة': true,
                          },
                        );
                        if (shouldRestore != true) return;
                        if (!context.mounted) return;
                        context.read<StudentDataBloc>().add(
                          StudentRestored(
                            actor: args.actor,
                            docId: student.docID,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            student.isArchived
                                ? Icons.unarchive
                                : Icons.archive,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            student.isArchived
                                ? 'استعادة الملف'
                                : 'أرشفة الملف',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (canArchive || canRestore) const SizedBox(width: 12),
              // Share Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Share.share(
                      'تفاصيل المخدوم:\n'
                      'الاسم: ${student.name}\n'
                      'الصف: ${_getGradeText(student.grade, student.educationStage)}\n'
                      'المجموعة: ${student.group.displayName}\n'
                      'الموبايل: ${student.mobile}',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'مشاركة',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCard(
    BuildContext context,
    Map<String, dynamic>? summary,
    Student student,
  ) {
    final total = summary?['totalSessions'] as int? ?? 0;
    final present = summary?['totalPresent'] as int? ?? 0;
    final percentage = total > 0 ? (present / total) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              const Icon(
                Icons.event_available,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'ملخص الحضور',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'السنة الحالية',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Row
          Row(
            children: [
              // Circular progress first (right side in RTL)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Text and linear bar (left side in RTL)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'حضر '),
                          TextSpan(
                            text: '$present',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(text: ' من أصل '),
                          TextSpan(
                            text: '$total',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(text: ' اجتماع'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // View Full History Button
          InkWell(
            onTap: () {
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'عرض سجل الحضور كاملاً',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCallButton(BuildContext context, String phoneNumber) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: phoneNumber));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ الرقم: $phoneNumber'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDark,
          ),
        );
      },
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: const Icon(Icons.phone, color: Color(0xFF2E7D32), size: 16),
      ),
    );
  }

  static String _optional(String? value) =>
      value == null || value.isEmpty ? '--' : value;

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit();

    return BlocConsumer<StudentDataBloc, StudentDataState>(
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
      builder: (context, state) {
        var student = args.student;
        if (state is StudentDataLoaded) {
          student = state.studentsByDocId[student.docID] ?? student;
        }

        return SanctuaryBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'تفاصيل المخدوم',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
              actions: [
                if (canEdit && !student.isArchived)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
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
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                  onPressed: () {},
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileCard(context, student),
                const SizedBox(height: 16),
                _buildAttendanceSummaryCard(
                  context,
                  student.attendanceSummary,
                  student,
                ),
                const SizedBox(height: 20),
                // Personal Info Section
                _buildSectionCard(
                  title: 'المعلومات الأساسية',
                  children: [
                    _buildInfoRow(
                      icon: Icons.groups_outlined,
                      label: 'المجموعة',
                      value: student.group.displayName,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.diversity_3_outlined,
                      label: 'الفريق',
                      value: _optional(student.teamName),
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'تاريخ الميلاد',
                      value: _formatArabicDate(student.birthdate),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Spiritual Info Section
                _buildSectionCard(
                  title: 'المعلومات الروحية',
                  children: [
                    _buildInfoRow(
                      icon: Icons.church_outlined,
                      label: 'أب الاعتراف',
                      value: _optional(student.fatherOfConfession),
                      subtitleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _optional(student.fatherOfConfession),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'كنيسة الملاك ميخائيل',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Family Info Section
                _buildSectionCard(
                  title: 'معلومات العائلة',
                  children: [
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'رقم هاتف الأم',
                      value: _optional(student.motherPhone),
                      trailing: student.motherPhone.isNotEmpty
                          ? _buildPhoneCallButton(context, student.motherPhone)
                          : null,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'رقم هاتف الأب',
                      value: _optional(student.fatherPhone),
                      trailing: student.fatherPhone.isNotEmpty
                          ? _buildPhoneCallButton(context, student.fatherPhone)
                          : null,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.home_outlined,
                      label: 'العنوان',
                      value: _optional(student.address),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Status Banner
                AppInfoBanner(
                  icon: student.isArchived
                      ? Icons.archive_outlined
                      : Icons.cloud_done,
                  message: student.isArchived
                      ? 'هذا المخدوم مؤرشف حاليا.'
                      : canEdit
                      ? 'صلاحيات الإدارة متاحة'
                      : 'عرض فقط',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
