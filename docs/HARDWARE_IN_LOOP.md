# Hardware-in-the-loop (HIL) readiness

Fleet Yangu should validate integrations against a simulator before a physical vehicle is connected.

## Test ladder

1. Pure software simulation of normalized telemetry.
2. Recorded-trace replay from known vehicles.
3. CAN/J1939 adapter connected to a bench simulator.
4. Gateway connected to a non-moving vehicle with read-only permissions.
5. Controlled proving-ground validation.
6. Limited production pilot with alert-only mode.
7. Gradual enablement of approved automations.

## Fault scenarios

The simulator should inject coolant leaks, alternator failure, tyre-pressure loss, fuel siphoning, driver fatigue, GPS loss, gateway clock skew, packet replay, delayed packets and cargo temperature excursions.

## Acceptance criteria

For each scenario track time-to-detect, false positives, missed detections, alert severity, evidence completeness, work-order correctness and whether any policy attempted unsafe actuation.

No actuator feature should be enabled solely because it passed software simulation.
