import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_state_message.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_bio_section.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key, required this.user});

  final AuthUser user;

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  @override
  void initState() {
    super.initState();
    context.read<StudentProfileCubit>().loadProfile(widget.user);
  }

  @override
  void didUpdateWidget(covariant StudentProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid ||
        oldWidget.user.isEmailVerified != widget.user.isEmailVerified) {
      context.read<StudentProfileCubit>().loadProfile(widget.user);
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
              context.read<StudentProfileCubit>().loadProfile(widget.user);
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
      body: BlocBuilder<StudentProfileCubit, StudentProfileState>(
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
            return AppStateMessage(
              icon: Icons.person_search_outlined,
              title: 'الملف الشخصي غير مكتمل',
              message: state.message,
              onRetry: () {
                context.read<StudentProfileCubit>().loadProfile(widget.user);
              },
            );
          }

          if (state is StudentProfileError) {
            return AppStateMessage(
              icon: Icons.error_outline,
              iconColor: Colors.red,
              title: 'تعذر تحميل الملف الشخصي',
              message: state.message,
              onRetry: () {
                context.read<StudentProfileCubit>().loadProfile(widget.user);
              },
            );
          }

          final student = (state as StudentProfileLoaded).student;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              StudentProfileHeader(student: student),
              AppSpacing.gapMd,
              StudentBioSection(student: student, showIdentitySection: false),
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
}
