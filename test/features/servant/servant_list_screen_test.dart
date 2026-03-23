import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_list_screen.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockServantDataRepository extends Mock implements ServantDataRepository {}

class MockAdminUserProvisioningService extends Mock
    implements AdminUserProvisioningService {}

void main() {
  late MockAuthBloc authBloc;
  late ServantDataCubit servantDataCubit;
  late MockServantDataRepository repository;
  late MockAdminUserProvisioningService adminUserProvisioningService;

  final adminUser = AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
  );

  setUpAll(() {
    registerFallbackValue(adminUser);
  });

  setUp(() {
    authBloc = MockAuthBloc();
    repository = MockServantDataRepository();
    adminUserProvisioningService = MockAdminUserProvisioningService();

    servantDataCubit = ServantDataCubit(
      repository: repository,
      adminUserProvisioningService: adminUserProvisioningService,
    );

    when(
      () => repository.getServantsPage(
        limit: any(named: 'limit'),
        lastDocument: any(named: 'lastDocument'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer(
      (_) async =>
          const ServantsPage(servants: [], lastDocument: null, hasMore: false),
    );

    when(() => authBloc.state).thenReturn(AuthAuthenticated(adminUser));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.close()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ServantDataCubit>.value(value: servantDataCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ServantListScreen(),
      ),
    );
  }

  testWidgets('ServantListScreen renders searching area', (tester) async {
    await tester.pumpWidget(buildSubject());
    // Since it's loading, it might show a progress indicator or empty state
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('البحث عن خادم'), findsOneWidget);
  });
}
