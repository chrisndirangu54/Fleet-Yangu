# Data retention and privacy classes

Fleet Yangu data should be classified before deployment.

## Suggested classes

- **Vehicle telemetry:** operational retention based on fleet analytics needs.
- **Raw camera footage:** short retention unless tied to an incident or legal requirement.
- **Incident evidence:** protected, access-controlled, integrity-checked retention.
- **Driver identity:** restricted personnel/security data.
- **Driver health/wearables:** highly restricted and explicit-consent data.
- **Location history:** sensitive operational data.
- **Audit logs:** longer-lived security and compliance records.
- **Model training snapshots:** de-identified/minimized where possible.

Retention must be configurable by tenant and jurisdiction. Deletion workflows should never silently remove evidence that is under an active legal or incident hold.
