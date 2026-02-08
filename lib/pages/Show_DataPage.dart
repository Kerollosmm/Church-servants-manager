import 'package:flutter/material.dart';

import '../widgets/MyColors.dart';


class ShowDataPage extends StatelessWidget {
  const ShowDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Directionality(
        textDirection: TextDirection.rtl, // Right-to-Left for Arabic
        child: Scaffold(
          backgroundColor: MyColors.paige,
          appBar: AppBar(
            backgroundColor: MyColors.lightBrown,
            title: const Text('تفاصيل الطالب', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: () {}),
            ],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header Profile Card
                _buildHeaderCard(),
                const SizedBox(height: 16),

                // Basic Information
                _buildInfoCard(
                  title: 'البيانات الأساسية',
                  items: {
                    'الاسم': 'kerollos',
                    'المجموعة': 'year1',
                    'الدور': 'servant',
                  },
                ),
                const SizedBox(height: 16),

                // Contact Information
                _buildInfoCard(
                  title: 'بيانات التواصل',
                  items: {
                    'رقم الهاتف': '--',
                    'البريد الإلكتروني': 'kerollosmelad94@gmail.com',
                  },
                ),
                const SizedBox(height: 16),

                // Other Information
                _buildInfoCard(
                  title: 'بيانات أخرى',
                  items: {
                    'تاريخ الميلاد': '--',
                    'رقم هاتف الأم': '--',
                    'رقم هاتف الأب': '--',
                    'أب الاعتراف': '--',
                    'ملاحظات': '--',
                  },
                ),
              ],
            ),
          ),
        ),
      );

  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[200],
              child: const Text('K', style: TextStyle(fontSize: 32, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('kerollos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('المجموعة: year1', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Map<String, String> items}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.burgundy)),
            const SizedBox(height: 20),
            ...items.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120, // Fixed width for labels to align values
                    child: Text(entry.key, style: TextStyle(color: Colors.brown, fontSize: 16)),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
