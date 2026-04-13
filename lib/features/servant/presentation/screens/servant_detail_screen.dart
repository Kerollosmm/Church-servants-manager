import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/core/widgets/common/app_profile_header_card.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detail screen for a servant showing info and archive/restore actions.
class ServantDetailScreen extends StatelessWidget {
  /// Screen arguments containing servant data and actor.
  final ServantDetailArgs args;

  const ServantDetailScreen({super.key, required this.args});

  bool _canEdit() {
    final actor = args.actor;
    return actor.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final servant = args.servant;
    final canEdit = _canEdit();
    final canArchive = canEdit && !servant.isArchived;
    final canRestore = canEdit && servant.isArchived;

    return BlocListener<ServantDataCubit, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataLoaded) {
          if (state.mutationStatus == ServantMutationStatus.success) {
            Navigator.pop(context, true);
          } else if (state.mutationStatus == ServantMutationStatus.failure) {
            AppSnackbars.showError(
              context,
              state.feedbackMessage ?? 'حدث خطأ.',
            );
          }
        } else if (state is ServantDataError) {
          AppSnackbars.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الخادم'), // Servant Details
          actions: [
            if (canEdit && !servant.isArchived)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل', // Edit
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    servantEdit,
                    arguments: ServantEditArgs(
                      actor: args.actor,
                      servant: servant,
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
                    title: 'أرشفة الخادم؟',
                    content:
                        'سيتم إيقاف حساب ${servant.name} وإزالته من القوائم النشطة حتى تتم استعادته.',
                    optionBuilder: () => {'إلغاء': false, 'أرشفة': true},
                  );
                  if (shouldArchive != true || !context.mounted) return;

                  final cubit = context.read<ServantDataCubit>();
                  await cubit.deleteServant(
                    actor: args.actor,
                    docId: servant.docID,
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
                    title: 'استعادة الخادم؟',
                    content:
                        'سيتم استعادة ${servant.name} وإرسال بريد إعادة تعيين كلمة المرور للحساب المرتبط. يلزم تعيين الفريق يدويا بعد الاستعادة.',
                    optionBuilder: () => {'إلغاء': false, 'استعادة': true},
                  );
                  if (shouldRestore != true || !context.mounted) return;

                  final cubit = context.read<ServantDataCubit>();
                  await cubit.restoreServant(
                    actor: args.actor,
                    docId: servant.docID,
                  );
                },
              ),
          ],
        ),
        body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _HeaderCard(
            servantName: servant.name,
            teamName: servant.teamName ?? '--',
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'البيانات الأساسية', // Basic Info
            children: [
              _InfoRow(label: 'الاسم', value: servant.name), // Name
              _InfoRow(
                label: 'المجموعة',
                value: _optional(servant.teamName),
              ), // Team
              _InfoRow(label: 'الدور', value: servant.role.name), // Role
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'بيانات التواصل', // Contact
            children: [
              _InfoRow(
                label: 'رقم الهاتف',
                value: _optional(servant.phone),
              ), // Phone
              _InfoRow(
                label: 'البريد الإلكتروني',
                value: _optional(servant.email),
              ), // Email
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'بيانات أخرى', // Other
            children: [
              _InfoRow(
                label: 'تاريخ الميلاد',
                value: _formatDate(servant.birthdate),
              ), // Birthdate
              _InfoRow(
                label: 'أب الاعتراف',
                value: _optional(servant.fatherOfConfession),
              ), // Father of Confession
              _InfoRow(
                label: 'ملاحظات',
                value: _optional(servant.notes),
              ), // Notes
            ],
          ),
          AppSpacing.gapMd,
          AppInfoBanner(
            icon: servant.isArchived
                ? Icons.archive_outlined
                : Icons.cloud_done,
            message: servant.isArchived
                ? 'هذا الخادم مؤرشف حاليا ويحتاج إلى إعادة تعيين فريق بعد الاستعادة.'
                : canEdit
                ? 'صلاحية المسؤول: تعديل'
                : 'عرض فقط',
          ),
        ],
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
}

class _HeaderCard extends StatelessWidget {
  final String servantName;
  final String teamName;

  const _HeaderCard({required this.servantName, required this.teamName});

  @override
  Widget build(BuildContext context) {
    return AppProfileHeaderCard(
      title: servantName,
      subtitle: 'المجموعة: $teamName',
      avatarText: servantName.isNotEmpty ? servantName[0].toUpperCase() : '?',
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppDetailSectionCard(title: title, children: children);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppKeyValueRow(label: label, value: value, labelWidth: 140);
  }
}
