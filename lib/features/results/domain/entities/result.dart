class Result {
  final String studentId;
  final String termId;
  final double score;
  final String? notes;
  final String groupId;

  const Result({
    required this.studentId,
    required this.termId,
    required this.score,
    this.notes,
    required this.groupId,
  });
}
