import 'package:flutter/material.dart';
import 'package:flutterbhz/widgets/MyColors.dart';




class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mycolors.paige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              //const SizedBox(height: 40),

              // اللوجو
              const Center(
                child: Image( image:AssetImage('assets/unnamed.png'),height: 180,width: 180,), // ضع مسار صورتك هنا
                ),

              //const SizedBox(height: 20),
              const Text(
                "مدرسة الكاروز",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Mycolors.burgandy,
                ),
              ),

              const Text(
                "تطبيق إدارة الحضور والغياب",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              //const SizedBox(height: 40),

              // بطاقة أخذ الحضور
              Padding(
                padding: const EdgeInsets.fromLTRB(0,25,0,8),
                child: _buildMenuCard(
                  title: "أخذ الحضور",
                  subtitle: "تسجيل حضور الطلاب لليوم",
                  icon: Icons.fact_check,
                  //iconBgColor: const Color(0xFFFDECEC),
                  iconColor: Colors.white,
                  onpressed: (){
                    Navigator.pushReplacementNamed(context, '/take');
                  },
                ),
              ),

             // const SizedBox(height: 16),

              // بطاقة إضافة طالب
              Padding(
                padding: const EdgeInsets.fromLTRB(0,8,0,8),
                child: _buildMenuCard(
                  title: "إضافة طالب",
                  subtitle: "تسجيل بيانات طالب جديد",
                  icon: Icons.person_add_alt_1,
                  //iconBgColor: const Color(0xFFFEF7EC),
                  iconColor: Colors.white,
                  onpressed: (){
                    Navigator.pushReplacementNamed(context, '/add');
                  },
                ),
              ),

              //const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.fromLTRB(0,8,0,25),
                child: _buildMenuCard(
                  title: "عرض بيانات الطالب",
                  subtitle: "عرض جميع المعلومات عن الطالب ",
                  icon: Icons.person_search,
                  //iconBgColor: const Color(0xFFFEF7EC),
                  iconColor: Colors.white,
                  onpressed: (){
                    Navigator.pushReplacementNamed(context, '/show');
                  },
                ),
              ),

              // قسم الإحصائيات
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildStatCard("٤٥", "طالب مسجل"),
                    const SizedBox(width: 16),
                    _buildStatCard("٩٨٪", "نسبة الحضور", isPercentage: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Mycolors.burgandy,
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // الصفحة الرئيسية
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "الإعدادات"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "السجل"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
        ],
      ),

    );
  }

  //  للبطاقات الكبيرة
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    //required Color iconBgColor,
    required Color iconColor,
    required VoidCallback? onpressed ,
  }) {
    return MaterialButton(
      height: 80,
      onPressed: onpressed,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(



        child: Row(
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.brown)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFAD375), Colors.brown]),

                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }

//  للإحصائيات الصغيرة
  Widget _buildStatCard(String value, String label, {bool isPercentage = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(

          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.brown),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isPercentage ? Colors.green : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

}