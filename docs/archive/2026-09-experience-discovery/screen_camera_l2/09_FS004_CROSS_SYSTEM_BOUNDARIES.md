# 09 — FS-004 Cross-System Boundaries (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-SF-10…14 · SC-OD-02/05/08/09  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Ownership map

| System | Owns | Must not |
|---|---|---|
| **FS-004** | OS/device camera intent; capture prevent/monitor/protect; P-7 monitoring semantics | Mic; SOS audio; ST minutes; package Allow/Block; schedules |
| **FS-003** | Package Allow/Block (incl. Camera app) | Claim hardware camera off |
| **Screen Time** | Minutes / Limit / Unlimited / Grant | Camera/screenshot OS policy |
| **FS-002** | URL plane | Capture monitoring policy |
| **FS-005 Modes** | Scheduling; may **tighten** FS-004 | Second FS-004 scheduler; silently weaken/remove FS-004 permanently |
| **SOS Final** | Emergency; **no audio** | — |
| **Smart Alerts** | Optional UI/notify shell | Second screenshot-monitoring policy |
| **Anti-tamper** | Integrity / uninstall resistance | Substituting for verified FS-004 plane |
| **Domain-1 Audio** | Ambient (if ever productized) | Inside FS-004 (OUT) |
| **Policy Kernel** | Merge / notify / action | Invent domain facts |
| **Studio/QR/Calls (A)** | Family OS camera UX | Bypass FS-004 without explicit exception |

---

## 2. Critical separations

```
FS-003: Camera PACKAGE deny
    ≠
FS-004: OS/device CAMERA restrict

FS-004 Prevent capture
    ≠
FS-004 Monitor capture (transparent)

FS-004
    ≠
Microphone / SOS audio / Domain-1 ambient
```

---

## 3. Modes

- Modes own schedules (SC-SF-10).  
- Modes may tighten FS-004 (SC-SF-11).  
- Modes must not silently weaken or permanently remove FS-004 restrictions.

---

## 4. Source-of-deny / UX honesty (for future L3)

When access fails, distinguish:

- FS-004 camera restrict  
- FS-003 package block  
- ST time  
- WF URL  
- Mode  
- Instant Lock  

No CTA that mutates the wrong system.

---

## 5. Closed discovery contradictions

| Former | Resolution |
|---|---|
| P-4 SOS audio | **SC-OD-08** — SOS Final wins; FS-004 no audio |
| FAT-065 vs P-7 ownership | **SC-OD-09** — FS-004 owns policy |
| Package block = camera off | **SC-OD-02** — separate planes |
| Mic in FS-004 | **SC-OD-05** — OUT |

---

## 6. No new Owner questions

No unavoidable new Q-SC created; discovered contradictions closed by SC-OD-05/08/09/02.
