# Family OS — Product Refinement V2

> **Status:** ACTIVE
> **Activated:** 2026-09-29
> **Product Ready:** Security & Digital Safety, Learning & Growth, Family Connection, Family Intelligence
> **Current pillar:** Administration, Trust & Operations
> **Current delivery mode:** Product refinement only — no Backend or Native implementation is authorized by this program yet.

## Why this workspace exists

Family OS is being refined as one connected family platform: a parent should experience calm, useful screens and dependable outcomes, while the platform coordinates the complexity of identity, devices, permissions, events, notifications, learning, safety, and support behind the scenes.

This workspace is the governing product record for **Product Refinement V2**. It was activated by the Owner's direction to continue the work as a coherent, global platform and to begin with the security pillar.

## Authority for this program

| Order | Artifact | Purpose |
|---|---|---|
| 1 | `00_PRODUCT_CHARTER.md` | Product direction, boundaries, and quality bar. |
| 2 | `04_DECISION_REGISTER.md` | Accepted and pending product decisions. |
| 3 | `01_PLATFORM_SYSTEM_UNIVERSE.md` | Full system inventory and platform connections. |
| 4 | `02_GLOBAL_DELIVERY_HARNESS.md` | The repeatable discovery-to-readiness workflow. |
| 5 | Pillar packs, beginning with `03_SECURITY_PHASE_INITIATION.md` | Detailed work for one domain at a time. |
| 6 | `LOOP_STATE.md` | Current work pointer only; it never decides scope or phase. |

## Relationship to older material

Earlier plans, policies, registries, implementation notes, screens, and source code are **evidence**. They help identify existing systems, user-facing surfaces, technical reality, and unfinished work. They do not determine Product Refinement V2 priorities, product law, inclusion, exclusion, or release scope.

The current service, journey, and screen registries remain valuable discovery inputs. Their legacy `priority`, `status`, and `wave` columns are not Product Refinement V2 decisions.

## Scope snapshot

- **In current refinement:** the 42 systems and 240 registered services already present in the platform inventory.
- **Future developments:** new candidate systems outside that inventory, including expanded home organization, financial responsibility, expanded values/religion, and one-way audio. They are recorded for future consideration only and are not part of the current build, navigation, data model, or release promise.
- **Current focus:** refine the Administration, Trust & Operations pillar—the shared setup, identity, device, notification, privacy, Today and support spine—before any production execution authorization.

## Runtime truth and backend placement

Production-facing outcomes must be real runtime behaviour, never hidden fixtures or hard-coded family data. Render is the system-of-record backend and hosts paid/usage-dependent workloads; Firebase is limited to individual no-cost auxiliary services after pricing/privacy review. Read `16_RUNTIME_TRUTH_POLICY.md` and `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md` before backend/integration work.

## Non-negotiable platform principle

No system is allowed to become an isolated mini-app. Each system must prove an appropriate connection to the shared family identity, roles and permissions, child/device context, notification center, activity timeline, Today dashboard, privacy/support controls, and—where useful—family intelligence.
