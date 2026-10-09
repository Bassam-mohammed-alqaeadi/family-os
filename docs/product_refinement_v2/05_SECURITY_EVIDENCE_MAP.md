# Security Evidence Map — SEC-DISCOVERY-01

> **Status:** Evidence baseline complete; product conclusions remain in discovery.
> **Inspected:** 2026-09-29
> **Purpose:** Separate what the repository demonstrably contains from what a production security platform can truthfully promise.

## 1. Evidence rules

| Label | Meaning |
|---|---|
| **Observed UI/domain evidence** | A screen, model, repository seam, local runtime, test, or core policy exists in the current Flutter source. |
| **Observed local persistence** | The current app records/restarts state locally; this is not multi-device synchronization or remote delivery. |
| **Not yet evidenced** | The repository does not currently demonstrate the platform integration required to promise the behaviour in production. |
| **Product decision pending** | Existence in code or registry does not decide that the system belongs in the first release. |

## 2. Current technical reality

### Observed

- The app is a Flutter application explicitly described in `app/pubspec.yaml` as **mock-first**.
- Local state tooling is present: `sqflite`, `path`, `path_provider`, and multiple preferences-shaped persistence adapters.
- There are 295 Dart test files in `app/test`, including security-domain, local persistence, and widget-level tests. Their presence is evidence of test intent and coverage assets; this review did not execute Flutter tests because the SDK is intentionally not installed in this workspace.
- The Android host is a standard `FlutterActivity` in `app/android/app/src/main/kotlin/.../MainActivity.kt`.
- Android manifests currently declare only the development INTERNET permission; there are no declared services, receivers, usage-access, accessibility, device-admin, location, or other enforcement permissions in the examined manifests.
- The iOS host is the standard Flutter `AppDelegate`; no entitlement file or declared Screen Time / Family Controls / location / background capability was found in the inspected iOS project.

### Not currently evidenced

- No Flutter `MethodChannel` or `EventChannel` implementation was found.
- No production HTTP client, Firebase, Dio, gRPC, or WebSocket integration was found in the Flutter source. References to Firebase are comments, labels, or explicit “not implemented” explanations—not proof of a Firebase integration.
- No Android service, accessibility service, device-admin receiver, background location implementation, usage-statistics adapter, or app-blocking adapter is present.
- No iOS Family Controls, Managed Settings, Device Activity, or related entitlement/approval implementation is present.
- Therefore, the current repository does **not** prove real remote command delivery, device-level enforcement, continuous location tracking, push delivery, social/content monitoring, or production emergency delivery.

### V2 capability truth

The application has valuable UX, domain, local persistence, and test evidence. It must be described today as a **local/mock-first product foundation**, not as a native-enforced or remote-connected parental-control product. The eventual Security build plan must close this gap without changing the approved information architecture.

## 3. Security system evidence map

| System | Observed UI/domain evidence | Local/test evidence | Production gap to resolve | Current V2 state |
|---|---|---|---|---|
| Screen-time management | `n03_screen_time` includes parent/child time screens, expiry, time requests, app denial, reports, UX bridge; core screen-time runtime and policy structures exist. | Screen-time policy, restart/persistence, time-request, screen/widget tests exist. | Device-level time collection/enforcement, remote synchronization, conflict ordering, and platform-specific behaviour. | Active discovery. |
| Application controls | Child app list, app approval, access-rule models, and app-control runtime exist. | Local seed/mock and policy tests exist. | Installed-app inventory, enforcement/allowlist integration, app-store approval flows, and device-specific delivery. | Active discovery. |
| Web filtering | `n04_web_filter` includes filter, block page, temporary unlock flow, home-router filter; core filter engine, enforcement/document models, and policy repositories exist. | Filter-enforcement, temporary-allow persistence, unlock-loop, and widget tests exist. | Browser/network/DNS/VPN enforcement model, supported-surface contract, remote delivery, and transparent fallback. | Active discovery. |
| Location and safe places | Day area includes map, history, safe zones, arrival and location UX bridge; core geofence/location types and evaluators exist. | Location/geofence and related screen tests exist. | Device GPS/background collection, permission lifecycle, stale/accuracy model, remote updates, travel/time-zone behaviour. | Active discovery. |
| Emergency and SOS | Emergency setup, child SOS button/in-progress, alert surfaces; a substantial `sos_final` lifecycle/escalation/readiness domain exists. | SOS lifecycle, resolver, cross-system, ladder, and screen tests exist. | Actual push/SMS/call/notification transport, location handoff reliability, offline guarantees, emergency response operations. | Active discovery. |
| Smart content monitoring | `offline_ai_safety`, `screen_camera`, platform monitoring and smart-alert surfaces provide concepts and interface evidence. | Screen-camera and platform-alert tests exist. | Supported data sources, collection boundaries, signal quality, human-review model, delivery, and user-facing transparency. | Explicit decision required. |
| Social-platform monitoring | Registry target exists; adjacent app/web and monitoring concepts exist. | No production social integration evidenced by this audit. | Platform-by-platform capability, lawful access path, content/signal model, account linking, transparency, and alert validity. | Explicit decision required. |
| Anti-tamper resilience | Tamper alert screen/models and anti-tamper policy/alert bus/domain exist. | Anti-tamper repository and alert-bus tests exist. | Native integrity signals, detection trust level, remediation workflow, remote assurance, and false-positive handling. | Active discovery. |
| Immediate lock | Instant-lock, child lock, second-key surfaces; device-lock service/state models exist. | Lock service and lock-screen tests exist. | Device-level lock execution, essential-access exemptions, acknowledgment receipt, remote queue/retry/reversal. | Active discovery. |
| Reports and analytics | Usage reports, day-board projections, alert hub/details, advisor/report-adjacent surfaces exist. | Relevant report, dashboard projection, alert, and widget tests exist. | Event ingestion, data quality, family/child data boundaries, retention, cross-device aggregation, and export contract. | Active discovery. |
| Mobility and driving safety | Road-safety models/repository/screen exist in the Day feature. | Road-safety widget test exists. | Motion/location inputs, actual risk definition, battery impact, alert confidence, and supported-device contract. | Explicit decision required. |
| School mode | Smart modes UI and modes core/domain exist; relevant focus and schedule structures occur elsewhere. | Smart-mode and mode-domain tests exist. | Unified schedule rules, education linkage, enforcement adapter, emergency/accessibility exceptions, and parent/child explanation. | Active discovery. |

