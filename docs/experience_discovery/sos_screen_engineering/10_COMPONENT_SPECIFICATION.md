# 10 — Component Specification

**Status:** Spec only — do not implement in this phase.  
**Placement later:** `app/lib/core/design/components/` (once each).

---

## SosStatusBanner

- **Responsibility:** Show lifecycle + P-4 honesty.  
- **Inputs:** `lifecycle`, `terminalReason?`, `panicQuiet`, `l10n`.  
- **Outputs:** none (display).  
- **States:** ACTIVE, ACKNOWLEDGED, ESCALATING, RESOLVED, FALSE_ALARM.

## SosDeliveryStatus

- **Responsibility:** Per-recipient/channel delivery honesty.  
- **Inputs:** `List<DeliveryRow{recipient, channel, class}>`.  
- **Outputs:** retry callback optional.  
- **States:** PENDING, DELIVERED, FAILED, PARTIAL aggregate.  
- **Rule:** Never DELIVERED without confirmation.

## SosLocationStatus

- **Responsibility:** Location class + optional age + open map.  
- **Inputs:** `class` READY|ACQUIRING|STALE|UNAVAILABLE, `updatedAt?`, `onOpenMap?`.  
- **States:** four classes + missing permission soft.

## SosIncidentTimeline

- **Responsibility:** Compact lifecycle/delivery/escalation events.  
- **Inputs:** `events[]` (type, at, actorLabel).  
- **States:** empty, populating, truncated.

## SosActionBar

- **Responsibility:** Role-filtered actions for FAT-018.  
- **Inputs:** `role`, `motherLevel`, `incidentOpen`, `capabilities`, callbacks.  
- **Outputs:** ack / contact / escalate / resolve / breakGlass / setup.  
- **States:** enabled set per SosRoleGuard.

## SosRoleGuard

- **Responsibility:** Pure allow/deny for `actionId`.  
- **Inputs:** `AppRole`, `MotherLevel?`, `actionId`.  
- **Outputs:** `bool allowed`.  
- **States:** n/a (function).

## SosReadinessCard

- **Responsibility:** FAT-028 / settings summary of SOS capability classes.  
- **Inputs:** push/SMS/call/location/ladder/verify counts, panicQuiet.  
- **States:** READY summary, DEGRADED, NOT_CONFIGURED warnings.

## SosBreakGlassSheet

- **Responsibility:** Break-glass lifecycle UI.  
- **Inputs:** allowlist capabilities, maxDuration, onConfirm, onCancel.  
- **Outputs:** invoke payload `{capabilityId, reason, endsAt}`.  
- **States:** see [08_BREAK_GLASS_UX.md](08_BREAK_GLASS_UX.md).  
- **RBAC:** Primary/Full only.

## SosCancelConfirmation

- **Responsibility:** Child false-alarm confirm sheet.  
- **Inputs:** onConfirmSafe, onDismiss.  
- **Outputs:** confirm / dismiss.  
- **States:** open, confirming, error.

## TrustedContactCard

- **Responsibility:** One backup row on FAT-028.  
- **Inputs:** name, priority, delay, enabled, verificationStatus, callbacks.  
- **States:** interactive vs locked.

## ContactVerificationState

- **Responsibility:** Badge + actions for UNVERIFIED→PENDING→VERIFIED→REVOKED.  
- **Inputs:** status, onStartVerify, onRevoke, error?.  
- **States:** four + failure.

## EscalationStatus

- **Responsibility:** Show trusted escalation progress on FAT-018.  
- **Inputs:** rung, contact labels, delivery classes, delaying?.  
- **States:** idle, waiting, notifying, partial, complete.

---

## Shared rules

- Semantics labels required.  
- Touch targets ≥48dp.  
- Tokens only.  
- No audio widgets.  
- No emergency-number fields.
