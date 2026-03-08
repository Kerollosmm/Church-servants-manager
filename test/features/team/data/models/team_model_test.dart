import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromMap tolerates missing optional team fields and primitive drift',
    () {
      final team = TeamModel.fromMap({
        'name': 123,
        'groupId': 'year1',
        'assignedServantId': null,
      }, 'team-1');

      expect(team.id, 'team-1');
      expect(team.name, '123');
      expect(team.groupId, 'year1');
      expect(team.assignedServantId, isNull);
      expect(team.assignedServantName, isNull);
    },
  );
}
