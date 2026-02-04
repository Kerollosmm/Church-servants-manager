import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutterbhz/pages/Add_StudentPage.dart';
import 'package:flutterbhz/pages/Auth/Login_page.dart';
import 'package:flutterbhz/pages/Auth/SignIn_page.dart';
import 'package:flutterbhz/pages/HomePage.dart';
import 'package:flutterbhz/pages/Show_DataPage.dart';
import 'package:flutterbhz/pages/Take_attendance.dart';
import 'package:flutterbhz/widgets/MyColors.dart';


void main() {
  runApp( const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
        routes: {
          '/login': (context) => const Login(),
          '/home': (context) => const HomePage(),
          '/take': (context) => const AttendancePage(),
          '/add': (context) => const AddStudentPage(),
          '/show': (context) => const ShowDataPage(),
          '/signIn': (context) => const SignInPage(),


        },
      debugShowCheckedModeBanner: false,
      home:AnimatedSplashScreen(
           duration: 100,
          backgroundColor: Mycolors.paige,
          splashIconSize: 300,
          centered: true,
          splash: "assets/unnamed.png",
          nextScreen: const Login())
    );
  }
}
