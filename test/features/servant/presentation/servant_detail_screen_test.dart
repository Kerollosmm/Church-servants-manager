import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin view hides servant delete action hotfix', (tester) async {
    const actor = AuthUser(
      uid: 'admin-1',
      email: 'admin@test.com',
      name: 'Admin',
      role: UserRole.admin,
      isEmailVerified: true,
    );

    final servant = ServantModel(
      uid: 'servant-1',
      docID: 'servant-1',
      name: 'Servant User',
      role: UserRole.servant,
      phone: '01000000000',
      email: 'servant@test.com',
      imageUrl: null,
      teamName: 'year1',
      fatherOfConfession: 'Fr. Test',
      birthdate: null,
      notes: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ServantDetailScreen(
          args: ServantDetailArgs(actor: actor, servant: servant),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
