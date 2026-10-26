export type SimVehicleState = {
  t: number;
  speedKph: number;
  coolantTempC: number;
  batteryVoltage: number;
  fuelPercent: number;
  tyrePressurePsi: number;
  brakeLifePercent: number;
  payloadKg: number;
  payloadCapacityKg: number;
  driverFatigueScore: number;
};

export type SimEvent = {
  eventId: string;
  sequence: number;
  capturedAt: string;
  kind: 'telemetry' | 'fault';
  payload: Record<string, unknown>;
};

export type Scenario = {
  durationSeconds: number;
  stepSeconds: number;
  initial: SimVehicleState;
  faultAtSecond?: number;
  fault?: 'coolant_leak' | 'tyre_leak' | 'alternator_failure' | 'fuel_siphon' | 'driver_fatigue';
};

export function runScenario(s: Scenario): SimEvent[] {
  const events: SimEvent[] = [];
  let state = {...s.initial};
  let sequence = 0;

  for (let t = 0; t <= s.durationSeconds; t += s.stepSeconds) {
    const faultActive = s.faultAtSecond != null && t >= s.faultAtSecond;

    if (faultActive) {
      switch (s.fault) {
        case 'coolant_leak':
          state.coolantTempC += 0.65 * s.stepSeconds;
          break;
        case 'tyre_leak':
          state.tyrePressurePsi = Math.max(10, state.tyrePressurePsi - 0.04 * s.stepSeconds);
          break;
        case 'alternator_failure':
          state.batteryVoltage = Math.max(9.5, state.batteryVoltage - 0.015 * s.stepSeconds);
          break;
        case 'fuel_siphon':
          if (state.speedKph < 5) state.fuelPercent = Math.max(0, state.fuelPercent - 0.15 * s.stepSeconds);
          break;
        case 'driver_fatigue':
          state.driverFatigueScore = Math.min(100, state.driverFatigueScore + 0.25 * s.stepSeconds);
          break;
      }
    }

    const fuelBefore = state.fuelPercent;
    if (state.speedKph > 0) {
      state.fuelPercent = Math.max(0, state.fuelPercent - 0.004 * s.stepSeconds);
    }
    const fuelDeltaPercent = state.fuelPercent - fuelBefore;

    events.push({
      eventId: `sim-${sequence}`,
      sequence,
      capturedAt: new Date(t * 1000).toISOString(),
      kind: 'telemetry',
      payload: {
        ...state,
        fuelDeltaPercent,
        simulation: true,
        scenarioFault: faultActive ? s.fault ?? null : null,
      },
    });
    sequence++;
  }

  return events;
}
