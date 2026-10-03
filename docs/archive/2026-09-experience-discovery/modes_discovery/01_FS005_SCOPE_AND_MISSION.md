# 01 — FS-005 Scope and Mission (Discovery)

**System label:** FS-005 — Special / Custom Modes (Smart Modes / lifestyle overlays)  
**Date:** 2026-09-24  
**Mode:** Evidence audit only — **no** L2 product law · **no** wireframes · **no** app code  
**Authority (frozen):** Identity (Primary / Co-Parent / Child) · Policy Kernel · Offline-first · Audit / Events / Notifications · SOS Final · Screen Time Final · FS-001 Location L2/L3 · FS-002 Web Filtering L2/L3 · FS-003 Application & System Control L2/L3 · FS-004 Screen & Camera Control L2/L3  
**Evidence baseline:** repository code + Policy Register §3 + frozen prototype + sibling discovery/L2 packs  
**Treat as evidence only (not target authority):** current Flutter mode implementations, old docs, prototype screens, Stage-1 mocks  

**Entry:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

```
FS-005 DISCOVERY: COMPLETE
FS-005 L2 POLICY: NOT STARTED
FS-005 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## 1. Mission of this discovery

Inventory **current repository evidence** and **documented product language** related to:

- Mode definitions (built-in and custom)
- Mode lifecycle, activation / deactivation, scheduling, manual activation
- Parent-created modes; per-child vs family-wide scope
- Priorities, conflicts, stacking / composition
- Tighten-only vs loosen behavior
- Overlays onto apps, web, location context, screen/camera, screen time
- SOS interaction and emergency reachability
- Exceptions, temporary overrides, child visibility, AuthZ
- Offline context, device acknowledgement, multi-device, audit / events / notifications
- Persistence / schema, sync / outbox
- Platform dependencies (Android / iOS) — **discovered, not chosen**
- **Every existing scheduler** that could compete with FS-005 ownership

**Hypothesis from sibling L2 packs (evidence, not frozen here):** FS-005 is expected to be the **schedule / lifestyle overlay owner** for FS-002 / FS-003 / FS-004. This pack **must not silently freeze** that ownership model — it must document whether current code **violates or duplicates** that responsibility.

---

## 2. Working definition (discovery, not law)

For this audit, a **Mode** is any lifestyle / situational policy overlay that:

1. Has identity (name / icon / catalog id), and  
2. May activate by schedule, manual parent action, seasonal window, and/or location context, and  
3. May change what is permitted under an active situation **without** becoming the permanent author of package lists, URL lists, minutes wallets, or geofence ownership.

Which of these facets belong in FS-005 v1 is **Owner L2** — not decided here.

---

## 3. Explicit non-goals of this pack

| Non-goal |
|---|
| Closing Owner decisions (L2) |
| Selecting Android/iOS wake, Focus Mode, WorkManager, AlarmManager as product mechanism |
| Inventing TTLs, durations, schemas, or stacking algorithms as law |
| Wireframes / Flutter / native changes |
| Absorbing Screen Time minutes / grants / wallets / Unlimited |
| Moving geofence ownership out of FS-001 into Modes |
| Silently rewriting URL lists (FS-002) or package policy (FS-003) |
| Claiming FS-005 L2 ownership freeze merely because sibling packs already name it |

---

## 4. Adjacent systems (do not duplicate)

| System | Boundary (discovery stance) |
|---|---|
| **Policy Kernel / TimeEngine** | Final merge / interpretation / action from contextual facts |
| **Screen Time Final** | Minutes, caps, grants, wallets, Unlimited, daily budget authorship |
| **FS-003 App Control** | Package Allow / Block / Permanent Block / install — Modes must not duplicate package policy store |
| **FS-002 Web Filter** | URL / category / keyword plane — Modes must not silently rewrite lists |
| **FS-004 Screen & Camera** | Camera / capture control — Modes may tighten only if L2 says so |
| **FS-001 Location** | Geofence / live location ownership — Modes may consume location **facts** |
| **SOS Final** | Always reachable; never gated by Mode |
| **Anti-tamper / Instant Lock** | Separate; Instant Lock sits above Modes on Register ladder |
| **Focus Report schedules** | Education / focus sessions — adjacent scheduler, not Modes catalog |
| **Contact / outer-circle schedules** | Contact policy — not Modes |

---

## 5. Critical boundary under investigation

Sibling contracts already state (as **their** L2 law, not FS-005 L2):

- FS-002 **WF-OD-10 / WF-OD-13** — Modes own scheduling; Modes tighten filter only  
- FS-003 **APP-OD-10 / APP-OD-11** — Modes own scheduling; tighten-only; cannot reopen Permanent Block  
- FS-004 **SC-SF-10** — Modes own scheduling; no second FS-004 scheduler  

This discovery **investigates** whether Stage-1 code already creates **duplicate schedulers** or **competing mode-flag producers**, especially:

- `ScheduleWindow` (FAT-032 sleep/prayer/study) → `modeActive`  
- `SmartModePrefs` (FAT-085) → activation bus  

**Ownership outcome is OPEN** — see **Q-MODE-06 / Q-MODE-08**.

---

## 6. Document index

| # | File |
|---|---|
| 01 | this file |
| 02 | [02_FS005_CURRENT_REPO_EVIDENCE.md](02_FS005_CURRENT_REPO_EVIDENCE.md) |
| 03 | [03_FS005_CAPABILITY_INVENTORY.md](03_FS005_CAPABILITY_INVENTORY.md) |
| 04 | [04_FS005_MODE_POLICY_AND_AUTHZ_DISCOVERY.md](04_FS005_MODE_POLICY_AND_AUTHZ_DISCOVERY.md) |
| 05 | [05_FS005_SCHEDULING_DISCOVERY.md](05_FS005_SCHEDULING_DISCOVERY.md) |
| 06 | [06_FS005_ENFORCEMENT_AND_OVERRIDE_DISCOVERY.md](06_FS005_ENFORCEMENT_AND_OVERRIDE_DISCOVERY.md) |
| 07 | [07_FS005_OFFLINE_SYNC_AUDIT.md](07_FS005_OFFLINE_SYNC_AUDIT.md) |
| 08 | [08_FS005_EVENTS_AUDIT_NOTIFICATIONS.md](08_FS005_EVENTS_AUDIT_NOTIFICATIONS.md) |
| 09 | [09_FS005_CROSS_SYSTEM_DEPENDENCIES.md](09_FS005_CROSS_SYSTEM_DEPENDENCIES.md) |
| 10 | [10_FS005_GAP_AND_CONTRADICTION_REGISTER.md](10_FS005_GAP_AND_CONTRADICTION_REGISTER.md) |
| 11 | [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md) |
