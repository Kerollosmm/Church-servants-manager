import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:church_management_system/church_app.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> _initializeFirebase() async {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // For unsupported platforms like Windows/Linux in standard Firebase setup
    await Firebase.initializeApp();
  }
}

void _registerHiveAdapters() {
  Hive
    ..registerAdapter(UserRoleAdapter())
    ..registerAdapter(AttendanceStatusAdapter())
    ..registerAdapter(EducationStageAdapter())
    ..registerAdapter(SyncStatusAdapter())
    ..registerAdapter(GroupAdapter())
    ..registerAdapter(StudentModelAdapter())
    ..registerAdapter(ServantModelAdapter())
    ..registerAdapter(TeamModelAdapter());
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Mandate: Initialize Hive for offline-first storage
      await Hive.initFlutter();
      _registerHiveAdapters();

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
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 100 * 1024 * 1024,
        );
        GoogleFonts.config.allowRuntimeFetching = false;
        configureDependencies();

        // Initialize Local Auth Store
        await getIt<AuthUserLocalStore>().init();

        runApp(const ChurchApp());
      } catch (error, stack) {
        developer.log(
          'Startup initialization failed (${error.runtimeType})',
          error: error,
          stackTrace: stack,
          name: 'Main',
        );
        runApp(_StartupFailureApp(error: error));
      }
    },
    (error, stack) {
      developer.log(
        'Uncaught application error (${error.runtimeType})',
        error: error,
        stackTrace: stack,
        name: 'Main',
      );
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
