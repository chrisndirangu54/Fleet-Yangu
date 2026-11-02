import test from 'node:test';
import assert from 'node:assert/strict';
import {validFleetInsuranceRequest,parseBimaQuote,policyRecord,renewalStatus}
  from '../bima_guardian_domain';

test('insurance quote request drops raw GPS, ECU and personal telemetry',()=>{
  const safe=validFleetInsuranceRequest({vehicleId:'vehicle_4',
    subtype:'fleet',sumInsured:2000000,driverName:'private',
    gpsTrail:[1,2],ecuDiagnostic:'restricted'});
  assert.deepEqual(safe,{vehicleId:'vehicle_4',product:'motor',
    subtype:'fleet',sumInsured:2000000,audience:'fleet_logistics'});
  assert.throws(()=>validFleetInsuranceRequest({vehicleId:'x',
    subtype:'cargo',sumInsured:2000000}),/cover/);
});
test('demo price is indicative and never insurer-confirmed',()=>{
  const parsed=parseBimaQuote({source:'demo',id:'quo_test',options:[
    {insurerName:'Example',insurerId:'example',premium:1000,
      userMedical:'not-exported'}]});
  assert.equal(parsed.source,'demo');
  assert.equal(parsed.verifiedInsurer,false);
  assert.equal(parsed.options.length,1);
  assert.equal(JSON.stringify(parsed).includes('not-exported'),false);
  assert.throws(()=>parseBimaQuote({source:'uploaded',options:null}));
});
test('manually recorded policies are not verified coverage',()=>{
  const record=policyRecord({vehicleId:'vehicle_1',insurer:'Example Insurance',
    policyNumber:'PX-001',subtype:'fleet',effectiveFrom:'2026-01-01',
    expiresOn:'2026-11-25'});
  assert.equal(record.verificationStatus,'unverified');
  assert.equal(record.insuranceStatus,'record_only');
  const renewed=renewalStatus(record,new Date('2026-11-02T00:00:00Z'));
  assert.equal(renewed.daysToExpiry,23);
  assert.equal(renewed.activeCoverage,false);
  assert.throws(()=>policyRecord({...record,expiresOn:'2025-01-01'}));
});
