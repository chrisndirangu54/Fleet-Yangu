import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/services/anomaly_engine.dart';

void main() {
  const engine = ExplainableAnomalyEngine(alpha: 0.2, zThreshold: 3);

  test('detects a large deviation after baseline learning', () {
    EwmaState? state;
    for (final value in [90.0, 91, 89, 90, 91, 90, 89, 90, 91, 90, 89, 90]) {
      state = engine.update(state, value);
    }

    final result = engine.evaluate(state!, 125, signalName: 'coolant');
    expect(result.anomalous, isTrue);
    expect(result.score, greaterThan(50));
  });
}
