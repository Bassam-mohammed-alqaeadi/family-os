# 03 — SOS Policy Model

**Authority:** `handoff/04_POLICY_REGISTER_EN.md` (P-4, P-5), constitution Rules 9/11, SET-010/011/020/021, UI-007/010/011, UF-08, S-SEC-026…031.  
**Do not invent current behavior — mark unproven as UNKNOWN.**

---

## Legend

- **CURRENT** = proven in app/tests  
- **REQUIRED** = Policy Register / contracts / UF-08  
- **GAP** = required − current  
- **OWNER** = needs Bassam decision  

---

## Semantics table

| Topic | CURRENT | REQUIRED | Gap / notes |
|---|---|---|---|
| **Activation** | CHD-005 hold 3s → `MockSosFire` + seed | 3s press always available | UX OK; channel mock |
| **Accidental activation protection** | Early release cancels hold | Protect without blocking reachability | OK |
| **Active SOS state** | `SosAlertStatus.active` | ACTIVE + live broadcast | No live stream |
| **Cancellation** | Child “I'm safe” → `resolve()` | UF-08: cancel rules ambiguous once ACTIVE | **OWNER** |
| **Parent acknowledgement** | Resolve CTA closes alert; comment says “ack” | Schema `ACKNOWLEDGED` then `RESOLVED` | Enum mismatch — **OWNER** if ACK separate |
| **Escalation** | Manual escalate increments counter | Timer ladder + national (P-5, S-SEC-030) | No scheduler / national |
| **Multiple parents** | Recipients father+mother (sim) | All guardians any MotherLevel | Policy OK; push absent |
| **Emergency contacts** | `SosBackupContact` name/delay/enabled | Outside-family contacts father-controlled | No phone/email |
| **Family contacts** | Rung-1 father+mother fixed | Immovable (SET-020) | OK |
| **Emergency services** | Escalate toast stub | National link | Stub |
| **Location acquisition** | Demo labels | Acquire on fire | Missing |
| **Live location updates** | Stylized pin | Continuous while ACTIVE (S-SEC-027) | Missing |
| **Location unavailable** | Not modeled | Fire anyway; honest UI | Missing |
| **Stale location** | Not modeled | Show age / last-known | Missing |
| **Device offline** | UNKNOWN (claimed P-4) | Local ACTIVE + queue | Not proven |
| **Network failure** | Load error UI on FAT-018/006 | Retry + fallbacks | Partial UI only |
| **SMS fallback** | Absent | Best-effort when push fails | Missing |
| **Call fallback** | Snackbar / nav to chat | Auto-call father (S-SEC-028) | Stub |
| **Notification failure** | Sim always delivers | Track failure; escalate channel | Missing |
| **Battery constraints** | Battery % display fixture | Prefer low-power pings; never block fire | Display only |
| **Quiet hours** | Critical always delivers (logic) | Pierce DND (OS perms) | Logic OK; OS absent |
| **Screen-time restrictions** | `sos` exempt in TimeExpirySurface | Never lock SOS (Rule 11) | OK helpers |
| **Device lock** | `sos` exempt in DeviceLockService | Never lock SOS | OK helpers |
| **Subscription expiry** | `SosFireService` entitlement-free | P-4 / Rule 9 | OK structural |
| **Audit** | Audit kind `sosAlert` exists; icon CTA fires demo | Full lifecycle immutable | SOS resolve path ≠ proven append |
| **Evidence** | Absent | Location trail ± audio (P-4 text) | Missing; audio **OWNER** |
| **Privacy** | Rule 23 no planted names in defaults | Child transparency for broadcast | Partial honesty banners |
| **Child-visible information** | Static “seen” lines | Honest delivery/location status | Misleading if treated as live |
| **Retry / recovery** | FAT-018 error retry | Offline outbox + channel retry | Missing |

---

## Hard laws already enforced in code (CURRENT)

1. **No SOS mute control** — `canShowSosMuteControl` always false; forbidden prefs keys.
2. **Quiet hours never silence critical** — `NotificationDelivery.shouldDeliver`.
3. **Rung-1 parents immovable** — `SosLadderValidationException`.
4. **Mother Observer still receives SOS** — SET-021 tests.
5. **Fire path must not import billing** — UI-007 / `SosFireService` design.
6. **Lock and time-expiry exempt `sos`**.

---

## Soft / incomplete laws

- P-4 “no internet” and “siren pierces silent” — **product law**, not OS-proven.
- P-4 “location+audio broadcast” — location mock; audio absent.
- P-5 delay-based escalation — delays stored on backups; **not executed**.
