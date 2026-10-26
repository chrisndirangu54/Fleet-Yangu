# Fleet Yangu architecture

## Vehicle edge

Fleet Yangu assumes a trusted telematics gateway between the application and vehicle networks. The gateway can host adapters for OBD-II, CAN, SAE J1939 and manufacturer-specific UDS profiles, GPS, IMU, TPMS, load cells, smart locks, cameras, environmental sensors and optional driver wearables.

The default policy is **read-only ECU access**. Actuation is separated into a command-control plane and is never executed directly by Flutter or a Cloud Function. A real deployment should use secure boot, signed firmware, hardware-backed keys, CAN allowlists, local rate limiting and fail-closed policies.

## Cloud ingestion

`ingestVehiclePacket` accepts authenticated device packets using a bearer device token whose SHA-256 hash is stored in the device registry. Production deployments should additionally use device certificate/mTLS or a managed IoT gateway, token rotation, replay protection, per-device quotas and a dedicated secrets system.

Supported packet domains:

- telemetry
- diagnostics
- driverSafetyEvents
- cameraEvents
- cargoEvents
- inspections

Firestore triggers normalize alerts, update live vehicle state, calculate health/risk indicators, create maintenance work orders and start incident evidence workflows.

## Control plane

High-risk controls use `commandRequests` rather than direct writes to an actuator. The current guard requires two approvals, a stationary vehicle, a trusted gateway and an allowlisted command before marking a request as ready for the trusted gateway. The cloud function intentionally does **not** emit raw CAN frames.

## Firebase domains

- `vehicles` — registry, health, risk and latest state
- vehicle subcollections — telemetry, diagnostics, driver safety, camera, cargo and inspections
- `drivers` — identity, certifications, shift state and safety scores
- `trips` — dispatch, routes, geofences and costs
- `alerts` — derived risk/anomaly events
- `incidents` — crash/SOS and evidence workflows
- `workOrders` — predictive and scheduled maintenance
- `devices` — gateway trust and credentials
- `commandRequests` — guarded smart-lock/immobilization workflows
- `auditLogs` — privileged event history
- `workshops`, `parts`, `policies`, `compliance`, `chargers`, `geofences` — operational integration domains

## AI/ML boundaries

The repository includes the data flow required for anomaly detection, predictive maintenance, visual damage inspection, driver-state models and a fleet copilot. Model inference should run through backend/provider adapters so privileged API keys never live in Flutter. Recommendations must retain the source telemetry and confidence metadata needed for human review.
