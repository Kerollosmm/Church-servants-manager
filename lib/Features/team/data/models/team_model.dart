import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'team_model.freezed.dart';
part 'team_model.g.dart';

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
  }) = _TeamModel;

  /// Creates a TeamModel from JSON.
  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  /// Convenience factory for Firestore documents with separate docId.
  factory TeamModel.fromMap(Map<String, dynamic> data, String docId) {
    return TeamModel.fromJson({...data, 'id': docId});
  }

  /// Converts to Firestore-compatible map (excludes the doc ID).
  Map<String, dynamic> toMap() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
