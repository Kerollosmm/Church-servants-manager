import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap tolerates missing optional servant fields and bool drift', () {
    final servant = ServantModel.fromMap({
      'uid': 42,
      'name': 'Servant One',
      'isEmailVerified': 'true',
      'groupId': 'year2',
    }, 'servant-1');

    expect(servant.docID, 'servant-1');
    expect(servant.uid, '42');
    expect(servant.name, 'Servant One');
    expect(servant.role, UserRole.servant);
    expect(servant.isEmailVerified, isTrue);
    expect(servant.teamName, 'year2');
    expect(servant.email, isNull);
    expect(servant.phone, isNull);
    expect(servant.assignedTeamId, isNull);
  });
}
