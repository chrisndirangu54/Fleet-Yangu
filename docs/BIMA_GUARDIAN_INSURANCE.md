# Fleet Yangu ↔ Bima Guardian insurance (quote-first)

## Implementation
Fleet Yangu → **Bima Guardian Insurance** now offers:
- Purpose-specific, 30-day renewable consent through `fleetYanguAuthorizeBimaGuardian`.
- Backend-only indicative `motor:fleet` and `motor:commercial` quotes.
- A manual policy registry with dates, expiry watch, source attribution and **unverified** status.
- Local incident claim drafts (**not submitted to Bima Guardian or insurers**).
- Owner/admin-only Firestore operations through callable Cloud Functions; all `insurancePermissions`, `insuranceQuotes`, `insurancePolicies` and `insuranceClaims` documents are denied direct client access.

Backend files: `functions/src/bima_guardian_insurance.ts`, `functions/src/bima_guardian_domain.ts`. UI: `lib/features/insurance/bima_guardian_screen.dart`. Access from the Fleet Yangu navigation.

## Setup
1. Configure a **private server-side** Bima Guardian gateway, backed by the Bima Guardian `customer_app/insurance-api` service and official insurer relationships. It is currently local-only at `127.0.0.1:8787` and uses a local/demo key without operator-provided configuration. **Do not expose the development server publicly.**
2. On the Fleet Yangu Firebase Functions service, set `BIMA_API_BASE_URL` to the trusted managed HTTPS gateway origin and provide `BIMA_API_KEY` using Firebase Secret Manager. Restrict upstream ingress, add quotas, logging, managed key rotation and TLS.
3. Deploy Functions, Firestore rules and Flutter. Sign in as an organization owner/super_admin/admin.
4. Open **Bima Guardian Insurance**, enter a Fleet Yangu organisation ID, load existing vehicles, authorize limited data sharing, choose cover and request an indicative quote.
5. Store an *existing* insurer policy number/expiry for renewal watch. It remains tagged `verificationStatus:unverified` until verified with the insurer through a separate approved workflow.
6. Create a local claim draft if needed. No payment, issuance, claim submission or settlement takes place through this feature.

The server sends **only** `{product:'motor', subtype, sumInsured, audience:'fleet_logistics'}` to Bima Guardian for quotation. It does not export driver biometrics, names, health histories, exact GPS positions, raw ECU telemetry, VIN, policy documents or incident evidence.

Bima Guardian's API responds with `source: 'demo'` where no approved paired rate card and matching PDF template exist. These prices must be labeled **indicative/demo** and cannot be treated as a confirmed policy or regulatory filing. An uploaded rate card is still not evidence of an insurer agreeing to bind cover.

## Production gates
- Obtain authorized insurer/API access and approved rate-card/wording, verify intermediaries and distribution permissions, and comply with applicable Kenyan insurance and privacy requirements.
- Enforce documented, purpose-specific consent and disclosure logs; introduce revocation and renewal reminders only after end-to-end user testing.
- Build signed insurer policy verification and claims intake APIs before claiming live coverage.
- Evaluate login/session access and Firestore security rules with integration/emulator tests.
- Validate quote correctness and rate-card currency units against the real Bima Guardian API. No locally created policy or claim draft is insurer-confirmed.
