class StudentOperationException implements Exception {
  const StudentOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
