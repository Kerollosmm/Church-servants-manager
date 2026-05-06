import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/core/widgets/common/app_profile_header_card.dart';
import 'package:church_management_system/core/widgets/common/app_state_message.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_event.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_state.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_profile_setup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key, required this.user});

  final AuthUser user;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StudentProfileBloc>().add(LoadProfileEvent(widget.user));
  }

  @override
  void didUpdateWidget(covariant StudentProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid ||
        oldWidget.user.isEmailVerified != widget.user.isEmailVerified) {
      context.read<StudentProfileBloc>().add(LoadProfileEvent(widget.user));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () {
              context.read<StudentProfileBloc>().add(
                LoadProfileEvent(widget.user),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSignOut());
            },
          ),
        ],
      ),
      body: BlocBuilder<StudentProfileBloc, StudentProfileState>(
        builder: (context, state) {
          if (state is StudentProfileLoading ||
              state is StudentProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentProfileProvisioning) {
            return const AppStateMessage(
              icon: Icons.hourglass_top_outlined,
              title: 'جار إعداد الملف الشخصي',
              message: 'نقوم بتجهيز بياناتك الآن، انتظر قليلا.',
            );
          }

          if (state is StudentProfileMissingProfile) {
            return StudentProfileSetupView(user: widget.user);
          }

          if (state is StudentProfileError) {
            return AppStateMessage(
              icon: Icons.error_outline,
              iconColor: Colors.red,
              title: 'تعذر تحميل الملف الشخصي',
              message: state.message,
              onRetry: () {
                context.read<StudentProfileBloc>().add(
                  LoadProfileEvent(widget.user),
                );
              },
            );
          }

          final student = (state as StudentProfileLoaded).student;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppProfileHeaderCard(
                title: student.name,
                subtitle:
                    'Group ${student.group.name} • Grade ${student.grade}',
                avatarText: student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : '?',
              ),
              AppSpacing.gapMd,
              AppDetailSectionCard(
                title: 'Contact',
                children: [
                  AppKeyValueRow(
                    label: 'Mobile',
                    value: student.mobile,
                    labelWidth: 140,
                  ),
                  AppKeyValueRow(
                    label: 'Mother Phone',
                    value: student.motherPhone,
                    labelWidth: 140,
                  ),
                  AppKeyValueRow(
                    label: 'Father Phone',
                    value: student.fatherPhone,
                    labelWidth: 140,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              AppDetailSectionCard(
                title: 'School',
                children: [
                  AppKeyValueRow(
                    label: 'School/College',
                    value: _opt(student.school),
                    labelWidth: 140,
                  ),
                  AppKeyValueRow(
                    label: 'Address',
                    value: _opt(student.address),
                    labelWidth: 140,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              AppDetailSectionCard(
                title: 'Other',
                children: [
                  AppKeyValueRow(
                    label: 'Education Stage',
                    value: student.educationStage.name,
                    labelWidth: 140,
                  ),
                  AppKeyValueRow(
                    label: 'Father of Confession',
                    value: student.fatherOfConfession,
                    labelWidth: 140,
                  ),
                  AppKeyValueRow(
                    label: 'Notes',
                    value: _opt(student.notes),
                    labelWidth: 140,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              const AppInfoBanner(
                icon: Icons.verified_user,
                message: 'صلاحية العرض فقط: مخدوم',
              ),
            ],
          );
        },
      ),
    );
  }

  String _opt(String? value) => value == null || value.isEmpty ? '—' : value;
}
