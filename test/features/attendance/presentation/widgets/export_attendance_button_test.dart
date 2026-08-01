import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression guard for review finding (b): chunk helper must keep groups
  // bounded at the configured size so the export issues at most 20 concurrent
  // Firestore reads per Future.wait batch, never an unbounded burst.
  test('ListChunking.chunk(20) bounds export parallel read groups', () {
    final sessions = List.generate(75, (i) => 'session-$i');
    final groups = sessions.chunk(20);
    expect(groups.length, 4); // ceil(75/20) = 4
    expect(groups[0].length, 20);
    expect(groups[1].length, 20);
    expect(groups[2].length, 20);
    expect(groups[3].length, 15);
    expect([for (final g in groups) ...g], equals(sessions));
  });

  test('empty closedSessions produces no read groups', () {
    expect(<String>[].chunk(20), isEmpty);
  });
}
