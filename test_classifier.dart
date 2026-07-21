import 'package:church_management_system/core/utils/sync_error_classifier.dart';

void main() {
  final e = Exception('Network error');
  print('Error toString: ${e.toString()}');
  print('isRetriable: ${SyncErrorClassifier.isRetriable(e)}');
}
