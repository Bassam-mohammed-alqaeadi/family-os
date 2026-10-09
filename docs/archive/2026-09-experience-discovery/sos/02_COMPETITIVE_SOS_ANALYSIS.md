# 02 — Competitive SOS Analysis

**Rule:** Separate COMPETITOR FACT · CURRENT REPOSITORY FACT · PROPOSED PRODUCT DECISION.  
Do not present competitor behavior as Family OS implementation.

---

## Sources (competitor facts)

- Qustodio Help — Panic Button articles
- FamiSafe / Wondershare support — SOS Alerts (iOS/Android guides)
- Bark Technologies support — Bark Watch emergency contacts / SOS button
- Google Android Help — Emergency SOS, Emergency Location Service (ELS), Personal Safety

---

## Pattern matrix

| Pattern | Qustodio | FamiSafe | Bark Watch | Android Emp. SOS / ELS | Family OS Target |
|---|---|---|---|---|---|
| Trigger | Tap SOS (+ confirm); Android Kids | Tap + **5s cancel window** | Hardware SOS; multi-step for 911 | Power×5 + hold/countdown | **3s hold** (Register P-4) |
| Who notified | Trusted contacts email/SMS | Parent app push | Emergency contacts; optional 911 path | Contacts + optional emergency services | Guardians + ladder backups + national link |
| Location | Link; updates while Panic Mode active | Live Location / history | Call-centric; watch GPS | ELS to responders on emergency call/text; share needs network | Live map to parents |
| Cancel | Child tap again; parents notified | Cancel within 5s window | Call-flow dependent | Abort before confirm | Child confirm-safe (today = resolve) |
| Parent disable SOS | Enable Panic Button setting | **Parent can disable** child SOS | N/A (hardware) | User can turn Emp. SOS off | **Cannot mute receipt** (P-4) — stricter than FamiSafe |
| Auto 911? | **No** — explicit disclaimer | Not claimed as auto-911 | Separate deliberate 911 | Can call local emergency number | OWNER DECISION |
| Platform limits | Android-focused Panic | Widget; parent kill-switch | SIM / model differences | Airplane / Battery Saver can block Emp. SOS | iOS Critical Alerts; Android FSI (`PLATFORM CONSTRAINT`) |

---

## Useful patterns (borrow carefully)

### COMPETITOR FACT → lesson

| Lesson | From | Family OS implication |
|---|---|---|
| Accidental-activation protection without killing reachability | FamiSafe 5s cancel; Android hold/countdown; Qustodio confirm | Keep 3s hold; clarify post-ACTIVE cancel (**OWNER**) |
| Trusted contacts need invite/accept | Qustodio | Backup contacts may need verification (**PROPOSED**) |
| Explicit “does not replace emergency services” | Qustodio | Honesty copy required (**PROPOSED**) |
| Parent can disable child SOS | FamiSafe | **Conflicts with P-4** — do not copy |
| Location update cadence while active | Qustodio | Need defined ping interval (**OWNER** / engineering) |
| Emergency contacts ≠ auto-911 | Bark | Separate national escalate from family ladder (**PROPOSED**) |
| ELS only on emergency call/text | Android | Do not claim ELS unless integrating OS emergency dial (**PLATFORM**) |
| Emp. SOS blocked in airplane / Battery Saver | Android | Degraded-path honesty mandatory (**PROPOSED**) |

---

## CURRENT REPOSITORY FACT (contrast)

- Mock fire always succeeds; no SMS/email/push
- No trusted-contact invite/accept flow
- Ladder backups have name/relation/delay/enabled — **no phone/email fields**
- UI never offers mute SOS (aligned with P-4; unlike FamiSafe disable)
- Auto-call and escalate are Stage-1 stubs
- No disclaimer screen that SOS ≠ national emergency services (copy partial via escalate CTA)

---

## PROPOSED PRODUCT DECISION (not approved)

1. Keep P-4 stricter than FamiSafe: guardians cannot disable SOS receipt.
2. Keep 3s hold (Register) rather than FamiSafe’s post-tap 5s cancel — unless owner changes activation UX.
3. Separate channels: family push/siren vs backup SMS/call vs national emergency (parent-initiated unless owner picks auto).
4. Always show honest degraded state when location/network/call unavailable.
5. Add clear “not a replacement for 911/997/…” honesty string (region-specific).

All of the above that conflict with frozen Register/screens require **OWNER DECISION** before implementation.
