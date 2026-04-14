import 'dart:async';
import 'dart:ui';

import 'package:church_management_system/church_app.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        Zone.current.handleUncaughtError(error, stack);
        return true;
      };

      try {
        await _initializeFirebase();
        GoogleFonts.config.allowRuntimeFetching = false;

        // Configure Firestore settings before DI registration
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 100 * 1024 * 1024,
        );

        configureDependencies();
        runApp(const ChurchApp());
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('Startup initialization failed (${error.runtimeType})');
          debugPrintStack(stackTrace: stack);
        }
        runApp(_StartupFailureApp(error: error));
      }
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught application error (${error.runtimeType})');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}

class _StartupFailureApp extends StatelessWidget {
  final Object error;

  const _StartupFailureApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.error_outline,
                  size: 64,

                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ أثناء تشغيل التطبيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'يرجى إعادة تشغيل التطبيق والمحاولة مرة أخرى.\nإذا استمرت المشكلة تواصل مع الدعم الفني.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
