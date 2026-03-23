import 'package:church_management_system/features/student/data/models/student_model.dart';

// FIX [P1]: extracted in-memory student search behind a use case.
class SearchStudentsUseCase {
  const SearchStudentsUseCase();

  List<StudentModel> call({
    required List<StudentModel> students,
    required String query,
  }) {
    final normalized = query.toLowerCase();
    return students
        .where((student) => student.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }
}
