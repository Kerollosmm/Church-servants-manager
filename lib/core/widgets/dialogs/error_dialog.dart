import 'package:church_managment_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog<void>(
    context: context,
    title: 'An Error Occurred',
    content: text,
    optionBuilder: () => {'OK': null},
  );
}
