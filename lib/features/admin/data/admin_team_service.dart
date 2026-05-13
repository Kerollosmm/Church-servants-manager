import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-only operations that touch multiple collections.
///
/// Feature: Teams
/// - Admin assigns a servant responsible for a team.
/// - Admin assigns/removes students to/from a team.
///
/// NOTE: Permissions must be enforced by Firestore Security Rules.
class AdminTeamService {
  final FirebaseFirestore _firestore;
  final AdminTeamMembershipService _membershipService;

  AdminTeamService({
    FirebaseFirestore? firestore,
    AdminTeamMembershipService? membershipService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _membershipService =
           membershipService ??
           AdminTeamMembershipService(firestore: firestore);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(FirestoreCollections.classes);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.servants);
  DocumentReference<Map<String, dynamic>> _teamRef(String teamId) =>
      _classes.doc(teamId);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _users.doc(userId);

  void _assertAdmin(AuthUser actor) {
    if (actor.role != UserRole.admin) {
      throw StateError('Permission denied: admin only');
    }
  }

  void _validateServantForTeam({
    required TeamModel team,
    required String servantDocId,
    required Map<String, dynamic> servantData,
  }) {
    if (team.isArchived) {
      throw StateError('Cannot assign a servant to an archived team');
    }

    final role = (servantData['role'] as String?)?.trim().toLowerCase();
    if (role != UserRole.servant.name) {
      throw StateError('Selected user is not a servant');
    }

    final isArchived = servantData['isArchived'] == true;
    if (isArchived) {
      throw StateError('Selected servant is archived');
    }

    final groupId = (servantData['groupId'] as String?)?.trim();
    if (groupId == null || groupId.isEmpty) {
      throw StateError(
        'Selected servant ($servantDocId) is missing group assignment',
      );
    }
    if (groupId != team.groupId) {
      throw StateError(
        'Cannot assign servant from group "$groupId" to team group "${team.groupId}"',
      );
    }
  }

  List<String> _extractAssignedTeamIds(Map<String, dynamic> data) {
    final ids = <String>[];

    final assignedTeamIds = data['assignedTeamIds'];
    if (assignedTeamIds is Iterable) {
      for (final value in assignedTeamIds) {
        if (value is! String) continue;
        final id = value.trim();
        if (id.isEmpty || ids.contains(id)) continue;
        ids.add(id);
      }
    }

    return ids;
  }

  Map<String, dynamic> _servantAssignmentPatch(List<String> teamIds) {
    if (teamIds.isEmpty) {
      return {
        'assignedTeamIds': FieldValue.delete(),
        'assignedTeamId': FieldValue.delete(), // Cleanup legacy field
        'requiresTokenRefresh': true, // Trigger reactive sync
        'updatedAt': FieldValue.serverTimestamp(),
      };
    }
    return {
      'assignedTeamIds': teamIds,
      'assignedTeamId': FieldValue.delete(), // Cleanup legacy field
      'requiresTokenRefresh': true, // Trigger reactive sync
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Assign [servant] as the responsible servant for [team].
  ///
  /// Updates:
  /// - Classes/{teamId}: assignedServantId + assignedServantName
  /// - Users/{servantDocId}: assignedTeamIds (+ legacy assignedTeamId)
  /// - If the team had a previous servant, removes this team from their list.
  Future<void> assignServantToTeam({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) async {
    _assertAdmin(actor);

    final teamRef = _teamRef(team.id);
    final newServantRef = _userRef(servant.docID);

    await _firestore.runTransaction((transaction) async {
      // 1. Perform all reads
      final teamSnap = await transaction.get(teamRef);
      if (!teamSnap.exists) {
        throw StateError('Team not found');
      }

      final teamData = teamSnap.data() ?? <String, dynamic>{};
      final oldServantId = (teamData['assignedServantId'] as String?)?.trim();
      final oldServantRef = oldServantId == null || oldServantId.isEmpty
          ? null
          : _userRef(oldServantId);

      final newServantSnap = await transaction.get(newServantRef);
      final newServantData = newServantSnap.data();
      if (!newServantSnap.exists || newServantData == null) {
        throw StateError('Servant not found');
      }

      DocumentSnapshot<Map<String, dynamic>>? oldServantSnap;
      if (oldServantRef != null && oldServantId != servant.docID) {
        oldServantSnap = await transaction.get(oldServantRef);
      }

      // 2. Perform validations
      _validateServantForTeam(
        team: team,
        servantDocId: servant.docID,
        servantData: newServantData,
      );

      final newServantTeamIds = _extractAssignedTeamIds(newServantData);
      if (!newServantTeamIds.contains(team.id)) {
        newServantTeamIds.add(team.id);
      }

      // 3. Perform all writes
      transaction.update(teamRef, {
        'assignedServantId': servant.docID,
        'assignedServantName':
            (newServantData['name'] as String?) ?? servant.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldServantSnap != null && oldServantSnap.exists) {
        final teamIds = _extractAssignedTeamIds(
          oldServantSnap.data() ?? <String, dynamic>{},
        )..removeWhere((id) => id == team.id);
        transaction.set(
          oldServantSnap.reference,
          _servantAssignmentPatch(teamIds),
          SetOptions(merge: true),
        );
      }

      transaction.set(newServantRef, {
        ..._servantAssignmentPatch(newServantTeamIds),
        'groupId': team.groupId,
      }, SetOptions(merge: true));
    });
  }

  /// Remove any responsible servant from [team] and removes this team from that servant's assignment list.
  Future<void> unassignServantFromTeam({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    _assertAdmin(actor);

    final teamRef = _teamRef(team.id);

    await _firestore.runTransaction((transaction) async {
      // 1. Perform all reads
      final teamSnap = await transaction.get(teamRef);
      if (!teamSnap.exists) {
        throw StateError('Team not found');
      }

      final data = teamSnap.data() ?? <String, dynamic>{};
      final oldServantId = (data['assignedServantId'] as String?)?.trim();
      final oldServantRef = oldServantId == null || oldServantId.isEmpty
          ? null
          : _userRef(oldServantId);

      DocumentSnapshot<Map<String, dynamic>>? oldServantSnap;
      if (oldServantRef != null) {
        oldServantSnap = await transaction.get(oldServantRef);
      }

      // 2. Perform all writes
      transaction.update(teamRef, {
        'assignedServantId': FieldValue.delete(),
        'assignedServantName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldServantSnap != null && oldServantSnap.exists) {
        final teamIds = _extractAssignedTeamIds(
          oldServantSnap.data() ?? <String, dynamic>{},
        )..removeWhere((id) => id == team.id);
        transaction.set(
          oldServantSnap.reference,
          _servantAssignmentPatch(teamIds),
          SetOptions(merge: true),
        );
      }
    });
  }

  /// Set the exact list of students that belong to [team].
  ///
  /// - Students selected => classId = team.id, team_name = team.name
  /// - Students removed  => classId deleted, team_name cleared
  ///
  /// Also maintains Classes/{teamId}.student_ids array (best-effort).
  Future<void> setStudentsForTeam({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> selectedStudents,
  }) async {
    if (team.isArchived) {
      throw StateError('Cannot manage members for an archived team');
    }

    await _membershipService.setStudentsForTeam(
      actor: actor,
      team: team,
      selectedStudents: selectedStudents,
    );
  }
}
