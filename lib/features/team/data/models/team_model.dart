import 'package:church_management_system/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

// ignore_for_file: invalid_annotation_target

part 'team_model.freezed.dart';
part 'team_model.g.dart';

typedef _TimestampConverter = FirestoreTimestampConverter;

enum SyncStatus { pending, synced, failed }

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 10;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return SyncStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeByte(obj.index);
  }
}

@freezed
class TeamModel with _$TeamModel {
  const TeamModel._();

  const factory TeamModel({
    /// Firestore document ID.
    required String id,

    /// Team display name (e.g. "فريق مارمرقس").
    required String name,

    /// The group/year this team belongs to (e.g. "year1").
    required String groupId,

    /// UID of the servant assigned to this team (optional).
    String? assignedServantId,

    /// Denormalized servant name for display.
    String? assignedServantName,

    @Default(false) bool isArchived,

    @_TimestampConverter() DateTime? archivedAt,

    String? archivedByUserId,

    String? archiveReason,

    @_TimestampConverter() DateTime? restoredAt,

    String? restoredByUserId,

    @Default(SyncStatus.synced) @HiveField(10) SyncStatus syncStatus,
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
    final json = toJson();
    json.remove('id');
    json.remove('syncStatus');
    return json;
  }

  bool get isActive => !isArchived;
}
