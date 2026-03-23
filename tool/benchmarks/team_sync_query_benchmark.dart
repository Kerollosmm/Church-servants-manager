import 'dart:async';
import 'dart:io';

const _chunkSize = 10;
const _userCount = 50;
const _simulatedQueryLatency = Duration(milliseconds: 35);
const _warmupIterations = 2;
const _measuredIterations = 8;

Future<void> main() async {
  final sequentialAverage = await _measureAverage(
    () => _fetchSequentially(_userCount),
  );
  final parallelAverage = await _measureAverage(
    () => _fetchInParallel(_userCount),
  );

  final savedTime = sequentialAverage - parallelAverage;
  final improvement = sequentialAverage == 0
      ? 0.0
      : (savedTime / sequentialAverage) * 100;

  stdout.writeln('Team sync query benchmark');
  stdout.writeln(
    'Synthetic workload: $_userCount users, '
    '${(_userCount / _chunkSize).ceil()} whereIn queries, '
    '${_simulatedQueryLatency.inMilliseconds}ms/query latency.',
  );
  stdout.writeln(
    'Sequential average: ${sequentialAverage.toStringAsFixed(2)} ms',
  );
  stdout.writeln('Parallel average: ${parallelAverage.toStringAsFixed(2)} ms');
  stdout.writeln('Saved time: ${savedTime.toStringAsFixed(2)} ms');
  stdout.writeln('Improvement: ${improvement.toStringAsFixed(1)}% faster');
  stdout.writeln(
    'Note: This benchmark models Firestore network latency with '
    'Future.delayed because fake_cloud_firestore is in-memory and does not '
    'expose the real cost of sequential round trips.',
  );
}

Future<double> _measureAverage(Future<void> Function() action) async {
  for (var index = 0; index < _warmupIterations; index++) {
    await action();
  }

  var totalMicroseconds = 0;
  for (var index = 0; index < _measuredIterations; index++) {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    totalMicroseconds += stopwatch.elapsedMicroseconds;
  }

  return totalMicroseconds / _measuredIterations / 1000;
}

Future<void> _fetchSequentially(int userCount) async {
  final userIds = List.generate(userCount, (index) => 'user-$index');
  for (final chunk in _chunkList(userIds, _chunkSize)) {
    await _simulateChunkQuery(chunk);
  }
}

Future<void> _fetchInParallel(int userCount) async {
  final userIds = List.generate(userCount, (index) => 'user-$index');
  await Future.wait(
    _chunkList(userIds, _chunkSize).map(_simulateChunkQuery),
    eagerError: true,
  );
}

Future<void> _simulateChunkQuery(List<String> chunk) async {
  await Future.delayed(_simulatedQueryLatency);
}

List<List<T>> _chunkList<T>(List<T> values, int size) {
  final chunks = <List<T>>[];
  for (var index = 0; index < values.length; index += size) {
    final end = index + size > values.length ? values.length : index + size;
    chunks.add(values.sublist(index, end));
  }
  return chunks;
}
