# Agentic fleet operations

Fleet Yangu agents may observe, reason and propose actions across vehicles, drivers, routes, maintenance, cargo and incidents.

## Allowed autonomous actions

- create low-risk work orders
- draft incident summaries
- prepare dispatcher notifications
- enrich alerts with evidence
- recommend route/vehicle/driver substitutions
- schedule analysis jobs

## Human approval required

- driver reassignment
- high-cost maintenance authorization
- insurance/claims submission
- any action affecting legal/compliance status
- any physical vehicle command

## Never directly autonomous

- raw CAN writes
- moving-vehicle immobilization
- safety-system overrides
- bypass of gateway policy
- deletion of incident evidence

Every recommendation should include confidence, evidence references, model/policy versions and a traceable rationale.
