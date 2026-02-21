// ignore_for_file: avoid_print
import 'dart:math';

class StudentLite {
  final String docId;
  final String name;

  StudentLite(this.docId, this.name);
}

List<StudentLite> _baselineMergeThenSortTwice(
  List<List<StudentLite>> chunkResults,
) {
  final byDocId = <String, StudentLite>{};
  for (final students in chunkResults) {
    for (final student in students) {
      byDocId[student.docId] = student;
    }
  }

  final merged = byDocId.values.toList(growable: false);
  merged.sort((a, b) => a.name.compareTo(b.name)); // repository sort
  merged.sort((a, b) => a.name.compareTo(b.name)); // bloc sort
  return merged;
}

List<StudentLite> _optimizedMergeThenSortOnce(
  List<List<StudentLite>> chunkResults,
) {
  final byDocId = <String, StudentLite>{};
  for (final students in chunkResults) {
    for (final student in students) {
      byDocId[student.docId] = student;
    }
  }

  final merged = byDocId.values.toList(growable: false);
  merged.sort((a, b) => a.name.compareTo(b.name)); // bloc sort only
  return merged;
}

List<List<StudentLite>> _buildSyntheticChunkResults({
  required int chunks,
  required int studentsPerChunk,
  required int duplicateEvery,
}) {
  final random = Random(42);
  final results = <List<StudentLite>>[];
  var runningId = 0;

  for (var c = 0; c < chunks; c++) {
    final chunk = <StudentLite>[];
    for (var i = 0; i < studentsPerChunk; i++) {
      final isDuplicate =
          duplicateEvery > 0 && i % duplicateEvery == 0 && c > 0;
      final id = isDuplicate
          ? 'student_${i % studentsPerChunk}'
          : 'student_${runningId++}';
      final name = 'Name_${random.nextInt(1000000).toString().padLeft(6, '0')}';
      chunk.add(StudentLite(id, name));
    }
    results.add(chunk);
  }

  return results;
}

Duration _measure(
  List<StudentLite> Function(List<List<StudentLite>>) fn,
  List<List<StudentLite>> data,
  int iterations,
) {
  final watch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn(data);
  }
  watch.stop();
  return watch.elapsed;
}

void main() {
  final data = _buildSyntheticChunkResults(
    chunks: 8,
    studentsPerChunk: 1500,
    duplicateEvery: 5,
  );

  const iterations = 150;

  final baseline = _measure(_baselineMergeThenSortTwice, data, iterations);
  final optimized = _measure(_optimizedMergeThenSortOnce, data, iterations);

  final baselineUs = baseline.inMicroseconds;
  final optimizedUs = optimized.inMicroseconds;
  final improvement = baselineUs == 0
      ? 0
      : ((baselineUs - optimizedUs) / baselineUs) * 100;

  print('Benchmark: team-student merge path (synthetic)');
  print('Iterations: $iterations');
  print('Baseline (2 sorts): ${baseline.inMilliseconds} ms');
  print('Optimized (1 sort): ${optimized.inMilliseconds} ms');
  print('Improvement: ${improvement.toStringAsFixed(2)}%');
}
