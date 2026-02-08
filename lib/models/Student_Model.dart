class Student {
  final String id;
  final String name;
  final String studentId;
  bool isPresent;

  Student({
    required this.id,
    required this.name,
    required this.studentId,
    this.isPresent = false,
  });
}

