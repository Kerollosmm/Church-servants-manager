import 'package:church_managment_system/church_app.dart';
import 'package:church_managment_system/core/di/injection.dart';
import 'package:church_managment_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();
  configureDependencies();

  runApp(const ChurchApp());
}
