import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/core/widgets/atoms/app_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(GlobalKey<FormState> formKey) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Form(
          key: formKey,
          child: const AppInputField(
            label: 'Name',
            leadingIcon: Icons.person_outline,
            validator: _requiredValidator,
          ),
        ),
      ),
    );
  }

  testWidgets('validator fires when form validates', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(buildSubject(formKey));

    formKey.currentState!.validate();
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('renders leading icon', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(buildSubject(formKey));

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}

String? _requiredValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Required';
  }

  return null;
}
