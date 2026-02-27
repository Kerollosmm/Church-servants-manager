import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_managment_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTeamCubit extends MockCubit<TeamState> implements TeamCubit {}

void main() {
  late MockTeamCubit mockTeamCubit;

  setUp(() {
    mockTeamCubit = MockTeamCubit();
    // Default mock for loadTeamsByGroup so it doesn't throw when called in initState
    when(
      () => mockTeamCubit.loadTeamsByGroup(
        any(),
        defaultTeamId: any(named: 'defaultTeamId'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTeamCubit.loadAllTeams()).thenAnswer((_) async {});
  });

  tearDown(() {
    mockTeamCubit.close();
  });

  group('TeamDropdown Widget Tests', () {
    final tTeam1 = TeamModel(
      id: 'team_1',
      name: 'Alpha Team',
      groupId: 'year1',
    );
    final tTeam2 = TeamModel(id: 'team_2', name: 'Beta Team', groupId: 'year1');

    testWidgets('shows loading interface initially', (tester) async {
      when(() => mockTeamCubit.state).thenReturn(const TeamLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TeamCubit>.value(
              value: mockTeamCubit,
              child: TeamDropdown(groupId: 'year1', onChanged: (_) {}),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders teams and allows selection', (tester) async {
      when(
        () => mockTeamCubit.state,
      ).thenReturn(TeamLoaded(teams: [tTeam1, tTeam2]));

      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TeamCubit>.value(
              value: mockTeamCubit,
              child: TeamDropdown(
                groupId: 'year1',
                onChanged: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dropdown hint text or actual text
      expect(find.text('Team'), findsWidgets);

      // Tap Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      // Options should be visible
      expect(find.text('Alpha Team').last, findsOneWidget);
      expect(find.text('Beta Team').last, findsOneWidget);

      // Select Beta
      await tester.tap(find.text('Beta Team').last);
      await tester.pumpAndSettle();

      expect(selectedValue, 'team_2');
    });

    testWidgets('shows All Teams option when showAllOption is true', (
      tester,
    ) async {
      when(() => mockTeamCubit.state).thenReturn(TeamLoaded(teams: [tTeam1]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TeamCubit>.value(
              value: mockTeamCubit,
              child: TeamDropdown(
                groupId: 'year1',
                showAllOption: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      expect(find.text('All Teams'), findsWidgets);
    });

    testWidgets('properly restricts to single team using restrictToTeamId', (
      tester,
    ) async {
      when(
        () => mockTeamCubit.state,
      ).thenReturn(TeamLoaded(teams: [tTeam1, tTeam2]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TeamCubit>.value(
              value: mockTeamCubit,
              child: TeamDropdown(
                groupId: 'year1',
                restrictToTeamId: 'team_2',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Beta Team'), findsWidgets);
      // Attempting to find Alpha Team should yield nothing except maybe nowhere
      expect(find.text('Alpha Team'), findsNothing);
    });

    testWidgets('calls loadAllTeams when groupId is null', (tester) async {
      when(
        () => mockTeamCubit.state,
      ).thenReturn(TeamLoaded(teams: [tTeam1, tTeam2]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TeamCubit>.value(
              value: mockTeamCubit,
              child: TeamDropdown(onChanged: (_) {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(() => mockTeamCubit.loadAllTeams()).called(1);

      // Tap Dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Team').last, findsOneWidget);
    });
  });
}
