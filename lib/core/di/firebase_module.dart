import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseModule {
  // 100MB cache limit to prevent excessive disk usage on user devices
  static const int _cacheSizeBytes = 100 * 1024 * 1024; // 100MB

  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore {
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: _cacheSizeBytes,
    );
    return firestore;
  }
}
