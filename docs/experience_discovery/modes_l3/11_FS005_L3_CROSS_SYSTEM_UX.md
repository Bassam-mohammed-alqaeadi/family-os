# 11 — FS-005 L3 Cross-System UX

**Authority:** MODE-OD-06…09 · MODE-OD-11…14 · L2 boundaries · sibling L3 chips  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Ownership map (UX)

| Concern | Owner | Modes UX |
|---|---|---|
| Lifestyle Mode model / schedule / activation | **FS-005** | Primary surfaces |
| Minutes / grants / wallets / Unlimited | Screen Time | Deep-link; context chip only |
| Package Allow/Block / Permanent Block / App AE | FS-003 | Tighten chip → Modes; package editors → App Control |
| URL lists / web unlock | FS-002 | Tighten chip; no list editors |
| Camera/capture policy | FS-004 | Tighten chip; no permanent SC editors |
| Geofence geometry / location truth | FS-001 | Consume facts; Open Location |
| Instant Lock | Instant Lock | Above Modes; distinct label |
| SOS / Required Chat / Quran | SOS / Register | Always reachable |
| Kernel merge | Policy Kernel | Invisible; results via source-of-deny |
| Audit | Audit | Browse Mode events |
| AI | Advisor | Approve/reject |

---

## 2. Seven-way source-of-deny (must never merge)

| # | Experience | Source label | Primary CTA |
|---|---|---|---|
| 1 | Mode overlay restriction | **Mode** (+ stack names) | Open Modes |
| 2 | FS-003 Permanent App Block | App Control · Permanent Block | Open App Control |
| 3 | FS-003 App Access Exception active | App Control · Exception | Open App Control |
| 4 | Screen Time Temporary Grant / cap | Screen Time | Open Screen Time |
| 5 | FS-002 Web restriction | Web Filter | Open Web Filter |
| 6 | FS-004 camera/capture restriction | Screen & Camera | Open FS-004 |
| 7 | Instant Lock | Instant Lock | Open Lock |

When several apply, show **effective** + **sources**; never one CTA that mutates the wrong system.

---

## 3. Modes tighten chips on sibling hubs

| Hub | Chip | Nav |
|---|---|---|
| FS-002 | “Mode tightening filter” | → Modes (no WF scheduler) |
| FS-003 | “Mode tightening app access” | → Modes |
| FS-004 | “Mode tightening camera/capture” | → Modes |
| Screen Time | “Mode active — schedules in Modes” | → Modes (not ScheduleWindow authority) |
| FS-001 | “Modes using this zone context” | → Modes binding (geometry stays Location) |

---

## 4. Explicit non-duplication UX

| Anti-pattern | Correct |
|---|---|
| Schedule editor inside App/Web/Camera | Absent; chip to Modes |
| Modes URL list screen | Absent |
| Modes package policy store | Absent |
| Modes geofence map editor | Absent |
| Modes mint minutes | Absent |
| Modes reopen Permanent Block | Absent + blocked confirm |
| Vacation widen allow apps | Absent |
| Child Mode off control | Absent |

---

## 5. ScheduleWindow migration UX

If legacy ST sleep/prayer/study UI still visible during transition:

```
[i] Lifestyle schedules are managed in Modes.
    [Open Modes scheduler]
```

Never present it as a second Mode evaluator.

---

## 6. Safety strip (all Mode-related parent + child screens)

Persistent ungated: **SOS · Required Family Chat · Quran** entry points where those surfaces belong.
