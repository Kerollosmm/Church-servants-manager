import 'package:cloud_firestore/cloud_firestore.dart';

bool isPermissionDeniedException(Object error) {
  if (error is FirebaseException) {
    return error.code == 'permission-denied';
  }
  final entry = error.toString().toLowerCase();
  return entry.contains('permission-denied') ||
      entry.contains('permission denied');
}

bool isNotFoundException(Object error) {
  if (error is FirebaseException) {
    return error.code == 'not-found';
  }
  final entry = error.toString().toLowerCase();
  return entry.contains('not-found') || entry.contains('not found');
}
