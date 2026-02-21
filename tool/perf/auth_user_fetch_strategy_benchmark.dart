// ignore_for_file: avoid_print
import 'dart:math';

class _Result {
  final int baselineMs;
  final int optimizedMs;
  const _Result(this.baselineMs, this.optimizedMs);
}

_Result _runSimulation({
  required int operations,
  required int cacheHitRatePercent,
  required int serverMs,
  required int cacheMs,
}) {
  final random = Random(2026);
  var baselineTotal = 0;
  var optimizedTotal = 0;

  for (var i = 0; i < operations; i++) {
    final cacheHit = random.nextInt(100) < cacheHitRatePercent;

    // Baseline: forced server first (cache only on failure).
    baselineTotal += serverMs;

    // Optimized: default-first allows immediate cache hit, otherwise server.
    optimizedTotal += cacheHit ? cacheMs : serverMs;
  }

  return _Result(baselineTotal, optimizedTotal);
}

void main() {
  const operations = 200;
  const serverMs = 85;
  const cacheMs = 4;
  const cacheHitRatePercent = 70;

  final result = _runSimulation(
    operations: operations,
    cacheHitRatePercent: cacheHitRatePercent,
    serverMs: serverMs,
    cacheMs: cacheMs,
  );

  final improvement =
      ((result.baselineMs - result.optimizedMs) / result.baselineMs) * 100;

  print('Benchmark: auth user fetch strategy (simulated latency model)');
  print('Operations: $operations');
  print('Cache-hit rate: $cacheHitRatePercent%');
  print('Baseline (forced server-first): ${result.baselineMs} ms');
  print('Optimized (default source first): ${result.optimizedMs} ms');
  print('Improvement: ${improvement.toStringAsFixed(2)}%');
}
