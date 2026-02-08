import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';

class MyTextField extends StatelessWidget {
  const MyTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.errorText,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
  });

  final String label;
  final IconData icon;
  final String errorText;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return errorText;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: MyColors.lightBrown),
            prefixIcon: Icon(icon),
            prefixIconColor: MyColors.lightBrown,
            suffixIcon: suffixIcon,
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: MyColors.lightBrown),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: MyColors.lightBrown),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      );

  }
}