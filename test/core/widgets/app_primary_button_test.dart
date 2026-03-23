import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/core/widgets/atoms/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders label text', (tester) async {
    await tester.pumpWidget(
      buildSubject(const AppPrimaryButton(label: 'Continue')),
    );

    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      buildSubject(
        AppPrimaryButton(label: 'Submit', onPressed: () => tapped = true),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows loader when busy', (tester) async {
    await tester.pumpWidget(
      buildSubject(const AppPrimaryButton(label: 'Submit', isLoading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });
}
