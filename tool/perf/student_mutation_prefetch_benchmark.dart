// ignore_for_file: avoid_print
import 'dart:async';

class StudentLite {
  final String docId;
  const StudentLite(this.docId);
}

Future<StudentLite?> _baselineAlwaysRepositoryRead(
  List<StudentLite> cache,
  String docId,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  for (final s in cache) {
    if (s.docId == docId) return s;
  }
  return null;
}

Future<StudentLite?> _optimizedCacheFirst(
  List<StudentLite> cache,
  String docId,
) async {
  for (final s in cache) {
    if (s.docId == docId) return s;
  }

  await Future<void>.delayed(const Duration(milliseconds: 1));
  return null;
}

Future<Duration> _measure(
  Future<StudentLite?> Function(List<StudentLite>, String) fn,
  List<StudentLite> cache,
  List<String> ids,
) async {
  final sw = Stopwatch()..start();
  for (final id in ids) {
    await fn(cache, id);
  }
  sw.stop();
  return sw.elapsed;
}

Future<void> main() async {
  final cache = List.generate(500, (i) => StudentLite('doc-$i'));
  final ids = List.generate(200, (i) => 'doc-${i % cache.length}');

  final baseline = await _measure(_baselineAlwaysRepositoryRead, cache, ids);
  final optimized = await _measure(_optimizedCacheFirst, cache, ids);

  final baselineUs = baseline.inMicroseconds;
  final optimizedUs = optimized.inMicroseconds;
  final improvement = baselineUs == 0
      ? 0
      : ((baselineUs - optimizedUs) / baselineUs) * 100;

  print('Benchmark: mutation pre-check cache hit path');
  print('Operations: ${ids.length}');
  print('Baseline (always repo read): ${baseline.inMilliseconds} ms');
  print('Optimized (cache-first): ${optimized.inMilliseconds} ms');
  print('Improvement: ${improvement.toStringAsFixed(2)}%');
}
