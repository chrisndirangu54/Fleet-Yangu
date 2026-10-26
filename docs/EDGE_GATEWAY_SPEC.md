# Edge gateway specification

The Fleet Yangu edge gateway is the trust boundary between vehicle networks and the cloud.

Minimum production requirements: secure boot, signed OTA firmware, hardware-backed identity where available, per-device credentials, monotonic sequence numbers, replay-resistant event IDs, encrypted local buffering, watchdog/heartbeat, clock sanity checks, schema-versioned payloads, CAN read allowlists by default, a separate actuator write allowlist and local safety interlocks.

Pipeline:

sensor/CAN frame → adapter → normalization → validation → local policy → event envelope → authenticated uplink → cloud ingestion

When offline, the gateway continues deterministic safety checks, buffers telemetry, prioritizes incidents, compresses lower-value high-frequency data, preserves original sequence and synchronizes without duplicates.

For actuation, the gateway must reject any cloud command that fails local policy even if the cloud marks it approved. Hardware remains the final safety authority.
