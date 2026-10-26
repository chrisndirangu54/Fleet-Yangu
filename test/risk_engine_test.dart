import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_yangu/models/fleet_models.dart';
import 'package:fleet_yangu/services/risk_engine.dart';

VehicleSnapshot vehicle({
  double health = 95,
  double coolant = 90,
  double tyre = 32,
  double brakes = 80,
  double payload = 300,
  double capacity = 1000,
  double fatigue = 10,
  double route = 20,
  double maintenance = 15,
  bool connected = true,
}) => VehicleSnapshot(
  id: 'v1',
  registration: 'TEST-1',
  name: 'Test Vehicle',
  type: 'Truck',
  healthScore: health,
  latitude: 0,
  longitude: 0,
  speedKph: 0,
  fuelPercent: 50,
  batteryPercent: 80,
  coolantTempC: coolant,
  tyrePressurePsi: tyre,
  brakeLifePercent: brakes,
  payloadKg: payload,
  payloadCapacityKg: capacity,
  driverFatigueScore: fatigue,
  routeRiskScore: route,
  maintenanceRiskScore: maintenance,
  engineOn: false,
  connected: connected,
);

void main() {
  const engine = FleetRiskEngine();

  test('healthy vehicle remains low risk', () {
    final result = engine.assess(vehicle());
    expect(result.level, RiskLevel.low);
    expect(result.score, lessThan(30));
  });

  test('multiple severe conditions escalate risk', () {
    final result = engine.assess(vehicle(
      health: 55,
      coolant: 110,
      tyre: 23,
      brakes: 8,
      payload: 1200,
      fatigue: 90,
      route: 80,
      maintenance: 85,
      connected: false,
    ));
    expect(result.level, RiskLevel.critical);
    expect(result.score, greaterThanOrEqualTo(75));
    expect(result.actions, isNotEmpty);
  });
}
