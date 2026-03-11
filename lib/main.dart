import 'dart:async';
import 'dart:ui';

import 'package:church_management_system/church_app.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Custom generic error screen for UI build exceptions
      ErrorWidget.builder = (FlutterErrorDetails details) {
        bool isDebug = kDebugMode;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'عذراً، حدث خطأ غير متوقع',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'نعتذر عن هذا الخلل. لقد تم تسجيل الخطأ للعمل على إصلاحه.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    if (isDebug) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          details.exceptionAsString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      };

      try {
        await _initializeFirebase();
        
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

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
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
      
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
