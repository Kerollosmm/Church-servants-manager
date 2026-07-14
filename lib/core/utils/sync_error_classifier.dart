import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncErrorClassifier {
  /// Determines if the given error is transient (e.g. network outage, timeout)
  /// and should be retried, or permanent (e.g. permission-denied) and should not.
  static bool isRetriable(Object error) {
    if (error is FirebaseException) {
      // Retriable firestore error codes
      const retriableCodes = {
        'unavailable',
        'deadline-exceeded',
        'aborted',
        'internal',
        'resource-exhausted',
      };
      return retriableCodes.contains(error.code);
    }

    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return true;
    }

    final errString = error.toString().toLowerCase();
    if (errString.contains('socketexception') ||
        errString.contains('timeout') ||
        errString.contains('connection failed') ||
        errString.contains('network') ||
        errString.contains('unavailable')) {
      return true;
    }

    return false;
  }
}
