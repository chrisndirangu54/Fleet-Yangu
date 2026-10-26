# Threat model

Primary assets include vehicle control, ECU/CAN integrity, driver/passenger safety, incident evidence, driver identity and health data, location history, device credentials and command approvals.

Representative threats include stolen gateway tokens, replayed telemetry, fabricated GPS/fuel data, compromised mobile clients, insider misuse, malicious firmware, CAN injection, evidence deletion, clock manipulation, model poisoning/drift and cross-tenant access.

Controls include device-bound authentication, monotonic sequence and event-id deduplication, tenant-scoped rules, immutable event streams, dual approval, stationary-state checks, signed firmware, hardware allowlists, append-only evidence, audit logs, model governance and secret isolation from Flutter clients.

This is a baseline, not a substitute for a formal safety/security assessment of a deployed hardware configuration.
