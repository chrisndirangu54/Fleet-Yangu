import '../models/fleet_models.dart';

class FleetRiskEngine {
  const FleetRiskEngine();

  RiskAssessment assess(VehicleSnapshot v) {
    final factors = <String>[];
    final actions = <String>[];
    var score = 0.0;

    final healthRisk = (100 - v.healthScore).clamp(0, 100);
    score += healthRisk * 0.24;
    if (v.healthScore < 75) factors.add('Vehicle health below 75/100');

    if (v.coolantTempC >= 105) {
      score += 22;
      factors.add('Coolant temperature ${v.coolantTempC.toStringAsFixed(0)}°C');
      actions.add('Stop safely and inspect the cooling system');
    } else if (v.coolantTempC >= 98) {
      score += 10;
      factors.add('Elevated coolant temperature');
    }

    if (v.tyrePressurePsi < 27) {
      score += 18;
      factors.add('Low tyre pressure');
      actions.add('Inspect tyre before continuing long-distance operation');
    }

    if (v.brakeLifePercent < 15) {
      score += 18;
      factors.add('Brake life estimated below 15%');
      actions.add('Schedule brake inspection immediately');
    }

    if (v.loadRatio > 1) {
      score += 18;
      factors.add('Vehicle is overloaded');
      actions.add('Redistribute payload before dispatch');
    } else if (v.loadRatio > .9) {
      score += 8;
      factors.add('Payload close to rated capacity');
    }

    score += v.driverFatigueScore.clamp(0, 100) * 0.16;
    if (v.driverFatigueScore >= 65) {
      factors.add('Driver fatigue risk elevated');
      actions.add('Replace driver or require a rest period');
    }

    score += v.routeRiskScore.clamp(0, 100) * 0.11;
    if (v.routeRiskScore >= 65) factors.add('Route risk elevated');

    score += v.maintenanceRiskScore.clamp(0, 100) * 0.13;
    if (v.maintenanceRiskScore >= 60) {
      factors.add('Predictive maintenance risk elevated');
      actions.add('Review predicted component failures');
    }

    if (!v.connected) {
      score += 12;
      factors.add('Telematics gateway offline');
      actions.add('Verify gateway connectivity and last known position');
    }

    score = score.clamp(0, 100);
    final level = score >= 75
        ? RiskLevel.critical
        : score >= 55
            ? RiskLevel.high
            : score >= 30
                ? RiskLevel.moderate
                : RiskLevel.low;

    if (actions.isEmpty) actions.add('Continue monitoring under normal fleet policy');
    return RiskAssessment(score: score, level: level, factors: factors, actions: actions);
  }
}
