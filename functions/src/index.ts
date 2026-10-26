import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import {onRequest} from 'firebase-functions/v2/https';
import {createHash, timingSafeEqual} from 'node:crypto';
import {initializeApp} from 'firebase-admin/app';
import {FieldValue, getFirestore} from 'firebase-admin/firestore';

initializeApp();
const db = getFirestore();

type Severity = 'info' | 'moderate' | 'high' | 'critical';
type Alert = {type: string; title: string; severity: Severity; detail: string; value?: unknown};

function number(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function bool(v: unknown): boolean { return v === true; }

async function writeAlerts(orgId: string, vehicleId: string, sourceId: string, alerts: Alert[]) {
  if (!alerts.length) return;
  const batch = db.batch();
  for (const alert of alerts) {
    const ref = db.collection('organisations').doc(orgId).collection('alerts').doc();
    batch.set(ref, {
      ...alert,
      vehicleId,
      sourceId,
      createdAt: FieldValue.serverTimestamp(),
      status: 'open',
    });
  }
  await batch.commit();
}

export const processTelemetry = onDocumentCreated(
  'organisations/{orgId}/vehicles/{vehicleId}/telemetry/{eventId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const alerts: Alert[] = [];

    const coolant = number(data.coolantTempC);
    const batteryVoltage = number(data.batteryVoltage, 12.6);
    const tyrePressure = number(data.tyrePressurePsi, 32);
    const tyreTemp = number(data.tyreTempC, 30);
    const brakeLife = number(data.brakeLifePercent, 100);
    const fuelPercent = number(data.fuelPercent, 100);
    const payload = number(data.payloadKg);
    const payloadCapacity = number(data.payloadCapacityKg);
    const speed = number(data.speedKph);
    const batterySoc = number(data.evBatterySoc, 100);
    const fuelDelta = number(data.fuelDeltaPercent);
    const fatigue = number(data.driverFatigueScore);
    const routeRisk = number(data.routeRiskScore);
    const maintenanceRisk = number(data.maintenanceRiskScore);
    const batteryTemp = number(data.evBatteryTempC, 25);

    if (coolant >= 105) alerts.push({type:'coolant_overheat', title:'Engine coolant critical', severity:'critical', detail:`Coolant reached ${coolant}°C`, value:coolant});
    else if (coolant >= 98) alerts.push({type:'coolant_high', title:'Coolant temperature elevated', severity:'high', detail:`Coolant reached ${coolant}°C`, value:coolant});
    if (batteryVoltage > 0 && batteryVoltage < 11.8) alerts.push({type:'battery_low', title:'12V battery voltage low', severity:'high', detail:`Battery voltage ${batteryVoltage}V`, value:batteryVoltage});
    if (tyrePressure > 0 && tyrePressure < 27) alerts.push({type:'tyre_pressure_low', title:'Tyre pressure unsafe', severity:'high', detail:`Pressure ${tyrePressure} psi`, value:tyrePressure});
    if (tyreTemp >= 85) alerts.push({type:'tyre_temperature_high', title:'Tyre temperature critical', severity:'critical', detail:`Tyre temperature ${tyreTemp}°C`, value:tyreTemp});
    if (brakeLife >= 0 && brakeLife < 15) alerts.push({type:'brake_life_low', title:'Brake service critical', severity:'critical', detail:`Estimated brake life ${brakeLife}%`, value:brakeLife});
    if (payloadCapacity > 0 && payload > payloadCapacity) alerts.push({type:'overload', title:'Vehicle overloaded', severity:'critical', detail:`Payload ${payload}kg exceeds ${payloadCapacity}kg`, value:payload});
    if (batterySoc < 15) alerts.push({type:'ev_soc_low', title:'EV state of charge low', severity:'high', detail:`Battery SOC ${batterySoc}%`, value:batterySoc});
    if (batteryTemp >= 55) alerts.push({type:'ev_battery_hot', title:'EV battery temperature high', severity:'critical', detail:`Battery temperature ${batteryTemp}°C`, value:batteryTemp});
    if (fuelDelta <= -12 && speed < 5) alerts.push({type:'fuel_drop_anomaly', title:'Possible fuel siphoning', severity:'high', detail:`Fuel level changed ${fuelDelta}% while vehicle was nearly stationary.`, value:fuelDelta});

    await writeAlerts(event.params.orgId, event.params.vehicleId, event.params.eventId, alerts);

    const vehicleRef = db.collection('organisations').doc(event.params.orgId).collection('vehicles').doc(event.params.vehicleId);
    const healthPenalty =
      (coolant >= 105 ? 18 : coolant >= 98 ? 8 : 0) +
      (tyrePressure > 0 && tyrePressure < 27 ? 12 : 0) +
      (brakeLife < 15 ? 18 : brakeLife < 30 ? 8 : 0) +
      (batteryVoltage > 0 && batteryVoltage < 11.8 ? 10 : 0) +
      (batteryTemp >= 55 ? 18 : 0);
    const healthScore = Math.max(0, Math.min(100, 100 - healthPenalty));
    const loadRisk = payloadCapacity > 0 ? Math.max(0, Math.min(100, (payload / payloadCapacity - 0.75) * 200)) : 0;
    const fleetRiskScore = Math.max(0, Math.min(100,
      (100 - healthScore) * 0.28 + fatigue * 0.18 + routeRisk * 0.18 + maintenanceRisk * 0.20 + loadRisk * 0.16
    ));
    await vehicleRef.set({
      healthScore,
      fleetRiskScore,
      live: {coolantTempC: coolant, batteryVoltage, tyrePressurePsi: tyrePressure, brakeLifePercent: brakeLife, fuelPercent, payloadKg: payload, speedKph: speed, evBatterySoc: batterySoc},
      lastTelemetryAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
);

export const processDriverSafety = onDocumentCreated(
  'organisations/{orgId}/vehicles/{vehicleId}/driverSafetyEvents/{eventId}',
  async (event) => {
    const data = event.data?.data(); if (!data) return;
    const fatigue = number(data.fatigueScore);
    const distraction = number(data.distractionScore);
    const healthRisk = number(data.healthRiskScore);
    const alerts: Alert[] = [];
    if (fatigue >= 75) alerts.push({type:'driver_fatigue', title:'Driver fatigue critical', severity:'critical', detail:`Fatigue score ${fatigue}/100`});
    else if (fatigue >= 60) alerts.push({type:'driver_fatigue', title:'Driver fatigue elevated', severity:'high', detail:`Fatigue score ${fatigue}/100`});
    if (distraction >= 70) alerts.push({type:'driver_distraction', title:'Driver distraction detected', severity:'high', detail:`Distraction score ${distraction}/100`});
    if (healthRisk >= 80) alerts.push({type:'driver_health', title:'Driver health intervention', severity:'critical', detail:'Wearable/health telemetry crossed configured emergency threshold.'});
    await writeAlerts(event.params.orgId, event.params.vehicleId, event.params.eventId, alerts);
  }
);

export const processCargoEvent = onDocumentCreated(
  'organisations/{orgId}/vehicles/{vehicleId}/cargoEvents/{eventId}',
  async (event) => {
    const data = event.data?.data(); if (!data) return;
    const alerts: Alert[] = [];
    if (bool(data.unauthorizedDoorOpen)) alerts.push({type:'cargo_tamper', title:'Unauthorized cargo access', severity:'critical', detail:'Cargo door opened outside an authorized stop/window.'});
    if (bool(data.lockTamper)) alerts.push({type:'lock_tamper', title:'Smart lock tamper detected', severity:'critical', detail:'Physical/electronic tamper event reported by lock controller.'});
    const temp = number(data.cargoTempC, 20);
    const min = number(data.tempMinC, -999); const max = number(data.tempMaxC, 999);
    if (temp < min || temp > max) alerts.push({type:'cold_chain', title:'Cold-chain excursion', severity:'high', detail:`Cargo temperature ${temp}°C outside ${min}–${max}°C range.`});
    await writeAlerts(event.params.orgId, event.params.vehicleId, event.params.eventId, alerts);
  }
);

export const processCameraEvent = onDocumentCreated(
  'organisations/{orgId}/vehicles/{vehicleId}/cameraEvents/{eventId}',
  async (event) => {
    const data = event.data?.data(); if (!data) return;
    const eventType = String(data.type ?? 'camera_event');
    const critical = ['collision_imminent','pedestrian_risk','driver_unresponsive'].includes(eventType);
    if (critical || bool(data.requiresReview)) {
      await writeAlerts(event.params.orgId, event.params.vehicleId, event.params.eventId, [{
        type:eventType, title:'Camera / ADAS safety event', severity:critical ? 'critical' : 'high', detail:String(data.summary ?? eventType),
      }]);
    }
  }
);

export const buildIncidentEvidence = onDocumentCreated(
  'organisations/{orgId}/incidents/{incidentId}',
  async (event) => {
    const data = event.data?.data(); if (!data) return;
    await event.data?.ref.set({
      evidencePackage: {
        status: 'collecting',
        required: ['gps','speed','ecu_snapshot','telemetry_window','camera_events','driver_state','cargo_state'],
        integrity: 'hash_and_timestamp_required',
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge:true});
  }
);

export const autoCreateMaintenance = onDocumentCreated(
  'organisations/{orgId}/alerts/{alertId}',
  async (event) => {
    const data = event.data?.data(); if (!data) return;
    const maintenanceTypes = new Set(['brake_life_low','coolant_overheat','battery_low','tyre_pressure_low','tyre_temperature_high','ev_battery_hot']);
    if (!maintenanceTypes.has(String(data.type))) return;
    const ref = db.collection('organisations').doc(event.params.orgId).collection('workOrders').doc();
    await ref.set({
      vehicleId: data.vehicleId,
      sourceAlertId: event.params.alertId,
      title: data.title,
      priority: data.severity,
      status: 'open',
      automation: 'alert_to_work_order',
      createdAt: FieldValue.serverTimestamp(),
    });
  }
);

export const guardCommandExecution = onDocumentUpdated(
  'organisations/{orgId}/commandRequests/{commandId}',
  async (event) => {
    const before = event.data?.before.data(); const after = event.data?.after.data();
    if (!before || !after || before.status === after.status || after.status !== 'approved') return;

    const approvals = Array.isArray(after.approvals) ? after.approvals : [];
    const stationary = after.vehicleState?.stationary === true;
    const gatewayTrusted = after.vehicleState?.gatewayTrusted === true;
    const allowed = new Set(['unlock_trunk','unlock_hood','unlock_fuel_cap','unlock_battery_compartment','immobilize_when_stationary']);
    const commandType = String(after.commandType ?? '');

    if (approvals.length < 2 || !stationary || !gatewayTrusted || !allowed.has(commandType)) {
      await event.data?.after.ref.set({
        status: 'rejected_by_safety_guard',
        rejection: {approvals: approvals.length, stationary, gatewayTrusted, allowedCommand: allowed.has(commandType)},
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge:true});
      return;
    }

    await event.data?.after.ref.set({
      status: 'ready_for_trusted_gateway',
      // No CAN/actuator command is emitted here. A separately authenticated gateway
      // integration must verify the signed request and hardware-specific safety policy.
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge:true});
  }
);


export const ingestVehiclePacket = onRequest(async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({error:'POST required'}); return; }
  const orgId = String(req.body?.orgId ?? '');
  const vehicleId = String(req.body?.vehicleId ?? '');
  const deviceId = String(req.body?.deviceId ?? '');
  const kind = String(req.body?.kind ?? 'telemetry');
  const payload = req.body?.payload;
  if (!orgId || !vehicleId || !deviceId || !payload || typeof payload !== 'object') {
    res.status(400).json({error:'orgId, vehicleId, deviceId and payload are required'}); return;
  }

  const auth = String(req.headers.authorization ?? '');
  if (!auth.startsWith('Bearer ')) { res.status(401).json({error:'Device token required'}); return; }
  const token = auth.slice(7);
  const tokenHash = createHash('sha256').update(token).digest();

  const deviceRef = db.collection('organisations').doc(orgId).collection('devices').doc(deviceId);
  const deviceSnap = await deviceRef.get();
  if (!deviceSnap.exists) { res.status(401).json({error:'Unknown device'}); return; }
  const storedHex = String(deviceSnap.data()?.tokenHashSha256 ?? '');
  let stored: Buffer;
  try { stored = Buffer.from(storedHex, 'hex'); } catch { res.status(401).json({error:'Invalid device credential'}); return; }
  if (stored.length !== tokenHash.length || !timingSafeEqual(stored, tokenHash)) {
    res.status(401).json({error:'Invalid device credential'}); return;
  }
  if (deviceSnap.data()?.vehicleId !== vehicleId || deviceSnap.data()?.status === 'revoked') {
    res.status(403).json({error:'Device is not authorized for this vehicle'}); return;
  }

  const allowedKinds = new Set(['telemetry','diagnostics','driverSafetyEvents','cameraEvents','cargoEvents','inspections']);
  if (!allowedKinds.has(kind)) { res.status(400).json({error:'Unsupported packet kind'}); return; }

  const sequence = Number(req.body?.sequence);
  if (!Number.isSafeInteger(sequence) || sequence < 0) {
    res.status(400).json({error:'A non-negative integer sequence is required'}); return;
  }

  const eventId = String(req.body?.eventId ?? '');
  if (!eventId || eventId.length > 128) {
    res.status(400).json({error:'A valid eventId is required'}); return;
  }

  const eventRef = db.collection('organisations').doc(orgId)
    .collection('vehicles').doc(vehicleId).collection(kind).doc(eventId);

  try {
    await db.runTransaction(async (tx) => {
      const freshDevice = await tx.get(deviceRef);
      const device = freshDevice.data() ?? {};
      const lastSequence = Number(device.lastSequence ?? -1);
      if (sequence <= lastSequence) {
        throw new Error('REPLAY_OR_OUT_OF_ORDER');
      }

      const existingEvent = await tx.get(eventRef);
      if (existingEvent.exists) {
        throw new Error('DUPLICATE_EVENT');
      }

      tx.set(eventRef, {
        ...payload,
        deviceId,
        schemaVersion: String(req.body?.schemaVersion ?? '1.0'),
        gatewaySequence: sequence,
        capturedAt: req.body?.capturedAt ?? null,
        provenance: req.body?.provenance ?? {},
        serverReceivedAt: FieldValue.serverTimestamp(),
      });
      tx.set(deviceRef, {
        lastSequence: sequence,
        lastSeenAt: FieldValue.serverTimestamp(),
      }, {merge:true});
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'INGESTION_REJECTED';
    if (message === 'REPLAY_OR_OUT_OF_ORDER' || message === 'DUPLICATE_EVENT') {
      res.status(409).json({error:message}); return;
    }
    throw error;
  }

  res.status(202).json({accepted:true, eventId});
});
