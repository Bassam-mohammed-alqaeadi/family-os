# 02 — FS-004 Policy Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-OD-01…12 · SC-SF-01…18  
**Authority:** [01_FS004_L2_OWNER_DECISIONS.md](01_FS004_L2_OWNER_DECISIONS.md)  
**Non-authority:** Stage-1 mocks · Discovery CURRENT implementation  

```
OWNER DECISIONS: FROZEN
FS-004 L2 POLICY: COMPLETE
```

---

## 1. Mission

**FS-004 Screen & Camera Control** answers:

> How does the family **restrict**, **monitor (transparently)**, and **protect** camera and screen-capture related capabilities for a child — separately from package Allow/Block (FS-003), minutes (Screen Time), URLs (Web Filter), and microphone/SOS audio (out of scope)?

### Owns (SC-OD-01)

| Pillar | Meaning |
|---|---|
| **Prevent** | Parental camera restriction (OS/device-level intent); capture prevention where platform can enforce |
| **Monitor** | Configured screenshot/capture monitoring with **mandatory child transparency** |
| **Protect** | Protection of Family OS sensitive surfaces against capture where supportable |

### Does not own

| Concern | Owner |
|---|---|
| Package Allow/Block (incl. Camera app package) | **FS-003** |
| Minutes / Limit / Unlimited / Temporary Grant | **Screen Time** |
| URL filtering | **FS-002** |
| Scheduling | **FS-005 Modes** |
| Microphone / ambient Domain-1 | **OUT** (SC-OD-05) |
| SOS audio / emergency lifecycle | **SOS Final** (SC-OD-08) |
| Uninstall resistance | **Anti-tamper** (adjacent) |

---

## 2. Policy document shape (SC-OD-12)

| Layer | Contents |
|---|---|
| **Family baseline** | Default prevent/monitor/protect settings |
| **Child override** | Per-child settings — **wins when present** |
| **Overlays** | Mode tighten context (consume Modes); explicit safety exceptions |
| **Version** | Monotonic `policyVersion` (or equivalent) |
| **Capability report** | Per-device plane honesty — required for claims |

---

## 3. Core policy objects (conceptual)

| Object | Pillar | Notes |
|---|---|---|
| Camera restriction intent | Prevent | OS/device-level; ≠ FS-003 package block |
| Capture prevention intent | Prevent | Only claim where plane supports |
| Screenshot monitoring config | Monitor | App/scope list TBD tech; **single source = FS-004** (SC-OD-09) |
| Monitoring active flag | Monitor | Drives child transparency (SC-OD-10) |
| Sensitive-surface protection | Protect | Family OS surfaces |
| Explicit camera exceptions | Safety | QR / approved workflows / call camera when required (SC-OD-07) |

---

## 4. Evaluation principles

1. Resolve family baseline + child override (override wins).  
2. Apply Mode **tighten-only** context (SC-SF-11) — Modes cannot permanently remove FS-004 policy.  
3. Apply explicit exceptions (SC-OD-07).  
4. Intersect honesty: no `enforced` claim without ack + verified plane (SC-OD-04).  
5. FS-003 package DENY does **not** auto-imply FS-004 camera DENY (SC-SF-12).  
6. No cross-system silent mutation of ST / WF / SOS / AC.

---

## 5. Forbidden product claims

| Forbidden |
|---|
| Universal third-party screenshot/recording blocking (SC-OD-03) |
| Android-equivalent iOS enforcement without proof (SC-OD-06) |
| Silent monitoring (SC-OD-01/10) |
| SOS/mic capabilities inside FS-004 (SC-OD-05/08) |
| Mechanism names as product law (SC-OD-04) |
