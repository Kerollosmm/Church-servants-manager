import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:hive/hive.dart';

class TeamLocalDatasource {
  static const String _boxName = 'teams_cache';
  static const String _syncQueueBox = 'teams_sync_queue';

  Future<void> init() async {
    await Hive.openBox<TeamModel>(_boxName);
    await Hive.openBox<TeamModel>(_syncQueueBox);
  }

  Box<TeamModel> get _box => Hive.box<TeamModel>(_boxName);
  Box<TeamModel> get _syncQueue => Hive.box<TeamModel>(_syncQueueBox);

  Future<void> saveTeam(TeamModel team) async {
    final key = team.id;
    await _box.put(key, team);
  }

  Future<void> saveTeams(List<TeamModel> teams) async {
    final entries = {for (final team in teams) team.id: team};
    await _box.putAll(entries);
  }

  TeamModel? getTeam(String id) {
    return _box.get(id);
  }

  List<TeamModel> getCachedTeams({bool includeArchived = false}) {
    return _box.values
        .where((team) => includeArchived || !team.isArchived)
        .toList()
      ..sort((a, b) {
        final groupCompare = a.groupId.compareTo(b.groupId);
        if (groupCompare != 0) return groupCompare;
        return a.name.compareTo(b.name);
      });
  }

  List<TeamModel> getCachedTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) {
    return getCachedTeams(
      includeArchived: includeArchived,
    ).where((t) => t.groupId == groupId).toList();
  }

  Future<void> deleteTeam(String id) async {
    await _box.delete(id);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }

  Future<void> queueForSync(TeamModel team) async {
    final key = team.id;
    await _syncQueue.put(key, team);
  }

  List<TeamModel> getPendingSyncQueue() {
    return _syncQueue.values.toList();
  }

  Future<void> removeFromSyncQueue(String id) async {
    await _syncQueue.delete(id);
  }

  Future<void> clearSyncQueue() async {
    await _syncQueue.clear();
  }
}
