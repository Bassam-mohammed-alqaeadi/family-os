# 10 — FS-004 L3 Cross-System UX

**Authority:** L2 Cross-System Boundaries · SC-OD-*  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## Ownership map (UX)

| Concern | Owner | FS-004 UX |
|---|---|---|
| Minutes / budgets / grants / Unlimited | Screen Time | Deep-link only; no minute editors |
| URL / web allow-deny | Web Filter | Deep-link only |
| App install / package allow-deny / permanent block | FS-003 | Distinct package camera copy + deep-link |
| OS/device camera + capture prevent/monitor/protect | **FS-004** | Primary surfaces |
| Mode schedules / tighten windows | Modes (FS-005) | Tighten chip → Modes; no schedule editor here |
| SOS reachability / SOS Final | SOS | Always reachable; **no SOS audio in FS-004** |
| Required Family Chat / Quran lockouts | Policy Register | Never ordinary-denied by FS-004 |
| P-7 monitoring policy store | **FS-004** | FAT-065 / Smart Alerts = entry/notify only |
| Identity roles | Identity | Primary+Full configure; Partner decide tickets; Observer view |
| Audit append-only | Audit | Browse only |
| AI suggestions | Advisor | Approve/reject — AI never writes FS-004 alone |

---

## Five-way camera/capture separation (must never merge)

| # | Experience | Source label | Primary CTA |
|---|---|---|---|
| 1 | FS-003 Camera **package** denied | App Control | Open App Control |
| 2 | FS-004 OS/device camera restricted | Screen & Camera · Camera | Open SC-P-CAMERA |
| 3 | FS-004 screenshot/capture **prevention** | Screen & Camera · Prevent | Open SC-P-PREVENT |
| 4 | FS-004 screenshot **monitoring** | Screen & Camera · Monitor | Open SC-P-MONITOR + child transparency |
| 5 | Family OS **protected-surface** capture protection | Screen & Camera · Protect | Open SC-P-PROTECT |

---

## Modes tighten-only

- Modes may **tighten** FS-004 effective restrictiveness during a mode window.  
- Modes **must not** silently permanently remove/weaken FS-004 baseline/override.  
- UX: Mode chip on hub/child; navigation to Modes to change schedule.  
- Ending a mode returns to FS-004 effective policy — not a silent wipe.

---

## Screen Time distinction

- Time remaining / Unlimited never presented as camera/capture controls.  
- Expiry never locks SOS / Required Chat / Quran (Register).

---

## FS-002 distinction

- FS-002 (prior discovery systems) does not own FS-004 pillars.  
- No silent mutation of FS-004 from FS-002 surfaces.

---

## SOS / mic / audio

| Item | FS-004 |
|---|---|
| SOS button reachability | Always preserved |
| SOS audio / ambient mic | **OUT** — never designed here |
| Microphone controls | **OUT** |

---

## Protected camera workflows

| Workflow | UX |
|---|---|
| QR / enrollment | Explicit exception or protected path; policy intent unchanged |
| Approved Studio capture | Explicit; scoped; ends cleanly |
| Required Family OS call camera | Explicit when required |
| After exception | Underlying restrict resumes |

---

## Notifications vs policy

- Smart Alerts / FAT-065 may surface monitoring notifications.  
- **Single policy store:** FS-004.  
- Opening alert → FS-004 config/OBS — never a duplicate toggle store.

---

## AI

- Suggestions may propose monitoring/camera settings.  
- Structural end: parent **approve** (authorized role) or **reject**.  
- No `execute()` that mutates FS-004 without approval.
