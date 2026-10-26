# Observability and operational intelligence

A production Fleet Yangu deployment should expose health across the complete vehicle-to-cloud chain.

## Core telemetry

### Gateway
- online/offline state
- firmware version
- boot integrity status
- buffer depth
- packet send/retry rate
- clock skew
- last accepted sequence
- radio/satellite link quality

### Ingestion
- accepted/rejected events
- duplicate/replay rejection
- schema validation failure
- end-to-end latency
- per-device rate
- dead-letter volume

### Fleet intelligence
- alert rate by category
- anomaly rate by vehicle cohort
- predictive-maintenance lead time
- precision/recall after workshop outcome
- route-risk calibration
- driver-safety alert confirmation rate

### Agentic operations
- proposals generated
- proposals accepted/rejected
- human override rate
- auto-executed low-risk workflows
- blocked high-risk actuation attempts
- time saved / downtime avoided

### Incident intelligence
- evidence completeness
- upload latency
- missing camera windows
- hash verification status
- time to first response

The objective is not simply infrastructure uptime; it is **decision-quality observability**.
