import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'team_model.freezed.dart';
part 'team_model.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

@freezed
@HiveType(typeId: 3)
class TeamModel with _$TeamModel {
  const TeamModel._();

  const factory TeamModel({
    /// Firestore document ID.
    @HiveField(0) required String id,

    /// Team display name (e.g. "فريق مارمرقس").
    @HiveField(1) required String name,

    /// The group/year this team belongs to (e.g. "year1").
    @HiveField(2) required String groupId,

    /// UID of the servant assigned to this team (optional).
    @HiveField(3) String? assignedServantId,

    /// Denormalized servant name for display.
    @HiveField(4) String? assignedServantName,

    @HiveField(5) @Default(false) bool isArchived,

    @HiveField(6) @_TimestampConverter() DateTime? archivedAt,

    @HiveField(7) String? archivedByUserId,

    @HiveField(8) String? archiveReason,

    @HiveField(9) @_TimestampConverter() DateTime? restoredAt,

    @HiveField(10) String? restoredByUserId,

    @HiveField(11) @Default(SyncStatus.synced) SyncStatus syncStatus,
  }) = _TeamModel;

  /// Creates a TeamModel from JSON.
  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory TeamModel.fromMap(Map<String, dynamic> data, String docId) {
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

    return TeamModel.fromJson({
      ...data,
      'id': readString('id') ?? docId,
      'name': readString('name') ?? '',
      'groupId': readString('groupId') ?? '',
      'assignedServantId': readString('assignedServantId'),
      'assignedServantName': readString('assignedServantName'),
    });
  }

  /// Converts to Firestore-compatible map (excludes the doc ID and syncStatus).
  Map<String, dynamic> toMap() {
    return toJson()
      ..remove('id')
      ..remove('syncStatus');
  }

  bool get isActive => !isArchived;

  Team toDomain() {
    return Team(
      id: id,
      name: name,
      groupId: groupId,
      assignedServantId: assignedServantId,
      assignedServantName: assignedServantName,
      isArchived: isArchived,
      archivedAt: archivedAt,
      archivedByUserId: archivedByUserId,
      archiveReason: archiveReason,
      restoredAt: restoredAt,
      restoredByUserId: restoredByUserId,
      syncStatus: syncStatus,
    );
  }

  factory TeamModel.fromDomain(Team team) {
    return TeamModel(
      id: team.id,
      name: team.name,
      groupId: team.groupId,
      assignedServantId: team.assignedServantId,
      assignedServantName: team.assignedServantName,
      isArchived: team.isArchived,
      archivedAt: team.archivedAt,
      archivedByUserId: team.archivedByUserId,
      archiveReason: team.archiveReason,
      restoredAt: team.restoredAt,
      restoredByUserId: team.restoredByUserId,
      syncStatus: team.syncStatus,
    );
  }
}
