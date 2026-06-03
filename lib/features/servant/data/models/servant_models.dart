import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'servant_models.freezed.dart';
part 'servant_models.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;
typedef _RoleConverter = UserRoleJsonConverter;

@freezed
@HiveType(typeId: 2)
class ServantModel with _$ServantModel {
  const ServantModel._();

  const factory ServantModel({
    /// Firebase Auth UID for this servant.
    @HiveField(0) String? uid,

    /// Firestore document ID.
    @HiveField(1) required String docID,

    @HiveField(2) required String name,

    /// Role (defaults to servant)
    @HiveField(3) @_RoleConverter() @Default(UserRole.servant) UserRole role,

    /// Email (may be null for some users)
    @HiveField(4) String? email,

    /// Phone number (optional - may not exist in user docs)
    @HiveField(5) String? phone,

    /// Profile image URL
    @HiveField(6) String? imageUrl,

    /// Team/group name - uses groupId from Users collection
    @HiveField(7) @JsonKey(name: 'groupId') String? teamName,

    /// Email verification status
    @HiveField(8)
    @JsonKey(name: 'isEmailVerified')
    @Default(false)
    bool isEmailVerified,

    /// Father of confession name.
    @HiveField(9)
    @JsonKey(name: 'father_of_confession')
    String? fatherOfConfession,

    /// Birthdate with Timestamp conversion.
    @HiveField(10) @_TimestampConverter() DateTime? birthdate,

    /// Optional notes about the servant.
    @HiveField(11) String? notes,

    @HiveField(12) @Default(false) bool isArchived,

    @HiveField(13) @_TimestampConverter() DateTime? archivedAt,

    @HiveField(14) String? archivedByUserId,

    @HiveField(15) String? archiveReason,

    @HiveField(16) @_TimestampConverter() DateTime? restoredAt,

    @HiveField(17) String? restoredByUserId,

    /// Assigned team/class ID within the servant's group.
    @HiveField(18)
    @Deprecated('Use assignedTeamIds instead')
    String? assignedTeamId,

    /// Multiple assigned team IDs (if applicable).
    @HiveField(19) @Default(<String>[]) List<String> assignedTeamIds,

    /// Aggregated group attendance metrics (for US1 Trend Insights).
    @HiveField(20) Map<String, dynamic>? groupAttendanceSummary,

    @HiveField(21) @Default(SyncStatus.synced) SyncStatus syncStatus,
    @HiveField(22) @_TimestampConverter() DateTime? clientUpdatedAt,

    /// Sectors this servant is authorised to manage (e.g. ['primary_boys', 'youth']).
    /// Used for sector-scoped RBAC in Firestore Security Rules.
    @HiveField(23) @Default(<String>[]) List<String> assignedSectorIds,
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
      'syncStatus': readString('syncStatus') ?? 'synced',
      'assignedSectorIds': (data['assignedSectorIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    });
  }

  /// Converts to Firestore-compatible map.
  Map<String, dynamic> toMap() => toJson();

  List<String> get effectiveAssignedTeamIds {
    final ids = <String>{};
    // Ensure we handle potential null list from legacy data sources
    final list = assignedTeamIds;
    for (final id in list) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) {
        ids.add(trimmed);
      }
    }
    final legacyId = assignedTeamId?.trim();
    if (legacyId != null && legacyId.isNotEmpty) {
      ids.add(legacyId);
    }
    return ids.toList(growable: false);
  }

  bool get isActive => !isArchived;

  Servant toDomain() {
    return Servant(
      uid: uid,
      docID: docID,
      name: name,
      role: role,
      email: email,
      phone: phone,
      imageUrl: imageUrl,
      teamName: teamName,
      isEmailVerified: isEmailVerified,
      fatherOfConfession: fatherOfConfession,
      birthdate: birthdate,
      notes: notes,
      isArchived: isArchived,
      archivedAt: archivedAt,
      archivedByUserId: archivedByUserId,
      archiveReason: archiveReason,
      restoredAt: restoredAt,
      restoredByUserId: restoredByUserId,
      assignedTeamId: assignedTeamId,
      assignedTeamIds: assignedTeamIds,
      groupAttendanceSummary: groupAttendanceSummary,
      syncStatus: syncStatus,
      clientUpdatedAt: clientUpdatedAt,
      assignedSectorIds: assignedSectorIds,
    );
  }

  factory ServantModel.fromDomain(Servant servant) {
    return ServantModel(
      uid: servant.uid,
      docID: servant.docID,
      name: servant.name,
      role: servant.role,
      email: servant.email,
      phone: servant.phone,
      imageUrl: servant.imageUrl,
      teamName: servant.teamName,
      isEmailVerified: servant.isEmailVerified,
      fatherOfConfession: servant.fatherOfConfession,
      birthdate: servant.birthdate,
      notes: servant.notes,
      isArchived: servant.isArchived,
      archivedAt: servant.archivedAt,
      archivedByUserId: servant.archivedByUserId,
      archiveReason: servant.archiveReason,
      restoredAt: servant.restoredAt,
      restoredByUserId: servant.restoredByUserId,
      assignedTeamId: servant.assignedTeamId,
      assignedTeamIds: servant.assignedTeamIds,
      groupAttendanceSummary: servant.groupAttendanceSummary,
      syncStatus: servant.syncStatus,
      clientUpdatedAt: servant.clientUpdatedAt,
      assignedSectorIds: servant.assignedSectorIds,
    );
  }
}

/// Pagination container for servants.
class ServantsPage {
  final List<ServantModel> servants;
  final PaginationCursor? lastDocument;
  final bool hasMore;

  const ServantsPage({
    required this.servants,
    this.lastDocument,
    required this.hasMore,
  });
}
