import 'dart:convert';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:hive/hive.dart';

class TeamLocalDatasource {
  static const String _boxName = 'teams_cache';
  static const String _syncQueueBox = 'teams_sync_queue';

  Future<void> init() async {
    await Hive.openBox(_boxName);
    await Hive.openBox(_syncQueueBox);
  }

  Box<String> get _box => Hive.box(_boxName);
  Box<String> get _syncQueue => Hive.box(_syncQueueBox);

  Future<void> saveTeam(TeamModel team) async {
    final key = team.id;
    await _box.put(key, jsonEncode(team.toJson()));
  }

  Future<void> saveTeams(List<TeamModel> teams) async {
    final entries = {
      for (final team in teams) team.id: jsonEncode(team.toJson()),
    };
    await _box.putAll(entries);
  }

  TeamModel? getTeam(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    try {
      return TeamModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  List<TeamModel> getCachedTeams({bool includeArchived = false}) {
    final teams = <TeamModel>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data == null) continue;
      try {
        final team = TeamModel.fromJson(jsonDecode(data));
        if (!includeArchived && team.isArchived) continue;
        teams.add(team);
      } catch (_) {
        continue;
      }
    }
    teams.sort((a, b) {
      final groupCompare = a.groupId.compareTo(b.groupId);
      if (groupCompare != 0) return groupCompare;
      return a.name.compareTo(b.name);
    });
    return teams;
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
    await _syncQueue.put(key, jsonEncode(team.toJson()));
  }

  List<TeamModel> getPendingSyncQueue() {
    final teams = <TeamModel>[];
    for (final key in _syncQueue.keys) {
      final data = _syncQueue.get(key);
      if (data == null) continue;
      try {
        teams.add(TeamModel.fromJson(jsonDecode(data)));
      } catch (_) {
        continue;
      }
    }
    return teams;
  }

  Future<void> removeFromSyncQueue(String id) async {
    await _syncQueue.delete(id);
  }

  Future<void> clearSyncQueue() async {
    await _syncQueue.clear();
  }
}
