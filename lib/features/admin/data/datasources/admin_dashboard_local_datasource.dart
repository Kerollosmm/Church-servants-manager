import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:hive/hive.dart';

/// Hive-backed local storage for [DashboardKpiData].
///
/// Caches the dashboard aggregate data (KPI counts & attendance rate)
/// as a simple Map to avoid requiring code generation/adapters.
class AdminDashboardLocalDatasource {
  static const String boxName = 'admin_dashboard_box';
  static const String kpiKey = 'kpi_data';

  late final Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(
      boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
    _initialized = true;
  }

  /// Returns the cached dashboard KPI data, or `null` if none exists.
  Future<DashboardKpiData?> getKpiData() async {
    await init();
    final map = _box.get(kpiKey);
    if (map is! Map) return null;
    try {
      return DashboardKpiData(
        totalStudents: map['totalStudents'] as int? ?? 0,
        totalServants: map['totalServants'] as int? ?? 0,
        totalTeams: map['totalTeams'] as int? ?? 0,
        totalSessions: map['totalSessions'] as int? ?? 0,
        totalPresent: map['totalPresent'] as int? ?? 0,
        attendanceRate: (map['attendanceRate'] as num? ?? 0.0).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Caches the dashboard KPI data.
  Future<void> saveKpiData(DashboardKpiData data) async {
    await init();
    await _box.put(kpiKey, {
      'totalStudents': data.totalStudents,
      'totalServants': data.totalServants,
      'totalTeams': data.totalTeams,
      'totalSessions': data.totalSessions,
      'totalPresent': data.totalPresent,
      'attendanceRate': data.attendanceRate,
    });
  }

  /// Clears all cached dashboard data.
  Future<void> clearAll() async {
    await init();
    await _box.clear();
  }
}
