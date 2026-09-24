# 05 — FS-005 Scheduling Discovery

**Mode:** Inventory every schedule/timer that could compete with Modes ownership.  
**Do not** select platform wake mechanisms.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Expected ownership hypothesis (sibling L2 — not frozen here)

FS-002 / FS-003 / FS-004 L2 state: **FS-005 owns scheduling / lifestyle overlays**; those systems must not create a second scheduler.

This discovery asks: **does Stage-1 already violate that?**

**Answer (evidence):** Yes — there are **at least two** schedule→mode pathways, plus adjacent non-mode schedulers. Whether ST `ScheduleWindow` remains ST-owned, becomes Modes-owned, or feeds Kernel as a fact is **Q-MODE-08**.

---

## 2. Primary schedulers / schedule-like mechanisms

| ID | Name | Location | Trigger | Output | OS cron? | FS-005 risk |
|---|---|---|---|---|---|---|
| **S1** | `ScheduleWindow` | `schedule_window.dart` + repo; FAT-032; `PolicySyncKind.schedule` | Parent enables sleep/prayer/study windows; `contains(now)` | `ScheduleWindowQuery` → `BuiltInModeId` + `modeActive=true` | **No** — evaluate-on-query | **HIGH** competing lifestyle overlay |
| **S2** | `SmartModeRow` school times | `smart_mode_prefs.dart`; FAT-085 | Parent picks start/end | Stored; `expiresAt` on publish; **no auto-activate** | **No** | Modes schedule store (incomplete) |
| **S3** | `SmartModeActivationBus` | `smart_mode_activation_bus.dart` | Manual publish on toggle/save | Child UI activation | N/A | Sync bus, not clock |
| **S4** | Focus schedules | `n14_studio/focus_report_*` | Mock weekly focus sessions | Advisor/focus UI | No | Adjacent |
| **S5** | Outer-circle / friend contact schedules | n02 day | Contact windows | Contact policy | No | Adjacent |
| **S6** | Notification quiet hours | `notification_prefs.dart` | Quiet window prefs | Notification gating | No | Adjacent |
| **S7** | Temporary grant expiry | ST grant models / query | Grant end time | ST access | Domain clock | ST; intersects Modes via Ruling C |
| **S8** | SOS escalation delays | SOS ladder | Father-set seconds | Escalation step | Domain | SOS |
| **S9** | Privacy wipe regret | Privacy wipe | 7-day window | Wipe | Documented | Privacy |
| **S10** | UI `Timer.periodic` | SOS hold, QR, child lock | UX ticks | UX only | N/A | Not policy |

### Counts

| Metric | Value |
|---|---|
| Primary schedule→mode / mode schedule mechanisms | **3** (S1, S2, S3) |
| Total schedule-like mechanisms inventoried | **10** |
| WorkManager / AlarmManager / cron for Modes | **0 found** |

---

## 3. S1 detail — Screen Time windows as mode flags

```
FAT-032 ScheduleWindow (sleep|prayer|study)
        → ScheduleWindowQuery.activeBuiltInMode
        → priority sleep > prayer > study
        → prayer maps to BuiltInModeId.sleep
        → TimeContext.modeActive = true
```

**Implication:** Lifestyle “mode active” can be true **without** FAT-085 activation. This **duplicates** the conceptual FS-005 overlay responsibility under Screen Time today.

---

## 4. S2 detail — Smart Modes school schedule

- Defaults: school 07:00–13:45 (prototype parity).
- Persisted on activate/save.
- On publish, `expiresAt` = today@scheduleEnd (UTC).
- **No** background job activates school when clock enters window.
- Other built-ins: no schedule fields in UI (except listing).

S-SEC-058 (school schedule) claimed hosted on FAT-085 — **UI store yes; runtime scheduler no**.

---

## 5. S-SEC-059 location auto-activation

| Claim | Evidence |
|---|---|
| Hosted on FAT-085 (not FAT-039) | Honesty banner + repo comments |
| Implementation | **MISSING** — no geofence callback → `publish` |
| Ownership of geofence geometry | Must remain **FS-001** (discovery stance) |

**T-MODE-07:** handoff contract only — Modes consume “at school” fact.

---

## 6. Seasonal / weekly / manual (Register)

| Type | Register | Flutter |
|---|---|---|
| Weekly | Required property | School TOD only; no Sun–Thu matrix in model |
| Manual-only | e.g. study in proto | Toggle exists for all ids |
| Seasonal between dates | Ramadan / vacation strings | **MISSING** date fields |

---

## 7. Duplicate scheduler risks across FS-001…FS-004

| System | Second scheduler in that system? | Modes interaction |
|---|---|---|
| FS-002 | L2 forbids; L3 chip→Modes | No WF scheduler code found |
| FS-003 | L2 forbids | No AC schedule editor for packages |
| FS-004 | L2 forbids | No SC schedule editor |
| FS-001 | Owns geofences | Must not become Modes; Modes may consume |
| Screen Time | **Has S1 ScheduleWindow** | **Active duplication risk vs Modes** |

---

## 8. Open questions

- **Q-MODE-06** — priority when S1 and S2 disagree  
- **Q-MODE-08** — scheduling ownership model (absorb / dual / Kernel facts)  
- **Q-MODE-09** — activation channels (clock / manual / geofence / seasonal)  
- **T-MODE-01** — single runtime evaluator vs multi  
- **T-MODE-02** — platform wake (not chosen)
