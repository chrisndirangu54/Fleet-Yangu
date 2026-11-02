import test from 'node:test';
import assert from 'node:assert/strict';
import {safeVehicleSummary} from '../workspace_bridge';

test('Fleet Yangu exports only allowlisted vehicle measurements',()=>{
  const result=safeVehicleSummary('v1',{
    registration:'KAB 123A',status:'active',healthScore:82,fleetRiskScore:21,
    driverMedicalHistory:{diagnosis:'private'},
    secretDeviceToken:'redacted',
    lastTelemetryAt:{toDate:()=>new Date('2026-11-02T11:00:00Z')},
    live:{coolantTempC:95,fuelPercent:64,speedKph:60,
      canFrame:'sensitive',driverGpsTrail:['secret'],batteryVoltage:12.5}
  });
  assert.equal(result.healthScore,82);
  assert.equal(result.telemetry.speedKph,60);
  assert.equal(result.lastTelemetryAt,'2026-11-02T11:00:00.000Z');
  assert.equal(JSON.stringify(result).includes('private'),false);
  assert.equal(JSON.stringify(result).includes('redacted'),false);
  assert.equal(JSON.stringify(result).includes('canFrame'),false);
});

test('Invalid sensor values are omitted, not treated as healthy data',()=>{
  const result=safeVehicleSummary('v2',{
    registration:'KBB 991',healthScore:120,fleetRiskScore:-4,
    live:{coolantTempC:Infinity,fuelPercent:101,speedKph:-2}
  });
  assert.equal(result.healthScore,null);
  assert.equal(result.fleetRiskScore,null);
  assert.equal(result.telemetry.fuelPercent,null);
  assert.equal(result.telemetry.speedKph,null);
});
