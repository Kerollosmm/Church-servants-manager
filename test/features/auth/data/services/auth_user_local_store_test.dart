import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  bool throwsException = false;
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwsException) throw Exception('Secure Storage Error');
    return _storage.containsKey(key);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwsException) throw Exception('Secure Storage Write Error');
    if (value != null) _storage[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwsException) throw Exception('Secure Storage Read Error');
    return _storage[key];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthUserLocalStore Security Tests', () {
    test('rethrows exception on secure storage failure without opening unencrypted storage', () async {
      final mockStorage = MockFlutterSecureStorage();
      mockStorage.throwsException = true;

      final store = AuthUserLocalStore(secureStorage: mockStorage);

      expect(store.init, throwsA(isA<Exception>()));
    });
  });
}
