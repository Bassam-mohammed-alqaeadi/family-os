# 10 — SOS Experience Gaps

Evidence-first. Types: **Safety** · **Honesty** · **Policy** · **Role** · **Data** · **Platform**

---

## Gap register

| ID | Gap | Type | Evidence | Roles hit |
|---|---|---|---|---|
| SOS-G01 | Cannot actually call / SMS / stream location | Safety | `MockSosFireService`; XD-005 prior discovery | All |
| SOS-G02 | App missing ACKNOWLEDGED vs schema | Data / Policy | `SosAlertStatus` vs `sos_status` enum | Parents |
| SOS-G03 | Ladder delays never execute | Policy | `delaySeconds` stored; no timer worker | All |
| SOS-G04 | Backup contacts lack phone/email | Data | `SosBackupContact` fields | Father config |
| SOS-G05 | Child “seen” status is static ARB | Honesty | CHD-006 status card | Child |
| SOS-G06 | Auto-call is snackbar / timer mock | Safety / Honesty | FAT-018 `_callNow` | Parents |
| SOS-G07 | Escalate is counter only | Safety | `escalateCount++` | Parents |
| SOS-G08 | Audio broadcast promised, not built | Safety / Honesty | P-4; GAP-A-SEC-008 | All |
| SOS-G09 | No FamilyEvent SOS types | Data | Repo grep empty | Platform |
| SOS-G10 | `sos_alert` table unused by app | Data | No client | Backend |
| SOS-G11 | Multi-device sync absent | Safety | In-memory Stage-1 | All |
| SOS-G12 | Airplane / offline not device-proven | Platform | UF-08 requires; no proof | Child |
| SOS-G13 | Observer action parity may over-grant | Role | FAT-018 test allows Observer resolve | Mother |
| SOS-G14 | FAT-028 editable without MotherLevel gate | Role | `EmergencySetupScreen` no lean | Mother / Child if navigated |
| SOS-G15 | No delivery failure UX | Honesty | Sim always delivers | Parents |
| SOS-G16 | Evidence Pack / Panic Quiet / Break-glass absent | Product | Not found | OWNER scope |
| SOS-G17 | SOS resolve → audit append unclear | Policy | Audit kind exists; path unproven | Father |
| SOS-G18 | National emergency not configured | Safety | S-SEC-030 stub | Parents |

---

## Closed related gaps (context — not SOS channel complete)

From `GAP_LOG.md` (settings/UI): SET-010/011/020/021, UI-007/010/011 — quiet hours / mute / rung-1 / paywall / expiry reachability. These close **policy UI**, not real emergency telecom.

---

## Priority suggestion (PROPOSED — not ordered for implementation without harness cards)

1. Real fire + push + location (SOS-G01, G10, G11)  
2. ACK vs RESOLVE + receipts (G02, G05, G15)  
3. Ladder execution + contacts MSISDN (G03, G04, G18)  
4. Call path (G06, G07)  
5. Audio / evidence (G08, G16) — after OWNER  
6. Role tightening (G13, G14) — after OWNER  
