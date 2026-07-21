import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for teams.
///
/// Provides a fast, offline-first cache for team data.
/// Currently does not use a sync queue because offline team mutations
/// are blocked to prevent conflict issues.
class TeamLocalDatasource {
  static const String boxName = 'teams_cache_box';

  Box<TeamModel>? _teamsBox;

  Future<void> init() async {
    _teamsBox ??= await Hive.openBox<TeamModel>(
      boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
  }

  // ---- Cache Operations ----

  Future<void> cacheTeam(TeamModel team) async {
    await init();
    await _teamsBox!.put(team.id, team);
  }

  Future<void> cacheTeams(List<TeamModel> teams) async {
    await init();
    final entries = <String, TeamModel>{for (final t in teams) t.id: t};
    await _teamsBox!.putAll(entries);
  }

  Future<TeamModel?> getCachedTeamById(String id) async {
    await init();
    return _teamsBox!.get(id);
  }

  Future<List<TeamModel>> getCachedTeamsByIds(List<String> ids) async {
    await init();
    final result = <TeamModel>[];
    for (final id in ids) {
      final team = _teamsBox!.get(id);
      if (team != null) {
        result.add(team);
      }
    }
    return result;
  }

  /// Returns all cached teams, optionally filtering out archived ones.
  Future<List<TeamModel>> getCachedTeams({bool includeArchived = false}) async {
    await init();
    final all = _teamsBox!.values;
    if (includeArchived) return all.toList();
    return all.where((t) => !t.isArchived).toList();
  }

  /// Returns cached teams filtered by groupId.
  Future<List<TeamModel>> getCachedTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) async {
    await init();
    return _teamsBox!.values
        .where(
          (t) => t.groupId == groupId && (includeArchived || !t.isArchived),
        )
        .toList();
  }

  Future<void> removeCachedTeam(String id) async {
    await init();
    await _teamsBox!.delete(id);
  }
}
