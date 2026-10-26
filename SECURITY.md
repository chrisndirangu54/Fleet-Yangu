# Security policy

Fleet Yangu interacts with cyber-physical vehicle systems, so security reports involving device identity, authorization, command workflows, CAN/J1939 integrations, cross-tenant access, location history or incident evidence should be treated as high priority.

## Reporting

Do not publish a working exploit in a public issue. Report enough detail to reproduce the problem safely, including affected component, attack prerequisites, expected impact and whether physical vehicle access is required.

## Safety boundary

The repository is designed so Flutter and cloud workflows do not directly emit arbitrary raw CAN commands. Production gateway implementations must independently enforce signed firmware, device identity, local policy, command allowlists, stationary-state restrictions and fail-safe behavior.

## Secrets

Never commit Firebase service credentials, gateway tokens, private signing keys, insurer API secrets or camera/storage credentials.

## Deployment responsibility

This repository is an engineering foundation, not a vehicle safety certification. Any deployment capable of physical actuation requires hardware-specific safety validation, threat modeling, jurisdiction review and controlled testing.
