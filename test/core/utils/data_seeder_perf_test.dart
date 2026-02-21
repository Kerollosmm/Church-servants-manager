import 'dart:math';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/core/utils/data_seeder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class ZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

void main() {
  const studentCount = 120;
  const queryDelay = Duration(milliseconds: 2);
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  test('benchmark seedStudents team lookup query count', () async {
    final firestore = MockFirebaseFirestore();
    final auth = MockFirebaseAuth();
    final studentsCollection = MockCollectionReference();
    final classesCollection = MockCollectionReference();

    when(
      () => firestore.collection(FirestoreCollections.students),
    ).thenReturn(studentsCollection);
    when(
      () => firestore.collection(FirestoreCollections.classes),
    ).thenReturn(classesCollection);

    var studentDocCounter = 0;
    when(() => studentsCollection.doc()).thenAnswer((_) {
      final docRef = MockDocumentReference();
      final docId = 'student-doc-${studentDocCounter++}';
      when(() => docRef.id).thenReturn(docId);
      when(() => docRef.set(any())).thenAnswer((_) async {});
      return docRef;
    });

    var teamQueryCount = 0;
    final queriesByGroup = <String, MockQuery>{};

    for (final group in Group.values) {
      final query = MockQuery();
      final snapshot = MockQuerySnapshot();
      final teamDoc = MockQueryDocumentSnapshot();

      when(() => teamDoc.data()).thenReturn({
        'id': 'team-${group.name}',
        'name': 'Team ${group.name}',
        'groupId': group.name,
      });
      when(() => snapshot.docs).thenReturn([teamDoc]);
      when(() => query.limit(5)).thenReturn(query);
      when(() => query.get()).thenAnswer((_) async {
        teamQueryCount++;
        await Future<void>.delayed(queryDelay);
        return snapshot;
      });

      queriesByGroup[group.name] = query;
    }

    when(
      () => classesCollection.where(
        'groupId',
        isEqualTo: any(named: 'isEqualTo'),
      ),
    ).thenAnswer((invocation) {
      final groupId = invocation.namedArguments[#isEqualTo] as String;
      return queriesByGroup[groupId]!;
    });

    final seeder = DataSeeder(
      firestore: firestore,
      auth: auth,
      random: ZeroRandom(),
    );

    final stopwatch = Stopwatch()..start();
    await seeder.seedStudents(count: studentCount);
    stopwatch.stop();

    originalDebugPrint('seed_students_count=$studentCount');
    originalDebugPrint('seed_students_team_query_count=$teamQueryCount');
    originalDebugPrint(
      'seed_students_elapsed_ms=${stopwatch.elapsedMilliseconds}',
    );

    expect(teamQueryCount, lessThan(studentCount));
    expect(teamQueryCount, lessThanOrEqualTo(Group.values.length));
  });
}
