# 01 — FS-004 Scope and Mission (Discovery)

**System label:** FS-004 — Screen & Camera Control  
**Date:** 2026-09-24  
**Mode:** Evidence audit only — **no** L2 product law · **no** wireframes · **no** app code  
**Authority (frozen):** Identity · Policy Kernel · Offline-first · Audit/Events/Notifications · SOS Final · Screen Time Final · FS-002 L2/L3 · FS-003 L2/L3 · FS-005 Modes (where relevant)  
**Evidence baseline:** repository + Policy Register / prototype / prior discovery packs  
**`docs/family_os_blueprint/`:** **NOT FOUND** in this workspace (path missing) — treated as **UNKNOWN** asset; did not invent its contents  

**Entry:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

```
FS-004 DISCOVERY: COMPLETE
FS-004 L2 POLICY: NOT STARTED
FS-004 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## 1. Mission of this discovery

Inventory **current repository evidence** and **documented product language** related to:

- Parental **camera** control on the child device (beyond Family OS using its own camera)  
- Parental **screenshot / screen-recording / screen-capture** control or monitoring  
- Screen/privacy protection surfaces  
- Coupled **microphone** concerns only where evidence ties them to capture/camera  
- Honesty, offline, multi-device, audit, and cross-system boundaries  

**FS-004 as a named system does not appear in the repository today.** This pack is the first structured discovery under that label.

---

## 2. Critical split (A vs B)

| Class | Meaning | In scope for FS-004 product? |
|---|---|---|
| **(A) Family OS camera/mic use** | App requests camera for QR, Studio textbook capture, video-call toggle | **Boundary evidence only** — not parental device control |
| **(B) Parental Screen & Camera Control** | Policy that blocks/monitors child device camera, screenshots, recordings, privacy | **Primary FS-004 discovery subject** |

Stage-1 (A) flows must **not** be mistaken for (B) product law.

---

## 3. Explicit non-goals of this pack

| Non-goal |
|---|
| Closing Owner decisions (L2) |
| Selecting Device Owner / Accessibility / MediaProjection / Camera APIs as product mechanism |
| Inventing TTLs, durations, or schemas |
| Wireframes / Flutter / Android changes |
| Re-opening Screen Time minutes economy under FS-004 |
| Claiming FS-003 App Control already solves FS-004 |

---

## 4. Adjacent systems (do not duplicate)

| System | Boundary |
|---|---|
| **Screen Time** | Minutes / caps / grants / Unlimited — **not** camera/screenshot OS control |
| **FS-003 App Control** | Package Allow/Block (may include a “Camera” app slug) — **not** hardware camera disable unless L2 says so |
| **FS-002 Web Filter** | URL plane |
| **FS-005 Modes** | Scheduling overlays |
| **SOS Final** | Emergency; **audio broadcast excluded** from product |
| **Anti-tamper** | Integrity / uninstall resistance — separate; may signal permission revoke |
| **Smart Alerts (FAT-065)** | Hosts a **screenshot monitoring toggle** mock — ownership vs FS-004 = **Q-SC-09** |

---

## 5. Working definition (discovery, not law)

For this audit, “Screen & Camera Control” candidate surfaces are any of:

1. **Prevent** child camera / screenshot / screen-record use  
2. **Monitor** (e.g. P-7 screenshot-on-app-open with transparency)  
3. **Protect** Family OS content (e.g. FLAG_SECURE on sensitive playback)  

Which of these belong in FS-004 v1 is **Owner L2** — not decided here.

---

## 6. Document index

| # | File |
|---|---|
| 01 | this file |
| 02 | [02_FS004_CURRENT_REPO_EVIDENCE.md](02_FS004_CURRENT_REPO_EVIDENCE.md) |
| 03 | [03_FS004_CAPABILITY_INVENTORY.md](03_FS004_CAPABILITY_INVENTORY.md) |
| 04 | [04_FS004_POLICY_AND_AUTHZ_DISCOVERY.md](04_FS004_POLICY_AND_AUTHZ_DISCOVERY.md) |
| 05 | [05_FS004_ENFORCEMENT_AND_PLATFORM_DISCOVERY.md](05_FS004_ENFORCEMENT_AND_PLATFORM_DISCOVERY.md) |
| 06 | [06_FS004_OFFLINE_SYNC_AUDIT.md](06_FS004_OFFLINE_SYNC_AUDIT.md) |
| 07 | [07_FS004_EVENTS_AUDIT_NOTIFICATIONS.md](07_FS004_EVENTS_AUDIT_NOTIFICATIONS.md) |
| 08 | [08_FS004_CROSS_SYSTEM_DEPENDENCIES.md](08_FS004_CROSS_SYSTEM_DEPENDENCIES.md) |
| 09 | [09_FS004_GAP_AND_CONTRADICTION_REGISTER.md](09_FS004_GAP_AND_CONTRADICTION_REGISTER.md) |
| 10 | [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md) |
