class ModelVersion {
  final String name;
  final String version;
  final String purpose;
  final String checksum;
  final DateTime activatedAt;
  final bool safetyCritical;
  final double? precision;
  final double? recall;
  final double? calibrationError;

  const ModelVersion({
    required this.name,
    required this.version,
    required this.purpose,
    required this.checksum,
    required this.activatedAt,
    required this.safetyCritical,
    this.precision,
    this.recall,
    this.calibrationError,
  });
}

class DriftSnapshot {
  final String modelName;
  final double populationStabilityIndex;
  final double missingnessDelta;
  final double predictionShift;
  final DateTime measuredAt;

  const DriftSnapshot({
    required this.modelName,
    required this.populationStabilityIndex,
    required this.missingnessDelta,
    required this.predictionShift,
    required this.measuredAt,
  });

  bool get requiresReview =>
      populationStabilityIndex >= 0.25 ||
      missingnessDelta >= 0.15 ||
      predictionShift >= 0.20;
}

class ModelGovernanceDecision {
  final bool allow;
  final List<String> reasons;

  const ModelGovernanceDecision(this.allow, this.reasons);
}

class ModelGovernance {
  const ModelGovernance();

  ModelGovernanceDecision canPromote(
    ModelVersion candidate, {
    DriftSnapshot? drift,
  }) {
    final reasons = <String>[];

    if (candidate.safetyCritical) {
      if ((candidate.precision ?? 0) < 0.90) reasons.add('Precision below 0.90');
      if ((candidate.recall ?? 0) < 0.90) reasons.add('Recall below 0.90');
      if ((candidate.calibrationError ?? 1) > 0.10) {
        reasons.add('Calibration error above 0.10');
      }
    }

    if (drift?.requiresReview == true) {
      reasons.add('Input or prediction drift requires review');
    }

    return ModelGovernanceDecision(reasons.isEmpty, reasons);
  }
}
