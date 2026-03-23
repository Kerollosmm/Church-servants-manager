import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter/material.dart';

class ServantEditControllers {
  ServantEditControllers({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    required this.fatherOfConfession,
    required this.notes,
    required this.imageUrl,
  });

  factory ServantEditControllers.fromServant(ServantModel? servant) {
    return ServantEditControllers(
      name: TextEditingController(text: servant?.name ?? ''),
      phone: TextEditingController(text: servant?.phone ?? ''),
      email: TextEditingController(text: servant?.email ?? ''),
      password: TextEditingController(),
      fatherOfConfession: TextEditingController(
        text: servant?.fatherOfConfession ?? '',
      ),
      notes: TextEditingController(text: servant?.notes ?? ''),
      imageUrl: TextEditingController(text: servant?.imageUrl ?? ''),
    );
  }

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController fatherOfConfession;
  final TextEditingController notes;
  final TextEditingController imageUrl;

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    fatherOfConfession.dispose();
    notes.dispose();
    imageUrl.dispose();
  }
}
