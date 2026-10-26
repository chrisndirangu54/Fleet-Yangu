# Model governance

Fleet Yangu treats machine learning as a governed production subsystem.

Every production model should record model name/version, training lineage, feature schema, code revision, checksum, calibration metrics, precision/recall, activation time, rollback target, owner/reviewer and whether it is safety-critical.

Safety-critical models should not be promoted automatically on aggregate accuracy alone. Promotion should consider precision, recall, calibration, subgroup performance, drift indicators, false-negative review, shadow-mode results and rollback readiness.

Runtime monitoring should include feature missingness, distribution drift, prediction shift, calibration drift, maintenance prediction precision/recall, incident-classification false negatives, anomaly rate and inference latency.

Recommendations must retain the evidence that generated them. Safety-critical actuation remains governed by deterministic policy and trusted gateway controls even when AI contributes a recommendation.
