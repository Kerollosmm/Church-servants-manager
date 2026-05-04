import 'dart:convert';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:hive/hive.dart';

class AuthUserLocalStore {
  static const String _boxName = 'auth_user_box';
  static const String _userKey = 'current_user';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> saveUser(AuthUser user) async {
    final box = Hive.box(_boxName);
    await box.put(_userKey, jsonEncode(user.toJson()));
  }

  AuthUser? getUser() {
    final box = Hive.box(_boxName);
    final data = box.get(_userKey);
    if (data == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(data as String));
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    final box = Hive.box(_boxName);
    await box.delete(_userKey);
  }
}
