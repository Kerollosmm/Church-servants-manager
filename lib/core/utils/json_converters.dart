import 'package:church_management_system/core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts Firestore Timestamp to/from Dart DateTime.
// ignore: type_annotate_public_apis
class FirestoreTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const FirestoreTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is DateTime) return json;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}

/// Converts Firestore Timestamp to/from a non-nullable Dart DateTime.
// ignore: type_annotate_public_apis
class RequiredFirestoreTimestampConverter
    implements JsonConverter<DateTime, dynamic> {
  const RequiredFirestoreTimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    return const FirestoreTimestampConverter().fromJson(json) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  dynamic toJson(DateTime date) {
    return Timestamp.fromDate(date);
  }
}

/// Converts role string values to/from [UserRole].
class UserRoleJsonConverter implements JsonConverter<UserRole, String?> {
  const UserRoleJsonConverter();

  @override
  UserRole fromJson(String? json) {
    if (json == null) return UserRole.servant;
    switch (json.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'student':
        return UserRole.student;
      case 'servant':
      default:
        return UserRole.servant;
    }
  }

  @override
  String toJson(UserRole role) => role.name;
}
