import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutterbhz/pages/Add_StudentPage.dart';
import 'package:flutterbhz/pages/Auth/Login_page.dart';
import 'package:flutterbhz/pages/HomePage.dart';
import 'package:flutterbhz/pages/Show_DataPage.dart';
import 'package:flutterbhz/pages/Take_attendance.dart';
import 'package:flutterbhz/widgets/MyColors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدرسة الكاروز',
      initialRoute: '/',
      routes: {
        '/': (context) => AnimatedSplashScreen(
              duration: 2000,
              backgroundColor: MyColors.paige,
              splashIconSize: 500,
              centered: true,
              splash: "assets/unnamed.png",
              nextScreen: const Login(),
            ),
        '/login': (context) => const Login(),
        '/home': (context) => const HomePage(),
        '/take': (context) => const AttendancePage(),
        '/add': (context) => const AddStudentPage(),
        '/show': (context) => const ShowDataPage(),
      },

    );
  }
}
