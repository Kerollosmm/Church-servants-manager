// ignore_for_file: avoid_print
/// Migration script: Convert servant groupId → assignedTeamIds
///
/// This script reads all servants with an empty assignedTeamIds but a non-null
/// groupId, resolves the matching team document by name, and writes the correct
/// teamId into assignedTeamIds.
///
/// IDEMPOTENT: Safe to run multiple times.
/// Only updates servants that need migration.
///
/// Usage: dart tools/migrate_servant_team_assignments.dart
library;

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore collection constants
class FirestoreCollections {
  static const String users = 'Users';
  static const String classes = 'Classes';
}

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  int exitCode = 0;

  try {
    print('🚀 Starting servant team assignment migration...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 1. Fetch all servants (role == 'servant')
    final servantsSnapshot = await firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'servant')
        .get();

    print('📋 Found ${servantsSnapshot.docs.length} servants total.');

    int migrated = 0;
    int skipped = 0;
    int errors = 0;

    // 2. Fetch all classes for team name lookup
    final classesSnapshot = await firestore
        .collection(FirestoreCollections.classes)
        .get();

    // Build a map: groupId → list of team docs
    final teamsByGroup = <String, List<QueryDocumentSnapshot>>{};
    for (final classDoc in classesSnapshot.docs) {
      final data = classDoc.data();
      final groupId = data['groupId'] as String?;
      if (groupId != null) {
        teamsByGroup.putIfAbsent(groupId, () => []).add(classDoc);
      }
    }

    print(
      '📋 Found ${classesSnapshot.docs.length} teams across ${teamsByGroup.length} groups.',
    );
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 3. Process each servant
    var batch = firestore.batch();
    int batchCount = 0;
    const maxBatchSize =
        400; // Firestore batch limit is 500, use 400 for safety

    for (final servantDoc in servantsSnapshot.docs) {
      final servantData = servantDoc.data();
      final servantName = servantData['name'] ?? 'Unknown';
      final servantId = servantDoc.id;

      final groupId = servantData['groupId'] as String?;
      final assignedTeamIds =
          (servantData['assignedTeamIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final assignedTeamId = servantData['assignedTeamId'] as String?;

      // Check if servant already has team assignments
      if (assignedTeamIds.isNotEmpty || assignedTeamId != null) {
        skipped++;
        print(
          '⏭️  Skipped "$servantName" ($servantId) — already has team assignments',
        );
        continue;
      }

      // Check if servant has a groupId to migrate
      if (groupId == null || groupId.isEmpty) {
        skipped++;
        print(
          '⏭️  Skipped "$servantName" ($servantId) — no groupId or assignedTeamIds',
        );
        continue;
      }

      // Find teams in the servant's group
      final teamsInGroup = teamsByGroup[groupId] ?? [];
      if (teamsInGroup.isEmpty) {
        errors++;
        print(
          '❌ Error: "$servantName" ($servantId) — no teams found for groupId "$groupId"',
        );
        continue;
      }

      // If there's only one team in the group, assign it
      // If there are multiple teams, assign all of them
      final teamIds = teamsInGroup.map((t) => t.id).toList();

      // Update the document
      final docRef = firestore
          .collection(FirestoreCollections.users)
          .doc(servantId);
      batch.update(docRef, {
        'assignedTeamIds': teamIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batchCount++;
      migrated++;
      print(
        '✅ Migrated "$servantName" ($servantId) → assignedTeamIds: $teamIds',
      );

      // Commit batch if we reached the limit
      if (batchCount >= maxBatchSize) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📦 Committing batch of $batchCount updates...');
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📦 Committing final batch of $batchCount updates...');
      await batch.commit();
    }

    // Summary
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎉 Migration complete!');
    print('   ✅ Migrated: $migrated servants');
    print('   ⏭️  Skipped:  $skipped servants');
    print('   ❌ Errors:   $errors servants');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (errors > 0) {
      print('⚠️  Some servants could not be migrated. Check logs above.');
    }
  } catch (error) {
    print('❌ Critical migration error: $error');
    exitCode = 1;
  } finally {
    print('Shutting down Firebase connections...');
    await FirebaseFirestore.instance.terminate();
    await Firebase.app().delete();
  }

  exit(exitCode);
}
