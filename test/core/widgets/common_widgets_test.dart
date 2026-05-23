import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEmptyState Widget Tests', () {
    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'Empty Title',
              subtitle: 'Empty Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Empty Title'), findsOneWidget);
      expect(find.text('Empty Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('shows action button when onAction is provided', (
      WidgetTester tester,
    ) async {
      bool actionCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: AppEmptyState(
              title: 'Title',
              subtitle: 'Subtitle',
              actionLabel: 'Add Something',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(FilledButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Add Something'), findsOneWidget);

      await tester.tap(buttonFinder);
      expect(actionCalled, true);
    });

    testWidgets('shows refresh button when onRefresh is provided', (
      WidgetTester tester,
    ) async {
      bool refreshCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: AppEmptyState(
              title: 'Title',
              subtitle: 'Subtitle',
              onRefresh: () async {
                refreshCalled = true;
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(TextButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);

      await tester.tap(buttonFinder);
      expect(refreshCalled, true);
    });
  });

  group('AppErrorState Widget Tests', () {
    testWidgets('renders title and error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              title: 'Error Title',
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button and calls onRetry', (
      WidgetTester tester,
    ) async {
      bool retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: AppErrorState(
              message: 'Error',
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(FilledButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(buttonFinder);
      expect(retryCalled, true);
    });
  });
}
