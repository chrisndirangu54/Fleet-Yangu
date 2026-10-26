import 'dart:math' as math;

class AnomalyResult {
  final double score;
  final bool anomalous;
  final String explanation;

  const AnomalyResult({
    required this.score,
    required this.anomalous,
    required this.explanation,
  });
}

class EwmaState {
  final double mean;
  final double variance;
  final int samples;

  const EwmaState({
    required this.mean,
    required this.variance,
    required this.samples,
  });

  factory EwmaState.seed(double value) =>
      EwmaState(mean: value, variance: 0, samples: 1);
}

/// Explainable edge/cloud-parity anomaly detector.
/// Deterministic safety checks remain authoritative; ML can augment them.
class ExplainableAnomalyEngine {
  final double alpha;
  final double zThreshold;

  const ExplainableAnomalyEngine({
    this.alpha = 0.18,
    this.zThreshold = 3.0,
  });

  EwmaState update(EwmaState? previous, double value) {
    if (previous == null) return EwmaState.seed(value);

    final nextMean = alpha * value + (1 - alpha) * previous.mean;
    final delta = value - previous.mean;
    final nextVariance =
        alpha * delta * delta + (1 - alpha) * previous.variance;

    return EwmaState(
      mean: nextMean,
      variance: nextVariance,
      samples: previous.samples + 1,
    );
  }

  AnomalyResult evaluate(EwmaState state, double value, {String? signalName}) {
    if (state.samples < 8 || state.variance <= 1e-9) {
      return const AnomalyResult(
        score: 0,
        anomalous: false,
        explanation: 'Insufficient baseline history',
      );
    }

    final std = math.sqrt(state.variance);
    final z = (value - state.mean).abs() / std;
    final normalized = (z / zThreshold).clamp(0.0, 2.0);
    final label = signalName ?? 'signal';

    return AnomalyResult(
      score: normalized * 50,
      anomalous: z >= zThreshold,
      explanation:
          '$label deviated by ${z.toStringAsFixed(2)}σ from its rolling baseline',
    );
  }
}
