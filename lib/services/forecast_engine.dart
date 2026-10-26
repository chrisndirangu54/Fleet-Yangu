class ForecastPoint {
  final DateTime time;
  final double value;
  final double lower;
  final double upper;

  const ForecastPoint({
    required this.time,
    required this.value,
    required this.lower,
    required this.upper,
  });
}

class RemainingUsefulLifeEstimate {
  final Duration expected;
  final Duration lower;
  final Duration upper;
  final double confidence;
  final List<String> drivers;

  const RemainingUsefulLifeEstimate({
    required this.expected,
    required this.lower,
    required this.upper,
    required this.confidence,
    required this.drivers,
  });
}

class TwinForecastEngine {
  const TwinForecastEngine();

  RemainingUsefulLifeEstimate estimateLinearRul({
    required double currentHealth,
    required double dailyHealthLoss,
    required double replacementThreshold,
    List<String> drivers = const [],
  }) {
    if (dailyHealthLoss <= 0 || currentHealth <= replacementThreshold) {
      return RemainingUsefulLifeEstimate(
        expected: Duration.zero,
        lower: Duration.zero,
        upper: const Duration(days: 1),
        confidence: 0.35,
        drivers: drivers,
      );
    }

    final days = (currentHealth - replacementThreshold) / dailyHealthLoss;
    final expected = Duration(hours: (days * 24).round());
    return RemainingUsefulLifeEstimate(
      expected: expected,
      lower: Duration(hours: (days * 24 * 0.70).round()),
      upper: Duration(hours: (days * 24 * 1.35).round()),
      confidence: drivers.isEmpty ? 0.55 : 0.72,
      drivers: drivers,
    );
  }

  List<ForecastPoint> forecastSignal({
    required DateTime start,
    required double current,
    required double deltaPerHour,
    int hours = 24,
  }) {
    return List.generate(hours, (i) {
      final h = i + 1;
      final value = current + deltaPerHour * h;
      final uncertainty = 0.08 * h.abs() * (current.abs() + 1) / 24;
      return ForecastPoint(
        time: start.add(Duration(hours: h)),
        value: value,
        lower: value - uncertainty,
        upper: value + uncertainty,
      );
    });
  }
}
