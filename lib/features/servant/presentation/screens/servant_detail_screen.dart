import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
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

    return BlocListener<ServantDataBloc, ServantDataState>(
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'تفاصيل الخادم',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          actions: [
            if (canEdit && !servant.isArchived)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل',
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

                  context.read<ServantDataBloc>().add(
                    ServantDeleted(actor: args.actor, docId: servant.docID),
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

                  context.read<ServantDataBloc>().add(
                    ServantRestored(actor: args.actor, docId: servant.docID),
                  );
                },
              ),
          ],
        ),
        body: SanctuaryBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _ProfileAvatarHeader(
                name: servant.name,
                isActive: !servant.isArchived,
              ),
              AppSpacing.gapLg,
              _InfoSection(
                title: 'البيانات الأساسية',
                children: [
                  _InfoRow(label: 'الاسم', value: servant.name),
                  _InfoRow(
                    label: 'المجموعة',
                    value: _optional(servant.teamName),
                  ),
                  _InfoRow(label: 'الدور', value: servant.role.name),
                ],
              ),
              AppSpacing.gapMd,
              _InfoSection(
                title: 'بيانات التواصل',
                children: [
                  _InfoRow(
                    label: 'رقم الهاتف',
                    value: _optional(servant.phone),
                  ),
                  _InfoRow(
                    label: 'البريد الإلكتروني',
                    value: _optional(servant.email),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              _InfoSection(
                title: 'بيانات أخرى',
                children: [
                  _InfoRow(
                    label: 'تاريخ الميلاد',
                    value: _formatDate(servant.birthdate),
                  ),
                  _InfoRow(
                    label: 'أب الاعتراف',
                    value: _optional(servant.fatherOfConfession),
                  ),
                  _InfoRow(label: 'ملاحظات', value: _optional(servant.notes)),
                ],
              ),
              AppSpacing.gapLg,
              AppInfoBanner(
                icon: servant.isArchived
                    ? Icons.archive_outlined
                    : Icons.verified_user_outlined,
                message: servant.isArchived
                    ? 'هذا الخادم مؤرشف حالياً ويحتاج إلى إعادة تعيين فريق بعد الاستعادة.'
                    : canEdit
                    ? 'صلاحية المسؤول: عرض وتعديل كامل البيانات.'
                    : 'أنت تشاهد تفاصيل الخادم.',
              ),
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
}

class _ProfileAvatarHeader extends StatelessWidget {
  final String name;
  final bool isActive;

  const _ProfileAvatarHeader({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          isActive ? 'حساب نشط' : 'حساب مؤرشف',
          style: TextStyle(
            color: isActive ? AppColors.secondary : AppColors.error,
            fontWeight: FontWeight.w600,
          ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          AppSpacing.gapMd,
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
      child: AppKeyValueRow(label: label, value: value, labelWidth: 120),
    );
  }
}