## 4. Cross-platform foundation already visible in source

| Foundation element | Evidence | Importance to Security |
|---|---|---|
| Identity / family / guardian structure | `sys3_identity`, linking/onboarding, family members, mother permission-level repositories/screens. | Determines who can set, receive, approve, or reverse a safety action. |
| Child and device context | Child profile, device-health surfaces, linking, device-health seam. | Prevents rules from being shown as effective when a target device is unhealthy or unsupported. |
| Policy models and schedule structures | Core policy engine, schedule windows, time/app/web/anti-tamper repositories, sync-bus seams. | Provides a valuable vocabulary for later backend contracts; does not itself prove remote policy sync. |
| Today / alert surfaces | Day board, alert hub/detail projections, notification preferences/catalog. | Enables the proposed Safety Hub to show priority rather than raw system lists. |
| Privacy and audit | Privacy/data screens, collection preferences, audit-log repositories and panels. | Must frame visibility, monitoring explanation, action history, and data controls. |
| Local reliability foundations | Local persistence and restart-proof tests in several security domains. | Useful patterns for offline continuity, but must be upgraded intentionally for multi-device truth. |

## 5. Research baseline: global parity signals

The following external references are comparison evidence—not a specification to copy:

| Reference | Relevant expectation for discovery |
|---|---|
| [Google Family Link](https://support.google.com/families/answer/7103340?hl=en) | Screen-time schedules, app controls, parent approvals, and platform-specific limits. |
| [Apple Screen Time](https://support.apple.com/en-my/108806) and [Family Sharing](https://support.apple.com/en-eg/105121) | Downtime, app limits, always-allowed access, communication/content controls, requests, and exemptions. |
| [Microsoft Family Safety](https://support.microsoft.com/en-US/family-safety/roles-permissions-and-data-sharing-in-family-safety) | Organizer/member relationships and explicit permissions; Android enforcement dependencies must be transparent. |
| [Qustodio features](https://www.qustodio.com/en/features/) | Unified parent dashboard, routines, pause, time/app/web controls, reporting, location/geofences, and platform support matrices. |
| [Bark FAQ](https://www.bark.us/faq/) | Signal/alert-oriented monitoring rather than indiscriminate content viewing; clear boundaries where iOS/platform limits apply. |
| [Life360 terms](https://legal.corp.life360.com/hc/en-us/articles/17865862545815-Life360-Product-and-Services-Terms) | Family circles, location consent, place alerts, check-ins, history expectations, and clear plan boundaries. |
| [Apple Screen Time API overview](https://developer.apple.com/videos/play/wwdc2021/10123/) | Apple-specific Family Controls, Managed Settings, and Device Activity constraints/entitlements; not a general monitoring promise. |

## 6. Discovery implications

1. The platform already has a broad security UX/domain foundation. Product refinement should preserve useful surfaces where they support the V2 model, rather than assuming a ground-up visual rewrite.
2. The largest gap is not the number of screens; it is the boundary between local policy representation and truthful multi-device, native, remote behaviour.
3. Security must be designed as a progressive system: parent value and child clarity first; advanced monitoring/drive/signal systems only after the supported capability is defined.
4. Device health and capability status are first-class UX, not a support afterthought.
5. SOS, location, time, app/web controls, alerts, privacy, and device health already show the beginnings of a connected platform. The next work is to reconcile them into one coherent Safety Hub and settings desk.

## 7. Open evidence questions for the next loop

- Which of the currently visible security screens are duplicated, incomplete, or mismatched with the desired Safety Hub hierarchy?
- What capability tiers should the UI communicate for Android, iOS, and unsupported devices without overwhelming a parent?
- Which 12-system areas are true V1 value versus strategic differentiation that should wait for validated native/remote capability?
- What is the minimum trustworthy SOS delivery model before it can be part of a public promise?
- Which monitoring concepts provide actionable family value without creating opaque, noisy, or misleading alerts?
- How do child requests, guardian permissions, and audit history form one consistent control language across time, apps, web, locks, and school mode?
