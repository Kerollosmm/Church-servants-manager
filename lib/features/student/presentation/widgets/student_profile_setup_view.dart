import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/validators.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileSetupView extends StatefulWidget {
  final AuthUser user;

  const StudentProfileSetupView({super.key, required this.user});

  @override
  State<StudentProfileSetupView> createState() =>
      _StudentProfileSetupViewState();
}

class _StudentProfileSetupViewState extends State<StudentProfileSetupView> {
  final _formKey = GlobalKey<FormState>();

  final _mobileController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _fatherOfConfessionController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _addressController = TextEditingController();

  EducationStage _selectedStage = EducationStage.highSchool;
  Group _selectedGroup = Group.year1;

  @override
  void dispose() {
    _mobileController.dispose();
    _motherPhoneController.dispose();
    _fatherPhoneController.dispose();
    _fatherOfConfessionController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final grade = int.tryParse(_gradeController.text.trim()) ?? 1;

    final newStudent = StudentModel(
      uid: widget.user.uid,
      docID: widget.user.uid,
      name: widget.user.name,
      imageUrl: null,
      role: widget.user.role,
      mobile: _mobileController.text.trim(),
      group: _selectedGroup,
      teamName: 'غير محدد',
      classId: 'unassigned',
      motherPhone: _motherPhoneController.text.trim(),
      fatherPhone: _fatherPhoneController.text.trim(),
      grade: grade,
      educationStage: _selectedStage,
      school: _schoolController.text.trim().isEmpty
          ? null
          : _schoolController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      birthdate: null,
      fatherOfConfession: _fatherOfConfessionController.text.trim(),
      notes: null,
    );

    context.read<StudentProfileBloc>().add(
      SetupProfileEvent(newStudent: newStudent, actor: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'استكمال الملف الشخصي',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapSm,
                const Text(
                  'برجاء استكمال بياناتك لتتمكن من استخدام التطبيق',
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapLg,
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف المحمول',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneArabic,
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _motherPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم هاتف الأم',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneArabic,
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _fatherPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم هاتف الأب',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneArabic,
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _fatherOfConfessionController,
                  decoration: const InputDecoration(
                    labelText: 'أب الاعتراف',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'هذا الحقل مطلوب'
                      : null,
                ),
                AppSpacing.gapMd,
                DropdownButtonFormField<EducationStage>(
                  initialValue: _selectedStage,
                  decoration: const InputDecoration(
                    labelText: 'المرحلة الدراسية',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: EducationStage.values.map((stage) {
                    return DropdownMenuItem(
                      value: stage,
                      child: Text(stage.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStage = value;
                      });
                    }
                  },
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: 'السنة الدراسية (رقم)',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'هذا الحقل مطلوب';
                    }
                    if (int.tryParse(value) == null) {
                      return 'يجب إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                AppSpacing.gapMd,
                DropdownButtonFormField<Group>(
                  initialValue: _selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'الفرقة/المجموعة',
                    prefixIcon: Icon(Icons.group),
                  ),
                  items: Group.values.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGroup = value;
                      });
                    }
                  },
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _schoolController,
                  decoration: const InputDecoration(
                    labelText: 'المدرسة/الكلية (اختياري)',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                AppSpacing.gapXl,
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ البيانات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
