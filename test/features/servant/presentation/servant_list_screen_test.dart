import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockServantDataCubit extends MockCubit<ServantDataState>
    implements ServantDataCubit {}

void main() {
  const admin = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(const AuthEventCheckStatus());
    registerFallbackValue(admin);
  });

  testWidgets(
    'keeps previously loaded list visible during operation success state',
    (tester) async {
      final authBloc = MockAuthBloc();
      final servantCubit = MockServantDataCubit();

      final servant = ServantModel(
        uid: 'servant-1',
        docID: 'doc-1',
        name: 'Test Servant',
        phone: '01234567890',
        email: 'servant@test.com',
        imageUrl: null,
        role: UserRole.servant,
        teamName: 'year1',
        fatherOfConfession: 'Fr. Test',
        birthdate: null,
        notes: null,
      );

      final loaded = ServantDataLoaded(servants: [servant]);
      const success = ServantDataOperationSuccess(
        'Servant updated successfully',
      );

      when(() => authBloc.state).thenReturn(const AuthAuthenticated(admin));
      whenListen(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(admin),
      );

      when(() => servantCubit.state).thenReturn(loaded);
      whenListen(
        servantCubit,
        Stream<ServantDataState>.fromIterable([success]),
        initialState: loaded,
      );

      when(
        () => servantCubit.loadServants(actor: any(named: 'actor')),
      ).thenAnswer((_) async {});
      when(
        () => servantCubit.searchServants(
          actor: any(named: 'actor'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => servantCubit.refreshServants(actor: any(named: 'actor')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ServantDataCubit>.value(value: servantCubit),
          ],
          child: const MaterialApp(home: ServantListScreen()),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Test Servant'), findsOneWidget);
      expect(find.text('Servant updated successfully'), findsOneWidget);
    },
  );
}
