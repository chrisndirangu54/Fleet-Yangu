# Feature registry and online feature contract

A SOTA fleet ML stack needs consistent definitions between training and serving.

Each feature should define:

- name and entity
- type and unit
- freshness/max age
- provenance
- calibration requirements
- safety relevance
- owner
- transformation version

Examples: coolant temperature, rolling fuel-efficiency delta, brake wear rate, tyre-pressure slope, route risk, driver fatigue score, battery-voltage variance and component age.

The feature registry prevents silent mismatches such as Celsius vs Fahrenheit, psi vs kPa, stale sensor values or training-serving skew.
