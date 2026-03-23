import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantEditSubmitButton extends StatelessWidget {
  const ServantEditSubmitButton({
    super.key,
    required this.isEditing,
    required this.onPressed,
  });

  final bool isEditing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServantDataCubit, ServantDataState>(
      builder: (context, state) {
        final isSubmitting =
            state is ServantDataLoading ||
            (state is ServantDataLoaded &&
                state.mutationStatus == ServantMutationStatus.inProgress);

        return FilledButton.icon(
          onPressed: isSubmitting ? null : onPressed,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isEditing ? Icons.save_outlined : Icons.add),
          label: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء خادم'),
        );
      },
    );
  }
}
