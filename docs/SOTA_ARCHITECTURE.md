# Fleet Yangu — SOTA architecture direction

Fleet Yangu should be treated as a **cyber-physical fleet intelligence platform**, not merely a GPS tracker. The architecture deliberately separates sensing, reasoning, workflow automation and vehicle actuation.

## 1. Edge intelligence

A trusted telematics gateway can host adapters for OBD-II / CAN / SAE J1939 / UDS, GPS, IMU, TPMS, load cells, cameras, driver-monitoring sensors, smart locks, cargo environmental sensors and driver wearables where legally permitted.

The gateway should use secure boot, signed firmware, hardware-backed device keys, monotonic sequence counters, buffered store-and-forward, watchdogs and strict CAN allowlists.

## 2. Canonical event envelope

Every packet carries organisation, vehicle and device identity; a globally unique event id; schema version; monotonic device sequence; capture/receive timestamps; provenance/calibration metadata; and normalized payload. This supports replay detection, schema evolution, forensic reconstruction and edge/cloud parity.

## 3. Hybrid intelligence

Safety logic uses three tiers:

1. deterministic thresholds for non-negotiable safety limits;
2. explainable statistical anomaly detection for deviations from each vehicle's own baseline;
3. ML models for predictive maintenance, visual damage, driver state and remaining useful life.

Opaque models never become the sole authority for safety-critical actuation.

## 4. Digital twin

Each vehicle twin continuously reconciles mechanical condition, DTC/freeze-frame history, component genealogy, tyre/brake/battery state, fuel/energy state, load/cargo state, driver exposure, route/environment history, service/workshop history, incidents/evidence, cost and emissions. The twin is the state projection; raw events remain immutable.

## 5. Risk graph

Fleet risk is better represented as a graph than a single score. Nodes may include vehicle, driver, route, cargo, component, workshop, depot, charger, insurer and supplier. Edges represent exposure, dependency and confidence. A single user-facing score can still be derived, but the graph preserves causal context.

## 6. Multimodal incident intelligence

An incident bundle can align GPS trajectory, speed/acceleration/yaw, ECU snapshot, ADAS/camera events, driver-state events, cargo state and nearby vehicle/infrastructure context. Evidence should be hashed, timestamped and access-controlled.

## 7. Predictive maintenance

The maintenance stack should support rule-based service intervals, EWMA/change-point anomaly detection, survival/hazard models, remaining-useful-life models, fleet cohort benchmarking, component-specific confidence intervals and workshop feedback loops.

## 8. Zero-trust command plane

Flutter never emits raw CAN frames. High-risk actions use:

request → policy evaluation → dual approval → vehicle-state validation → signed command → trusted gateway → hardware allowlist → actuator

Immobilization is stationary-only by default. Every privileged action is audited.

## 9. Offline-first remote operations

For rural, mining, agriculture and cross-border fleets: local buffering, conflict-safe synchronization, opportunistic upload, compressed telemetry summaries, satellite fallback adapters and edge inference when cloud connectivity is unavailable.

## 10. Observability and SRE

Production deployments should measure packet latency/loss, replay rejection, gateway clock skew, model drift, predictive-maintenance precision/recall, alert acknowledgement time, command-policy denials, evidence completeness, uptime and firmware distribution.
