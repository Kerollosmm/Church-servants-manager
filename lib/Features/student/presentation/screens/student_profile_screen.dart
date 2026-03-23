import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_profile_view.dart';
import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return StudentProfileView(user: user);
  }
}
