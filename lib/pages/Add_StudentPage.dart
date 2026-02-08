import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';
import 'package:flutterbhz/widgets/Text_field.dart';
import 'package:intl/intl.dart'; // ستحتاج لإضافة حزمة intl في pubspec.yaml لتنسيق التاريخ
import 'dart:ui' as ui;

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final TextEditingController _birthDateController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'EG'), // لجعل التقويم بالعربي
    );
    if (picked != null) {
      setState(() {
        // تنسيق التاريخ ليظهر بشكل مقروء
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
            backgroundColor: MyColors.paige,
            appBar: AppBar(
              backgroundColor: MyColors.lightBrown,
              title: const Text('إضافة طالب', style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: 'بيانات الطالب',
                    children: const [
                      MyTextField(label: 'الاسم', icon: Icons.person_outline, errorText: 'برجاء إدخال الاسم'),
                      MyTextField(label: 'رقم الهاتف', icon: Icons.phone_outlined, errorText: 'برجاء إدخال الرقم'),
                      MyTextField(label: 'البريد الإلكتروني', icon: Icons.email_outlined, errorText: 'برجاء إدخال البريد'),
                      MyTextField(label: 'المجموعة', icon: Icons.group_outlined, errorText: 'برجاء إدخال المجموعة'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'بيانات إضافية',
                    children: [
                      const MyTextField(label: 'أب الاعتراف', icon: Icons.church_outlined, errorText: 'برجاء إدخال الاسم'),
                      Row(
                        children: [
                          Expanded(
                            child: MyTextField(
                              label: 'تاريخ الميلاد',
                              icon: Icons.cake_outlined,
                              errorText: 'برجاء إدخال التاريخ',
                              controller: _birthDateController, // ربط الخانة بالمتحكم
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _selectDate(context), // تشغيل منتقي التاريخ
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.lightBrown,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('اختيار', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const MyTextField(label: 'رقم هاتف الأم', icon: Icons.phone_outlined, errorText: ''),
                      const MyTextField(label: 'رقم هاتف الأب', icon: Icons.phone_outlined, errorText: ''),
                      const MyTextField(label: 'ملاحظات (اختياري)', icon: Icons.notes_outlined, errorText: ''),
                      _buildAdminPermissionTile(),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            bottomSheet: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('حفظ البيانات', style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: MyColors.lightBrown),
                ),
              ),
            ),
          ),
      ),
    );

  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: MyColors.burgundy, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children.expand((widget) => [widget, const SizedBox(height: 16)]).toList()..removeLast(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPermissionTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blueGrey[400]),
          const SizedBox(width: 12),
          Text('صلاحية المسؤول: إضافة/تعديل/حذف', style: TextStyle(color: Colors.blueGrey[700])),
        ],
      ),
    );
  }
}
