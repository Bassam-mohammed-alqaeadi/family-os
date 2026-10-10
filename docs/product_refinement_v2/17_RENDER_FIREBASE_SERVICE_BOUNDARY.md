# Render + Firebase Service Boundary & Cost Policy

> **Status:** Active architecture and cost policy
> **Decision:** PRV2-021
> **Last pricing-source review:** 2026-09-29; every integration must re-check current terms before implementation.

## 1. Architecture decision

- **Render is the primary backend platform and system of record.**
- **Firebase is an auxiliary client/service toolkit only when a selected Firebase feature is genuinely no-cost under current terms and passes privacy/cost review.**
- **Any Firebase feature that needs a paid plan, Cloud Billing, Blaze dependency, paid quota, or an uncertain future charge is not part of the production path. Its workload belongs on Render or an explicitly approved Render-operated alternative.**

This policy does not mean all Render infrastructure is free. It means the platform’s paid/usage-dependent backend responsibility and cost control live in the Render architecture rather than being scattered across Firebase billing products.

## 2. Render owns

| Responsibility | Render placement |
|---|---|
| Public authenticated API / BFF | Render web service(s). |
| Family, identity, role, device, policy, content, conversation, calendar, task, event and audit data | Render-managed/Render-connected durable datastore selected during execution; Render service is the authoritative access boundary. |
| Authorization and session/token verification | Render API/domain layer; Firebase tokens may be verified only if Firebase Auth is explicitly approved as a no-cost identity provider. |
| Realtime product events | Render realtime/WebSocket service with a durable shared state/queue strategy. Render documents WebSocket support; reconnect, ordering and horizontal scaling are product responsibilities. |
| Background jobs | Render background worker/queue or scheduled job for notifications, media/AI work, report aggregation, delivery retries and cleanup. |
| Paid/usage-dependent processing | Render services/workers and approved Render-operated or Render-connected dependencies. |
| Data exports, audit/support endpoints, admin operations | Render private/admin services with least-privilege access. |
| Product feature flags / server-authoritative configuration | Render configuration/domain layer; client configuration is never the sole authority for a safety or entitlement decision. |

## 3. Firebase may be considered only for explicitly approved no-cost auxiliary use

The official Firebase pricing page currently lists no-cost products including Analytics, App Check, App Distribution, Cloud Messaging, Crashlytics, In-App Messaging, Performance Monitoring, and Remote Config. Current terms can change; this list is a candidate set, not blanket approval.

| Candidate Firebase capability | Permitted role if approved | Forbidden role / condition |
|---|---|---|
| Cloud Messaging (FCM) | Push transport from a trusted Render backend to registered clients. | Never the source of truth for alert, message, task, SOS, delivery or read state. Render owns the event/receipt lifecycle. |
| Crashlytics / Performance | Privacy-minimized client reliability telemetry. | No child message/media/location/raw learning content or sensitive identifiers. |
| App Check | Client attestation signal protecting Render APIs where technically appropriate. | Not a substitute for Render authorization, rate limiting, or server-side validation. |
| Analytics | Consentful, minimized product measurement. | No sensitive child-content tracking; no source of truth for product state. |
| Remote Config | Non-critical presentation/experiment configuration mirrored/controlled by Render policy. | Cannot independently enable sensitive controls, alter authorization, enforce safety rules, or become the sole feature source. |
| Firebase Authentication | Optional identity-token provider only if the exact selected provider stays within accepted no-cost terms and Render owns roles/family/authorization. | Phone/SMS auth and any billing-required flow are excluded. Firebase Auth does not become the family system of record. |

## 4. Explicitly excluded Firebase production paths unless Owner changes policy

- Firestore / Realtime Database as the authoritative Family OS database.
- Firebase Storage as production media/file storage.
- Cloud Functions, Cloud Run, or other Firebase/Google Cloud workloads requiring paid billing as a core product service.
- Phone authentication, SMS verification, SMS MFA, or any SMS-dependent flow.
- Any service that requires Blaze, billing-account attachment, paid quota, or automatic overage.
- Firebase-hosted AI, content processing, background work, or analytics data export that creates uncontrolled paid dependencies.

Firebase documentation currently states that phone/SMS authentication requires billing/pay-as-you-go conditions; it is therefore outside this policy without a later explicit alternative decision.

## 5. Required integration approval record

Before any Firebase SDK enters a production target, the implementation card must record:

1. Exact Firebase product and intended limited role.
2. Official pricing URL and review date.
3. Selected plan and confirmation that no billing account/paid dependency is required for that flow.
4. Current documented quota and behavior when quota is exhausted.
5. Data classification, consent, privacy minimization, and deletion/retention implications.
6. Render source-of-truth service that owns the product event/state.
7. Kill switch and fallback when the Firebase feature is unavailable, limited, or pricing changes.
8. Owner/architecture approval.

### Recorded owner decisions

- **2026-10-10 — Google Maps billing (owner: Taha).** Google Maps is approved for the
  safety phase **now** (ش٦ live map / places: Maps SDK + geocoding). When the free quota
  runs out, the owner has approved **subscribing to the Google Maps billing plan** —
  an explicit, written owner decision under §6 ("no automatic billing enablement …
  without an explicit Owner decision recorded in the decision register"). Scope is
  limited to Google Maps usage for the safety phase; **no** Firebase Blaze migration,
  Cloud Functions/Run workload, or any other paid service is authorized by this record.
  (Owner decision text: "Google Maps now; subscribe when the free quota runs out.")

## 6. Cost and reliability controls

- No automatic Firebase billing enablement or Blaze migration without an explicit Owner decision recorded in the decision register.
- Alert on quota/budget/plan changes before a user-facing feature degrades.
- The product must fail honestly when FCM or another auxiliary service is unavailable; it must not mark a notification/action delivered merely because a send attempt occurred.
- Render background workers are paid infrastructure in current Render documentation; use them only where a verified asynchronous workload needs them and include cost/queue/rollback planning.
- Render WebSockets require reconnect/keepalive, routing, and horizontal-scaling design; realtime state remains durable outside a single connection instance.
- All secrets live in Render environment/secret management at execution time, never in Flutter source or repository documentation.

## 7. Official references

- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/)
- [Firebase Authentication limits](https://firebase.google.com/docs/auth/limits)
- [Firebase Authentication FAQ](https://firebase.google.com/docs/auth/faq-and-troubleshooting)
- [Render WebSockets](https://render.com/docs/websocket)
- [Render backend/service architecture](https://render.com/docs/render-vs-vercel-comparison)
- [Render background workers](https://render.com/docs/deploy-celery)
