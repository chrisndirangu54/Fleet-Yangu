# Fleet Yangu ↔ TeknTandao Workspace integration

This repository supplies the **Fleet Yangu side** of a separately deployed, explicit, organization-owner-approved integration. Workspace remains a separate Firebase project and tenant authority. Do not copy an entire Firestore collection into the other project or embed server credentials in the browser.

## What the bridge does

- `fleetYanguIssueWorkspaceKey`: authenticated owner/super_admin callable. Issues a one-time `fyw_` token valid for 90 days, scoped to one Fleet Yangu organization and one Workspace organization. Key is stored as a SHA-256 hash. Default permission is **read-only**; sending trip requests requires `allowDispatch=true` at key issuance.
- `fleetYanguRevokeWorkspaceKey`: owner/super_admin callable. Revokes the key immediately.
- `fleetYanguWorkspaceBridge`: server-to-server HTTPS bridge:
  - `GET /v1/vehicles`: bounded (100 each) vehicle health snapshot, allowlisted engine indicators, sanitized alerts and maintenance work orders. Does not export raw CAN, command requests, driver medical history, camera footage, precise GPS trails or gateway secrets.
  - `POST /v1/dispatch`: optional; receives validated and authenticated trip *requests*, never direct commands. Returns status `awaiting_fleet_dispatcher_review`. Replayed dispatch IDs are idempotent and cannot change a previous request to point to a different shipment or vehicle.

The existing ingestion endpoint (`ingestVehiclePacket`) remains separate; no device sends telemetry straight to Workspace through this bridge. No proof of real hardware connectivity is implied.

## Connection steps

1. Deploy Fleet Yangu Functions, security rules and Flutter app from this branch to your Fleet Yangu Firebase project.
2. Sign in as a Fleet Yangu organization owner/super admin. In **Admin & Security → TeknTandao Workspace connection**, enter your Fleet Yangu organization ID and the target Workspace organization ID, select read-only or explicitly enable dispatch and issue a key.
3. Copy the one-time token; supply it to the Workspace owner securely.
4. Workspace operator configures the **server-only** environment variable `FLEET_YANGU_BRIDGE_URL` as the deployed HTTPS URL of `fleetYanguWorkspaceBridge`, without a trailing `/v1/*` path, and the 32-byte base64 Firebase Secret Manager secret `FLEET_YANGU_ENCRYPTION_KEY`. The key must not be committed to GitHub or embedded in Flutter.
5. In Workspace Fleet/Freight → Fleet Yangu connector, enter Fleet Yangu organization ID and the one-time token. Successful pairing calls the Fleet endpoint to validate scope and source identity before saving an AES-256-GCM encrypted token.
6. Map each Fleet Yangu vehicle to the correct Workspace fleet vehicle, then review health/risk/maintenance summaries.
7. If needed, an authorized Workspace owner can hand off a **booked** shipment to Fleet Yangu for dispatcher review, provided the source key explicitly allows dispatch and vehicle readiness checks pass.
8. When disconnecting, **revoke the source key in Fleet Yangu** and disconnect in Workspace. Connection revocation is not equivalent to deleting operational history.

## Security & operational considerations

- In Fleet Yangu Firestore Rules, `workspaceConnections` must be fully server-only; the wildcard collection rule excludes it.
- All requests use scoped bearer authorization, constant-time token hash comparison, expiry, fixed source/target organization headers, bounded payloads, identity verification and HTTPS for the deployed Cloud Function.
- Add Cloud Armor/API Gateway rate limits, anomaly monitoring and per-tenant export auditing before high-volume production use.
- Disclosing a key permits its scoped reads and optional dispatch. Rotate immediately after compromise.
- Current Fleet Yangu command-control/immobilization features are **not** integrated, even when dispatch is enabled.
- The UI in other Fleet Yangu modules still contains demonstration telemetry; only backend records are exported. Validate device connectivity and the freshness of `lastTelemetryAt` before interpreting risk scores.
- The integration has no automatic background synchronization or notification service yet: Workspace pulls snapshots on demand. Future versions could include event-driven delta sync after consent and retention tests.
