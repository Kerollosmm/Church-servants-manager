import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDataFeedbackListener extends StatelessWidget {
  const ServantDataFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServantDataCubit, ServantDataState>(
      listener: (context, state) {
        if (state is ServantDataError) {
          AppSnackbars.showError(context, state.message);
        }
        if (state is ServantDataLoaded &&
            state.feedbackMessage != null &&
            state.mutationStatus == ServantMutationStatus.success) {
          AppSnackbars.showSuccess(
            context,
            state.feedbackMessage!,
            backgroundColor: AppColors.secondary,
          );
        }
        if (state is ServantDataLoaded &&
            state.feedbackMessage != null &&
            state.mutationStatus == ServantMutationStatus.failure) {
          AppSnackbars.showError(context, state.feedbackMessage!);
        }
      },
      child: child,
    );
  }
}
