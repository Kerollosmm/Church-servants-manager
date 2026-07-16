import 'dart:convert';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/auth/domain/entities/invitation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class InvitationsRepository {
  final FirebaseFirestore _firestore;

  InvitationsRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<Invitation?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final box = await Hive.openBox<String>('invitation_by_email_cache');
    final cachedStr = box.get(normalizedEmail);
    if (cachedStr != null) {
      try {
        final decoded = json.decode(cachedStr) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
        if (DateTime.now().difference(cachedAt).inHours < 1) {
          final invMap = decoded['invitation'] as Map<String, dynamic>?;
          if (invMap == null) return null; // cached negative lookup
          return Invitation.fromMap(invMap);
        }
      } catch (e, stackTrace) {
        developer.log(
          'Failed to parse cached invitation: $e',
          name: 'InvitationsRepository',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      final docSnap = await _firestore
          .collection(FirestoreCollections.invitations)
          .doc(normalizedEmail)
          .get();

      if (!docSnap.exists) {
        // Cache negative lookup (invitation doesn't exist)
        final cacheMap = {
          'cachedAt': DateTime.now().toIso8601String(),
          'invitation': null,
        };
        await box.put(normalizedEmail, json.encode(cacheMap));
        return null;
      }

      // Convert timestamp from firestore safely
      final data = docSnap.data()!;
      final mapForInvitation = Map<String, dynamic>.from(data);
      final invitedAtVal = data['invitedAt'];
      if (invitedAtVal is Timestamp) {
        mapForInvitation['invitedAt'] = invitedAtVal.toDate().toIso8601String();
      }

      final invitation = Invitation.fromMap(mapForInvitation);

      final cacheMap = {
        'cachedAt': DateTime.now().toIso8601String(),
        'invitation': invitation.toMap(),
      };
      await box.put(normalizedEmail, json.encode(cacheMap));
      return invitation;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch invitation from Firestore: $e',
        name: 'InvitationsRepository',
        error: e,
        stackTrace: stackTrace,
      );
      // On network failure, fall back to expired cache if available
      if (cachedStr != null) {
        try {
          final decoded = json.decode(cachedStr) as Map<String, dynamic>;
          final invMap = decoded['invitation'] as Map<String, dynamic>?;
          if (invMap != null) {
            return Invitation.fromMap(invMap);
          }
        } catch (cacheErr, cacheStack) {
          developer.log(
            'Failed to parse cached invitation fallback: $cacheErr',
            name: 'InvitationsRepository',
            error: cacheErr,
            stackTrace: cacheStack,
          );
        }
      }
      return null;
    }
  }
}
