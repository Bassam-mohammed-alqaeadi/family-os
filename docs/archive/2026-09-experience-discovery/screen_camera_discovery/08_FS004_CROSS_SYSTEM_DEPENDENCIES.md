# 08 — FS-004 Cross-System Dependencies

**Mode:** Map boundaries. Do not merge ownership.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Dependency table

| System | Relationship | Risk if confused |
|---|---|---|
| **Screen Time** | Minutes economy / usage reports | Treating “screen time” docs as FS-004 camera/screenshot control |
| **FS-003 App Control** | May Allow/Block Camera **package**; stricter ∩ WF; package ID law | Assuming package block = hardware camera off (**Q-SC-04**) |
| **FS-002 Web Filter** | URL plane; browser package ≠ URL | Screenshot of browser ≠ filter unlock |
| **FS-005 Modes** | Scheduling / tighten-only (WF/AC pattern) | Second scheduler inside FS-004 |
| **SOS Final** | Always reachable; **no audio** in product | P-4 Register audio contradiction (**Q-SC-08**) |
| **Smart Alerts FAT-065** | Hosts screenshot toggle mock | Ownership of P-7 (**Q-SC-09**) |
| **Anti-tamper** | Permission revoke alerts | Camera-specific vs generic (**T-SC-08**) |
| **Instant Lock** | Device lock P1 | Not screenshot block |
| **Studio / QR / Calls** | Class (A) camera use | Mistaking for parental (B) control |
| **Domain 1 Audio** | Ambient + playback FLAG_SECURE intent | Scope in/out FS-004 (**Q-SC-05**) |
| **Policy Kernel** | Future merge of capture facts | No FS-004 facts today |
| **Notifications / Audit** | Delivery / append | No FS-004 emitters |
| **Identity** | Per-child / family scope TBD | **Q-SC-12** |

---

## 2. Diagram (CURRENT)

```
Screen Time (minutes) ──X── FS-004 (mostly missing)
FS-003 App Control (mock Camera app block) ──?── hardware camera (MISSING)
FAT-065 Smart Alerts (screenshot toggle MOCK) ──X── capture pipeline (MISSING)
SOS (no audio) ──≠── P-4 Register audio claim
Domain 1 ambient (DOC ONLY) ──X── impl
(A) FakeCamera QR/Studio ── boundary only
```

---

## 3. Frozen adjacent laws FS-004 must not violate later

| Law | Source |
|---|---|
| SOS / Required Chat / Quran reachable | SOS · FS-003 APP-SF-04 |
| Stricter ∩ App Control ∩ Web Filter | WF-OD-12 |
| Modes tighten-only; Modes own schedules | FS-002/003 ODs |
| ST owns Limit/Unlimited/Countable/Grant | APP-OD-12 |
| Enforcement honesty; no false protected claims | WF/AC SF |
| RBAC; no device-holder AuthZ | Global |

---

## 4. Duplicated ownership risks (for L2)

| Risk | Gate |
|---|---|
| FAT-065 vs FS-004 for P-7 | **Q-SC-09** |
| FS-003 Camera package vs OS camera disable | **Q-SC-04** |
| Domain 1 mic vs FS-004 | **Q-SC-05** |
| Screen Time “screen” naming collision | Naming clarity in L2 |
