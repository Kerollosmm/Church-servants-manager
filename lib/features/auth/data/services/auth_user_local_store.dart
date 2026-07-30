import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class AuthUserLocalStore {
  static const String _boxName = 'auth_user_box';
  static const String _userKey = 'current_user';
  static const _androidOptions = AndroidOptions(
    // ignore: deprecated_member_use
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _secureStorage;

  AuthUserLocalStore({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );

  Future<void> init() async {
    try {
      final containsKey = await _secureStorage.containsKey(
        key: 'hive_encryption_key',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      Uint8List encryptionKey;
      if (!containsKey) {
        final key = Hive.generateSecureKey();
        await _secureStorage.write(
          key: 'hive_encryption_key',
          value: base64UrlEncode(key),
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        encryptionKey = Uint8List.fromList(key);
      } else {
        final base64Key = await _secureStorage.read(
          key: 'hive_encryption_key',
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        );
        if (base64Key == null) {
          throw StateError(
            'Hive encryption key not found in secure storage despite containsKey returning true.',
          );
        }
        encryptionKey = base64Url.decode(base64Key);
      }

      try {
        await Hive.openBox(
          _boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
          compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
        );
      } catch (boxError, boxStackTrace) {
        developer.log(
          'Encrypted Hive box corrupted or unreadable. Evicting box.',
          error: boxError,
          stackTrace: boxStackTrace,
          name: 'AuthUserLocalStore',
        );
        // Safe eviction: delete potentially corrupted or plaintext box from disk
        await Hive.deleteBoxFromDisk(_boxName);
        await Hive.openBox(
          _boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
          compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize AuthUserLocalStore secure key storage',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthUserLocalStore',
      );
      // If secure storage or generation fails completely, open box as plaintext or rethrow.
      // To preserve safety and avoid lockouts, rethrow and let auth flow redirect to Login/Error.
      rethrow;
    }
  }

  Future<void> saveUser(AuthUser user) async {
    final box = Hive.box(_boxName);
    await box.put(
      _userKey,
      jsonEncode(AuthUserModel.fromDomain(user).toJson()),
    );
  }

  AuthUser? getUser() {
    final box = Hive.box(_boxName);
    final data = box.get(_userKey);
    if (data == null) return null;
    try {
      return AuthUserModel.fromJson(jsonDecode(data as String)).toDomain();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to deserialize cached user JSON',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthUserLocalStore',
      );
      return null;
    }
  }

  Future<void> deleteUser() async {
    final box = Hive.box(_boxName);
    await box.delete(_userKey);
  }
}
