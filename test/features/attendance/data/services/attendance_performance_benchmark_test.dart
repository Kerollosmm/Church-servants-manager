import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Performance Benchmark: Parallel Future.wait vs Sequential Loop', () {
    test('Future.wait executes simulated Firestore reads in parallel', () async {
      const itemCount = 10;
      const delayPerRead = Duration(milliseconds: 50);

      // Baseline: Sequential execution
      final sequentialStopwatch = Stopwatch()..start();
      for (int i = 0; i < itemCount; i++) {
        await Future.delayed(delayPerRead);
      }
      sequentialStopwatch.stop();

      // Optimized: Parallel execution using Future.wait
      final parallelStopwatch = Stopwatch()..start();
      await Future.wait(
        List.generate(itemCount, (_) => Future.delayed(delayPerRead)),
      );
      parallelStopwatch.stop();

      final sequentialMs = sequentialStopwatch.elapsedMilliseconds;
      final parallelMs = parallelStopwatch.elapsedMilliseconds;

      // Parallel execution should complete in ~1x delay time rather than 10x delay time
      expect(parallelMs, lessThan(sequentialMs ~/ 2));
    });
  });
}
