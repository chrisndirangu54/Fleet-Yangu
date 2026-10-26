# Fleet Yangu

Fleet Yangu is a Flutter + Firebase **cyber-physical fleet intelligence and vehicle operations platform**. It combines fleet tracking, ECU diagnostics, predictive maintenance, driver safety, smart vehicle security, camera/ADAS events, cargo intelligence, incident evidence, cost analytics, compliance and guarded automation in one application.

## What is included

### Vehicle intelligence
- GPS tracking, trip history, geofencing and route deviation
- OBD-II, CAN, SAE J1939 and UDS diagnostic event model
- DTC/freeze-frame workflows and live engine telemetry
- Vehicle health score and multi-factor fleet risk score
- Predictive maintenance and alert-to-work-order automation
- Digital twin / lifecycle history for every vehicle

### Mechanical, fuel and energy
- Fuel efficiency and suspicious fuel-drop detection
- Tank/ECU reconciliation architecture
- 12V battery monitoring and parasitic-drain capability
- EV SOC, battery temperature, health and charging domain
- TPMS, tyre temperature, puncture/wear capability
- Brake-life, ABS and stopping-risk capability
- Payload/axle loading and overload risk

### Safety and driver operations
- Drowsiness/fatigue and distraction event processing
- Driver health/wearable integration domain
- Driver identity and authorization (face/NFC/fingerprint adapters)
- Driver behaviour, rest/shift and seatbelt capability
- Panic/SOS and two-way mission communication capability
- Route-risk and dynamic dispatch

### Security, locks and cameras
- Smart hood, trunk/cargo, fuel-cap and battery-compartment locks
- Tamper and unauthorized cargo-access alerts
- Anti-theft and unauthorized towing/movement capability
- Dashcam, cabin and 360-degree camera event pipeline
- ADAS events: collision risk, lane, tailgating, blind spot, pedestrian/cyclist capability
- Guarded stationary-only immobilization workflow
- ANPR/smart-gate integration capability

### Cargo, incidents and inspections
- Cargo door, temperature/humidity, shock/vibration and cold-chain workflows
- Crash/incident records and automatic evidence-package initialization
- Pre/post-trip inspections and driver sign-off
- Visual damage/defect workflow for body, tyres, lights and mirrors
- Defect-to-maintenance workflow architecture

### Business operations
- Cost/km and asset-utilization dashboards
- Carbon/emissions capability
- Insurance, inspection, driver-certification and claims domains
- Workshop/parts matching and repair-quality capability
- Residual-value and replacement-timing capability
- Fleet AI copilot boundary for natural-language analysis and reports
- Offline/store-and-forward and satellite-fallback architecture

## Flutter UI

The responsive Flutter command center exposes the entire module set with demo telemetry so the product can be explored before real hardware is connected. Replace the demo repository with Firestore providers as each deployment source goes live.

## Firebase backend

Cloud Functions currently implement:

- telemetry threshold/anomaly processing
- vehicle live-state update
- heuristic health and fleet-risk scoring
- driver fatigue/distraction/health alerts
- cargo tamper and cold-chain alerts
- camera/ADAS review alerts
- automatic maintenance work-order creation
- incident evidence-package initialization
- authenticated hardware packet ingestion
- safety guard for high-risk command requests

## Hardware gateway

```text
ECU / CAN / J1939 / UDS
GPS / IMU / TPMS / load cells
locks / cameras / cargo sensors / wearables
               ↓
      trusted telematics gateway
               ↓
       HTTPS / cellular / Wi-Fi
               ↓
     Firebase ingestion + analytics
               ↓
      Flutter Fleet Yangu clients
```

The ECU path is read-only by default. Flutter never sends raw CAN frames. High-risk controls use a separate approval-based command request whose server-side guard requires two approvals, a stationary vehicle and a trusted gateway before a request can advance. Production hardware must still enforce its own allowlist and safety checks.

## Firebase setup

1. Install Flutter and Firebase CLI.
2. Create a Firebase project.
3. Enable Authentication, Firestore, Storage, Messaging and Functions.
4. Run `flutterfire configure` to generate platform Firebase configuration.
5. Run `flutter pub get`.
6. In `functions/`, run `npm install && npm run build`.
7. Deploy with `firebase deploy` after reviewing environment-specific security settings.
8. Register telematics gateways in `organisations/{orgId}/devices/{deviceId}` with a SHA-256 hash of the device bearer token and the bound `vehicleId`.
9. Connect real OBD/CAN/J1939 hardware through the documented ingestion API or substitute a managed IoT gateway/mTLS adapter.

## Security notes

- Do not place privileged API keys or device secrets in Flutter.
- Rotate gateway credentials and add replay protection/rate limits in production.
- Use App Check for client-originated Firebase traffic where supported.
- Camera/incident evidence should receive retention, consent and access policies appropriate to the deployment jurisdiction.
- Health/wearable information needs explicit consent and strict access separation.
- Vehicle actuation must remain hardware-vendor and jurisdiction aware.

See `docs/ARCHITECTURE.md` and `docs/FEATURE_MATRIX.md` for implementation boundaries and the full feature matrix.


## SOTA engineering layer

The repository now includes:

- canonical versioned telemetry envelopes with provenance, timestamps and monotonic device sequence numbers
- replay and duplicate-event rejection at the authenticated gateway boundary
- deterministic safety thresholds plus an explainable EWMA anomaly detector
- a zero-trust command-policy mirror for stationary-only and dual-approval controls
- CI for Flutter analysis/tests and TypeScript Cloud Functions builds
- baseline unit tests for risk escalation and anomaly detection
- a SOTA architecture covering edge intelligence, hybrid ML, digital twins, risk graphs, multimodal incident reconstruction, predictive-maintenance feedback loops, offline/satellite operations and SRE telemetry

See `docs/SOTA_ARCHITECTURE.md` for the design direction.
