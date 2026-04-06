import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'servant_models.freezed.dart';
part 'servant_models.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;
typedef _RoleConverter = UserRoleJsonConverter;

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

    @Default(false) bool isArchived,

    @_TimestampConverter() DateTime? archivedAt,

    String? archivedByUserId,

    String? archiveReason,

    @_TimestampConverter() DateTime? restoredAt,

    String? restoredByUserId,

    /// Assigned team/class ID within the servant's group.
    String? assignedTeamId,

    /// Multiple assigned team IDs (if applicable).
    List<String>? assignedTeamIds,
  }) = _ServantModel;

  /// Creates a ServantModel from JSON.
  factory ServantModel.fromJson(Map<String, dynamic> json) =>
      _$ServantModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory ServantModel.fromMap(Map<String, dynamic> data, String docId) {
    String? readString(String key) {
      final value = data[key];
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    bool readBool(String key, {bool fallback = false}) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return fallback;
    }

    return ServantModel.fromJson({
      ...data,
      'uid': readString('uid'),
      'docID': readString('docID') ?? docId,
      'name': readString('name') ?? '',
      'role': readString('role') ?? UserRole.servant.name,
      'email': readString('email'),
      'phone': readString('phone'),
      'imageUrl': readString('imageUrl'),
      'groupId': readString('groupId'),
      'isEmailVerified': readBool('isEmailVerified'),
      'father_of_confession': readString('father_of_confession'),
      'notes': readString('notes'),
      'assignedTeamId': readString('assignedTeamId'),
    });
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();

  bool get isActive => !isArchived;
}
