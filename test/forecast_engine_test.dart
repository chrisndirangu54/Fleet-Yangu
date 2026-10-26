import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/services/forecast_engine.dart';

void main() {
  const engine = TwinForecastEngine();

  test('RUL shrinks as degradation rate rises', () {
    final slow = engine.estimateLinearRul(
      currentHealth: 90,
      dailyHealthLoss: 1,
      replacementThreshold: 60,
    );
    final fast = engine.estimateLinearRul(
      currentHealth: 90,
      dailyHealthLoss: 3,
      replacementThreshold: 60,
    );

    expect(fast.expected, lessThan(slow.expected));
  });
}
