bool isPermissionDeniedException(Object error) {
  final entry = error.toString().toLowerCase();
  return entry.contains('permission-denied') ||
      entry.contains('permission denied');
}

bool isNotFoundException(Object error) {
  final entry = error.toString().toLowerCase();
  return entry.contains('not-found') || entry.contains('not found');
}
