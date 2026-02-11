import 'package:church_managment_system/core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'servant_models.freezed.dart';
part 'servant_models.g.dart';

/// Converts Firestore Timestamp to/from Dart DateTime.
class _TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const _TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
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

/// Converts role string to UserRole enum.
class _RoleConverter implements JsonConverter<UserRole, String?> {
  const _RoleConverter();

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

@freezed
class ServantModel with _$ServantModel {
  const ServantModel._();

  const factory ServantModel({
    /// Firebase Auth UID for this servant.
    String? uid,

    /// Firestore document ID.
    required String docID,

    required String name,

    /// Role (defaults to servant)
    @_RoleConverter() @Default(UserRole.servant) UserRole role,

    /// Email (may be null for some users)
    String? email,

    /// Phone number (optional - may not exist in user docs)
    String? phone,

    /// Profile image URL
    String? imageUrl,

    /// Team/group name - uses groupId from Users collection
    @JsonKey(name: 'groupId') String? teamName,

    /// Email verification status
    @JsonKey(name: 'isEmailVerified') @Default(false) bool isEmailVerified,

    /// Father of confession name.
    @JsonKey(name: 'father_of_confession') String? fatherOfConfession,

    /// Birthdate with Timestamp conversion.
    @_TimestampConverter() DateTime? birthdate,

    /// Optional notes about the servant.
    String? notes,

    /// Assigned team/class ID within the servant's group.
    String? assignedTeamId,
  }) = _ServantModel;

  /// Creates a ServantModel from JSON.
  factory ServantModel.fromJson(Map<String, dynamic> json) =>
      _$ServantModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory ServantModel.fromMap(Map<String, dynamic> data, String docId) {
    return ServantModel.fromJson({...data, 'docID': docId});
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();
}
