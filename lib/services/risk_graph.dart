enum RiskNodeType {
  vehicle,
  driver,
  route,
  cargo,
  component,
  workshop,
  depot,
  charger,
  insurer,
  supplier,
}

class RiskNode {
  final String id;
  final RiskNodeType type;
  final double intrinsicRisk;
  final double confidence;

  const RiskNode({
    required this.id,
    required this.type,
    required this.intrinsicRisk,
    required this.confidence,
  });
}

class RiskEdge {
  final String from;
  final String to;
  final double exposure;
  final double confidence;
  final String relation;

  const RiskEdge({
    required this.from,
    required this.to,
    required this.exposure,
    required this.confidence,
    required this.relation,
  });
}

class RiskGraphResult {
  final double score;
  final List<String> explanations;

  const RiskGraphResult(this.score, this.explanations);
}

class FleetRiskGraph {
  const FleetRiskGraph();

  RiskGraphResult score({
    required String targetId,
    required List<RiskNode> nodes,
    required List<RiskEdge> edges,
  }) {
    final byId = {for (final n in nodes) n.id: n};
    final target = byId[targetId];
    if (target == null) {
      return const RiskGraphResult(0, ['Target node not found']);
    }

    var weighted = target.intrinsicRisk * target.confidence;
    var weight = target.confidence;
    final explanations = <String>[
      'Intrinsic ${target.type.name} risk contributes ${target.intrinsicRisk.toStringAsFixed(1)}',
    ];

    for (final edge in edges.where((e) => e.from == targetId || e.to == targetId)) {
      final otherId = edge.from == targetId ? edge.to : edge.from;
      final other = byId[otherId];
      if (other == null) continue;
      final w = edge.exposure * edge.confidence * other.confidence;
      weighted += other.intrinsicRisk * w;
      weight += w;
      if (w >= 0.25) {
        explanations.add(
          '${edge.relation}: ${other.type.name} ${other.id} contributes '
          '${(other.intrinsicRisk * w).toStringAsFixed(1)} weighted risk',
        );
      }
    }

    final score = weight <= 0 ? 0 : (weighted / weight).clamp(0.0, 100.0);
    return RiskGraphResult(score, explanations.take(5).toList());
  }
}
