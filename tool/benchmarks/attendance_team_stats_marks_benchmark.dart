import 'dart:async';
import 'dart:io';

const _sessionCount = 8;
const _marksPerSession = 12;
const _simulatedMarksQueryLatency = Duration(milliseconds: 30);
const _warmupIterations = 2;
const _measuredIterations = 8;

Future<void> main() async {
  final sequentialAverage = await _measureAverage(_fetchSequentialMarks);
  final parallelAverage = await _measureAverage(_fetchParallelMarks);

  final savedTime = sequentialAverage - parallelAverage;
  final improvement = sequentialAverage == 0
      ? 0.0
      : (savedTime / sequentialAverage) * 100;

  stdout.writeln('Attendance team-stats marks benchmark');
  stdout.writeln(
    'Synthetic workload: $_sessionCount closed sessions, '
    '$_marksPerSession marks/session, '
    '${_simulatedMarksQueryLatency.inMilliseconds}ms/query latency.',
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
    'surface the production cost of serialized subcollection reads.',
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

Future<void> _fetchSequentialMarks() async {
  for (var index = 0; index < _sessionCount; index++) {
    final marks = await _simulateMarksQuery(index);
    _consumeMarks(marks);
  }
}

Future<void> _fetchParallelMarks() async {
  final snapshots = await Future.wait(
    List.generate(_sessionCount, _simulateMarksQuery),
    eagerError: true,
  );

  for (final marks in snapshots) {
    _consumeMarks(marks);
  }
}

Future<List<int>> _simulateMarksQuery(int sessionIndex) async {
  await Future.delayed(_simulatedMarksQueryLatency);
  return List.generate(
    _marksPerSession,
    (markIndex) => sessionIndex * _marksPerSession + markIndex,
  );
}

void _consumeMarks(List<int> marks) {
  var presentCount = 0;
  for (final mark in marks) {
    if (mark.isEven) {
      presentCount += 1;
    }
  }

  if (presentCount < 0) {
    throw StateError('Unreachable');
  }
}
