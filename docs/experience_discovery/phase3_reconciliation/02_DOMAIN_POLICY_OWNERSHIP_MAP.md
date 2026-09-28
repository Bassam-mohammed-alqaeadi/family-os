# PHASE 3 — Domain / Policy Ownership Map (02)

**Date:** 2026-09-25  
**Authority:** `handoff/04_POLICY_REGISTER_EN.md` · FS-001…010 packs · Phase 2 cross-FS  

## Schema

`fact` · `policy_register_ref` · `owning_domain_or_fs` · `must_not_own` · `class`

## Core unique owners

| fact | policy_register_ref | owning_domain_or_fs | must_not_own | class |
|------|---------------------|---------------------|--------------|-------|
| Minutes currency / earn | Economy §§ / Rule 4–6 | PolicyEngine.earn + Minutes VO | Direct balance writes; XP/coins | VERIFIED EXISTING |
| Role guarding | Sovereignty § / Rule 8 | RoleGuard in router | Feature-local role checks | VERIFIED EXISTING |
| SOS never subscription-gated | Rule 9 | FS-006 SOS | Billing / Modes / ST | VERIFIED EXISTING |
| Location never subscription-gated | Rule 9 | FS-001 Location | Billing | VERIFIED EXISTING |
| Family chat never subscription-gated | Rule 9 | FS-010 Chat | Billing / ST lock / Modes lock | VERIFIED EXISTING |
| Audit append-only | Rule 10 | Audit Log repository | Any update/delete API | VERIFIED EXISTING |
| Time expiry exemptions (chat/Quran/SOS) | Rule 11 | ST + exemptions consumers | Chat/Quran/SOS lock-on-expiry | VERIFIED EXISTING |
| AI suggest-only | Rule 7 / 26 | Advisor/Insights/Tutor repos | On-device inference; AiSuggestion.execute | VERIFIED EXISTING |
| Quran licensed source | Rule 26 | EDU Quran path | AI-generated verses | VERIFIED EXISTING |
| Safe zones / location history | Location FS-001 L2/L3 | FS-001 Domain loc_* | Stage1 as durable authority | VERIFIED EXISTING |
| Web filter policy + temp-allow | WF FS-002 | FS-002 Domain wf_* | Prefs as sole production authority | VERIFIED EXISTING |
| App control allow/block | AC FS-003 | FS-003 Domain ac_* | OS intercept claiming live DeviceAdmin | VERIFIED EXISTING |
| Screen Time daily limit / schedule / sleep / time-request | ST prefs axis | Screen Time prefs/local persist | Modes ScheduleWindow confusion | VERIFIED EXISTING |
| Modes / school mode windows | FS-005 | FS-005 Modes SQLite | ST ScheduleWindow as Modes twin | VERIFIED EXISTING |
| Screen/camera monitoring desired state | FS-004 | FS-004 Domain sc_* + DesiredMonitoring | Ambient mic (FS-008) | VERIFIED EXISTING |
| Ambient mic listen sessions | Domain 1 / FS-008 | FS-008 (S-PAR-030) | FS-004 SC · FS-006 SOS evidence audio | REGISTRY GAP |
| SOS ladder / break-glass / alerts | FS-006 | sos_final Domain | Parallel Stage1 alert stores as authority | VERIFIED EXISTING |
| Offline AI local classify | FS-007 | Local classifier | Cloud Advisor as local authority | VERIFIED EXISTING |
| Activity report aggregation | FS-009 | FS-009 report host | ST raw minutes ownership | DESIGN GAP |
| Weekly recommendation prose | Rule 26 Insights/Advisor | Advisor/Insights | FS-009 inventing advice text | VERIFIED EXISTING |
| Durable family messages | FS-010 | FS-010 message store (target) | Disappearing S-COM-050; Transport as message owner | VERIFIED EXISTING |
| Disappearing messages | Deleted Domain | NONE | FS-010 revival | CLOSED |
| Identity / family context / roster | Identity Domain | Identity runtime / family context | Feature-hardcoded ChildId names | VERIFIED EXISTING |
| Notification prefs | Prefs-misc | NotificationPrefs repository | Per-feature silent prefs forks | VERIFIED EXISTING |
| Privacy collection prefs | Prefs-misc / ADM privacy | PrivacyCollection repository | Dual silent stores | VERIFIED EXISTING |
| Device lock / anti-tamper prefs | Prefs-misc | DeviceLock / AntiTamper repos | Claiming OS lock live without NAT | VERIFIED EXISTING |
| PDF export format | FS-009 / REP-C1 | UNRESOLVED Owner | Agent inventing PDF mandate | POLICY DECISION REQUIRED |
| Mic clip duration / trigger (AUD-C*) | FS-008 Gates | UNRESOLVED Owner | Agent inventing Gate 7 answers | POLICY DECISION REQUIRED |
| Chat edit depth / delete-for-all audit (CHAT-C*) | FS-010 | UNRESOLVED Owner | Agent inventing | POLICY DECISION REQUIRED |

## Non-duplicate hard rules (carry from FS-001…007 + Phase 2)

1. Mic ≠ FS-004 screen/camera.  
2. Chat ≠ ST/Modes lock surfaces.  
3. Reports ≠ ST authority over raw minutes.  
4. Audit emits only — never owned by FS feature stores.  
5. Identity RBAC consumed by all FS — never reimplemented per feature.
