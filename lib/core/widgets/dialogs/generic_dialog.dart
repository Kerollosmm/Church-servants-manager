import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

typedef DialogOptionBuilder<T> = Map<String, T?> Function();

Future<T?> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder<T> optionBuilder,
}) {
  final options = optionBuilder();
  return showDialog<T?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Text(content, style: const TextStyle(fontSize: 15)),
        actions: options.keys.map((optionTitle) {
          final T? value = options[optionTitle];
          return TextButton(
            onPressed: () {
              Navigator.of(context).pop(value);
            },
            child: Text(
              optionTitle,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}
