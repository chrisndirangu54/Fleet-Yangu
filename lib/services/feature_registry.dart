class FeatureDefinition {
  final String name;
  final String entity;
  final String dtype;
  final String unit;
  final Duration maxAge;
  final bool safetyRelevant;
  final String owner;

  const FeatureDefinition({
    required this.name,
    required this.entity,
    required this.dtype,
    required this.unit,
    required this.maxAge,
    required this.safetyRelevant,
    required this.owner,
  });
}

class FeatureValue {
  final FeatureDefinition definition;
  final Object? value;
  final DateTime observedAt;
  final double confidence;
  final String provenance;

  const FeatureValue({
    required this.definition,
    required this.value,
    required this.observedAt,
    required this.confidence,
    required this.provenance,
  });

  bool staleAt(DateTime now) =>
      now.difference(observedAt) > definition.maxAge;
}

class FeatureRegistry {
  final Map<String, FeatureDefinition> definitions;

  const FeatureRegistry(this.definitions);

  FeatureDefinition? operator [](String name) => definitions[name];

  bool validate(FeatureValue v) {
    final registered = definitions[v.definition.name];
    if (registered == null) return false;
    return registered.dtype == v.definition.dtype &&
        registered.unit == v.definition.unit &&
        v.confidence >= 0 &&
        v.confidence <= 1;
  }
}
