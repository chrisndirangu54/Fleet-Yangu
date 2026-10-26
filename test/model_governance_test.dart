import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/services/model_governance.dart';

void main() {
  const governance = ModelGovernance();

  test('blocks weak safety-critical model', () {
    final decision = governance.canPromote(
      ModelVersion(
        name: 'driver-drowsiness',
        version: '2.0.0',
        purpose: 'Driver drowsiness detection',
        checksum: 'abc',
        activatedAt: DateTime(2026, 1, 1),
        safetyCritical: true,
        precision: 0.82,
        recall: 0.95,
        calibrationError: 0.05,
      ),
    );

    expect(decision.allow, isFalse);
    expect(decision.reasons, isNotEmpty);
  });
}
