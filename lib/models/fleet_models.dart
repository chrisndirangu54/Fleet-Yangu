enum RiskLevel { low, moderate, high, critical }

enum FeatureStatus { healthy, attention, warning, critical, offline }

class VehicleSnapshot {
  final String id;
  final String registration;
  final String name;
  final String type;
  final double healthScore;
  final double latitude;
  final double longitude;
  final double speedKph;
  final double fuelPercent;
  final double batteryPercent;
  final double coolantTempC;
  final double tyrePressurePsi;
  final double brakeLifePercent;
  final double payloadKg;
  final double payloadCapacityKg;
  final double driverFatigueScore;
  final double routeRiskScore;
  final double maintenanceRiskScore;
  final bool engineOn;
  final bool connected;
  final bool ev;

  const VehicleSnapshot({
    required this.id,
    required this.registration,
    required this.name,
    required this.type,
    required this.healthScore,
    required this.latitude,
    required this.longitude,
    required this.speedKph,
    required this.fuelPercent,
    required this.batteryPercent,
    required this.coolantTempC,
    required this.tyrePressurePsi,
    required this.brakeLifePercent,
    required this.payloadKg,
    required this.payloadCapacityKg,
    required this.driverFatigueScore,
    required this.routeRiskScore,
    required this.maintenanceRiskScore,
    required this.engineOn,
    required this.connected,
    this.ev = false,
  });

  double get loadRatio => payloadCapacityKg <= 0 ? 0 : payloadKg / payloadCapacityKg;
}

class FleetAlert {
  final String id;
  final String vehicleId;
  final String title;
  final String detail;
  final RiskLevel severity;
  final DateTime occurredAt;
  final String category;

  const FleetAlert({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.detail,
    required this.severity,
    required this.occurredAt,
    required this.category,
  });
}

class FleetModule {
  final String id;
  final String title;
  final String subtitle;
  final String metric;
  final FeatureStatus status;
  final List<String> capabilities;

  const FleetModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.status,
    required this.capabilities,
  });
}

class RiskAssessment {
  final double score;
  final RiskLevel level;
  final List<String> factors;
  final List<String> actions;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.actions,
  });
}
