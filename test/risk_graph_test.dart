import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/services/risk_graph.dart';

void main() {
  test('risk graph incorporates connected exposure', () {
    const graph = FleetRiskGraph();
    final result = graph.score(
      targetId: 'vehicle-1',
      nodes: const [
        RiskNode(
          id: 'vehicle-1',
          type: RiskNodeType.vehicle,
          intrinsicRisk: 25,
          confidence: 1,
        ),
        RiskNode(
          id: 'driver-1',
          type: RiskNodeType.driver,
          intrinsicRisk: 80,
          confidence: 0.95,
        ),
      ],
      edges: const [
        RiskEdge(
          from: 'vehicle-1',
          to: 'driver-1',
          exposure: 0.8,
          confidence: 0.9,
          relation: 'assigned_driver',
        ),
      ],
    );

    expect(result.score, greaterThan(25));
    expect(result.explanations, isNotEmpty);
  });
}
