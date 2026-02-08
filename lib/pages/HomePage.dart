import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: MyColors.paige,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Image(image: AssetImage('assets/unnamed.png'), height: 180, width: 180),
                ),
                const Text(
                  "مدرسة الكاروز",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: MyColors.burgundy),
                ),
                const Text(
                  "تطبيق إدارة الحضور والغياب",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                _buildMenuCard(
                  context,
                  title: "أخذ الحضور",
                  subtitle: "تسجيل حضور الطلاب لليوم",
                  icon: Icons.fact_check,
                  onPressed: () => Navigator.pushNamed(context, '/take'),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: "إضافة طالب",
                  subtitle: "تسجيل بيانات طالب جديد",
                  icon: Icons.person_add_alt_1,
                  onPressed: () => Navigator.pushNamed(context, '/add'),
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: "عرض بيانات الطالب",
                  subtitle: "عرض جميع المعلومات عن الطالب",
                  icon: Icons.person_search,
                  onPressed: () => Navigator.pushNamed(context, '/show'),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    _buildStatCard("٤٥", "طالب مسجل"),
                    const SizedBox(width: 16),
                    _buildStatCard("٩٨٪", "نسبة الحضور", isPercentage: true),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: MyColors.burgundy,
          unselectedItemColor: Colors.grey,
          currentIndex: 2,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "الإعدادات"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "السجل"),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [MyColors.ocur, Colors.brown]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {bool isPercentage = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.brown.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isPercentage ? Colors.green : Colors.black)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
