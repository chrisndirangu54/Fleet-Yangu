import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/services/feature_registry.dart';

void main() {
  const def = FeatureDefinition(
    name: 'coolant_temp',
    entity: 'vehicle',
    dtype: 'double',
    unit: 'C',
    maxAge: Duration(minutes: 2),
    safetyRelevant: true,
    owner: 'vehicle-intelligence',
  );

  const registry = FeatureRegistry({'coolant_temp': def});

  test('validates a registered feature contract', () {
    final value = FeatureValue(
      definition: def,
      value: 92.0,
      observedAt: DateTime(2026, 1, 1),
      confidence: 0.99,
      provenance: 'ecu',
    );
    expect(registry.validate(value), isTrue);
  });
}
