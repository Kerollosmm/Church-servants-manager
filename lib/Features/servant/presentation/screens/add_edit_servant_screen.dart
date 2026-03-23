import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/servant/presentation/widgets/add_edit_servant_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddEditServantScreen extends StatefulWidget {
  const AddEditServantScreen({super.key, required this.args});

  final ServantEditArgs args;

  @override
  State<AddEditServantScreen> createState() => _AddEditServantScreenState();
}

class _AddEditServantScreenState extends State<AddEditServantScreen> {
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.args.isEditing;

    return BlocListener<ServantDataCubit, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataLoaded &&
            state.mutationStatus == ServantMutationStatus.success &&
            state.feedbackMessage != null) {
          Navigator.pop(context);
        } else if (state is ServantDataError) {
          AppSnackbars.showError(context, state.message);
        } else if (state is ServantDataLoaded &&
            state.mutationStatus == ServantMutationStatus.failure &&
            state.feedbackMessage != null) {
          AppSnackbars.showError(context, state.feedbackMessage!);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'تعديل خادم' : 'إضافة خادم')),
        body: SafeArea(child: AddEditServantForm(args: widget.args)),
      ),
    );
  }
}
