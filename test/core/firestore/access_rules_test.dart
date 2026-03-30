import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final rulesFile = File('firestore.rules');

  test('rules use canonical linkedUserId for student self-read', () async {
    final content = await rulesFile.readAsString();

    expect(
      content.contains("resource.data.linkedUserId == callerUid()"),
      isTrue,
    );
    expect(content.contains("resource.data.uid == callerUid()"), isFalse);
  });

  test(
    'rules no longer allow self-updating isEmailVerified or role fields',
    () async {
      final content = await rulesFile.readAsString();

      expect(content.contains('allow update: if isAdmin();'), isTrue);
      expect(content.contains("'isEmailVerified'"), isTrue);
    },
  );

  test(
    'rules keep class reads limited to signed-in admins or servants',
    () async {
      final content = await rulesFile.readAsString();

      expect(
        content.contains(
          'allow read: if isSignedIn() && (isAdmin() || isServant());',
        ),
        isTrue,
      );
    },
  );
}
