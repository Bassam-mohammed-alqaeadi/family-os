# 13 — SOS Screen Traceability

Maps frozen requirements → screen → component → state → role → event → backend/device dependency (named only).

**Authority:** `sos_final` OD/RD/Q freeze.

---

## Trace table

| Requirement ID | Screen | Component | State | Role | Event | Backend/device dependency |
|---|---|---|---|---|---|---|
| OD-01 Observer limits | FAT-018, FAT-028 | SosActionBar, SosRoleGuard | active/empty | Observer | — | API reject ack/esc/res/config |
| OD-02 Partner respond | FAT-018 | SosActionBar | ACTIVE→ACK→… | Partner | SosAcknowledged, SosEscalated, SosResolved | Incident API |
| OD-03 Full config | FAT-028 | TrustedContactCard, Panic toggle | ready | Full | SosLadderConfigured | Ladder API |
| OD-04 Primary full | FAT-018/028 | all | — | Primary | all allowed | RBAC |
| OD-05 ACK≠RESOLVE | FAT-018 | SosActionBar, SosStatusBanner | ACKNOWLEDGED vs RESOLVED | Partner+ | distinct events | Status enum |
| OD-06 Child cancel | CHD-006 | SosCancelConfirmation | cancellation | Child | SosFalseAlarmCancelled | Cancel API + notify |
| OD-07 Auto-call trusted | FAT-018 | SosActionBar | active | Partner+ | SosCallAttempted | Dialer/VoIP — no national |
| OD-08 No emergency # | FAT-028 | — | — | — | — | No field |
| OD-09 Confirm delivery | FAT-018, CHD-006 | SosDeliveryStatus | PENDING/DELIVERED/FAILED | All | delivery events | Push/SMS/call receipts |
| OD-10 Evidence (no AV) | FAT-018 | SosIncidentTimeline | active | Guardians | — | Evidence store 90d samples |
| OD-11 No audio | all | — | — | — | — | No mic SOS |
| OD-12 / RD-01 Panic Quiet | CHD-006, FAT-028 | layout mode | ACTIVE critical-only | Child / Full+Primary config | SosPanicQuietModeChanged | Settings |
| OD-13 / Q-02A/02B Break-glass | FAT-018 | SosBreakGlassSheet | OVERRIDE_ACTIVE | Primary, Full | SosBreakGlass* | Override ticket + Policy Kernel |
| OD-14 Exemptions | CHD-005, CHD-021, lock | hold / CTA | reachable | Child | — | Exempt surfaces |
| OD-15 Trusted escalate only | FAT-018 | EscalationStatus | ESCALATING | Partner+ | SosEscalated | Timer + VERIFIED only |
| OD-16 Location honesty | CHD-006, FAT-018 | SosLocationStatus | READY/…/UNAVAILABLE | All | SosLocationUpdated | Location services |
| OD-17 Offline | CHD-005/006 | status chips | offline/sync | Child | SosIncidentCreated local | Outbox |
| OD-18 Resolve retains | FAT-018 | SosStatusBanner | RESOLVED | Partner+ | SosResolved | No delete |
| OD-19 Incident model | FAT-018 | center layout | lifecycle | Guardians | — | SosIncident |
| OD-20 Delivery≠lifecycle | FAT-018, CHD-006 | dual chips | both | All | — | DeliveryAttempt |
| OD-21 Readiness | FAT-028 | SosReadinessCard | ready/degraded | Primary, Full | — | Readiness probe |
| RD-04 Verify | FAT-028 | ContactVerificationState | UNVERIFIED…REVOKED | Primary, Full | ContactVerificationChanged | Abstract verifier |
| RD-05 Max 5 / priority | FAT-028 | TrustedContactCard | at_cap | Primary, Full | ladder update | Validation |
| Q-03A Retention | FAT-018 timeline | SosIncidentTimeline | samples vs audit | — | SosEvidencePurged | Retention worker |

---

## Coverage note

Every OD-01…21 and closed RD/Q row appears above. Implementation later must keep this matrix green in widget tests per role.
