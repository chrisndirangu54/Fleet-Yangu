class TwinSignal {
  final String name;
  final double value;
  final String unit;
  final DateTime observedAt;
  final double confidence;
  final String source;

  const TwinSignal({
    required this.name,
    required this.value,
    required this.unit,
    required this.observedAt,
    required this.confidence,
    required this.source,
  });
}

class VehicleDigitalTwin {
  final String vehicleId;
  final Map<String, TwinSignal> signals;
  final Map<String, String> componentState;
  final Map<String, double> healthScores;
  final DateTime updatedAt;

  const VehicleDigitalTwin({
    required this.vehicleId,
    required this.signals,
    required this.componentState,
    required this.healthScores,
    required this.updatedAt,
  });

  double? signal(String key) => signals[key]?.value;

  VehicleDigitalTwin mergeSignals(Iterable<TwinSignal> incoming) {
    final next = Map<String, TwinSignal>.from(signals);
    for (final signal in incoming) {
      final current = next[signal.name];
      if (current == null ||
          signal.observedAt.isAfter(current.observedAt) ||
          (signal.observedAt == current.observedAt &&
              signal.confidence > current.confidence)) {
        next[signal.name] = signal;
      }
    }
    return VehicleDigitalTwin(
      vehicleId: vehicleId,
      signals: next,
      componentState: componentState,
      healthScores: healthScores,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
