# 03 — FS-004 Capability Inventory

**Mode:** Evidence-only. Do not invent parental-control industry defaults.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

Classification: **IMPLEMENTED** · **PARTIAL** · **MOCK/SIMULATION** · **DOCUMENTED ONLY** · **MISSING** · **UNKNOWN**

---

## Matrix

| # | Capability | Class | Evidence (short) |
|---|---|---|---|
| 1 | Named FS-004 system / pack (pre-this) | **MISSING** | No prior folder/symbol |
| 2 | Parent block **system Camera app** via App Control UI | **MOCK/SIMULATION** | FAT-034 mock `camera` row |
| 3 | Parent **hardware/OS camera disable** | **MISSING** | No DPM/`setCameraDisabled` |
| 4 | Parent **allow camera** after block (OS) | **MISSING** | — |
| 5 | Per-child camera policy store | **MISSING** | No schema; mock only |
| 6 | Family baseline camera policy | **MISSING** | — |
| 7 | Mode-driven camera restrictions | **MISSING** / **UNKNOWN** ownership | Modes exist; no camera facet |
| 8 | Block child **screenshots** (third-party) | **MISSING** | — |
| 9 | Block child **screen recording** | **MISSING** | — |
| 10 | Detect MediaProjection / recording | **MISSING** | No API usage |
| 11 | Parent **screenshot-on-app-open monitoring** (P-7) | **DOCUMENTED ONLY** + **MOCK** toggle | Register P-7; FAT-065 toggle |
| 12 | Screenshot **app picker** | **DOCUMENTED ONLY** (proto); **MISSING** Flutter | `screenshotApps` JS only |
| 13 | Child transparency for screenshot monitoring | **DOCUMENTED ONLY** (P-7); **PARTIAL/MISSING** in Flutter feature set | MonitoringFeature omits |
| 14 | FLAG_SECURE / protect Family OS surfaces | **MISSING** | Zero matches |
| 15 | Protect Domain-1 playback from screenshots | **DOCUMENTED ONLY** | Domain 1 audio doc |
| 16 | Microphone parental block | **MISSING** | — |
| 17 | Ambient surround recording (Domain 1) | **DOCUMENTED ONLY** | No impl |
| 18 | SOS audio broadcast | **DOCUMENTED ONLY** (P-4) vs **excluded** (SOS-final) | Contradiction |
| 19 | Family OS QR/Studio camera permission UX | **MOCK/SIMULATION** / **PARTIAL** | FakeCameraPermissionSeam |
| 20 | Family call camera toggle | **MOCK/SIMULATION** | Active call UI |
| 21 | Device health: camera permission row | **MISSING** | device_health_seam |
| 22 | Schema `perm_key` CAMERA / SCREEN_CAPTURE | **MISSING** | schema.sql |
| 23 | Offline enforce camera/screenshot policy | **MISSING** | No policy delivery |
| 24 | Policy version / device ack for FS-004 | **MISSING** | — |
| 25 | Outbox for FS-004 decisions | **MISSING** | — |
| 26 | Multi-device camera/screenshot state | **MISSING** | — |
| 27 | Audit events for capture monitoring | **MISSING** (impl) | P-7 documented |
| 28 | Notifications for capture alerts | **MISSING** (impl) | — |
| 29 | Enforcement honesty states for FS-004 | **MISSING** dedicated; pattern exists in FS-002/003 | Reuse candidate |
| 30 | Safety exception: camera for SOS/calls/Quran | **UNKNOWN** product | Needs Q-SC-07 |
| 31 | Interaction with FS-003 package block | **PARTIAL** conceptual | Mock camera app only |
| 32 | Interaction with Screen Time minutes | **MISSING** as FS-004 | ST is separate |
| 33 | Interaction with Web Filter | **MISSING** | — |
| 34 | Anti-tamper permission revoke (camera-specific) | **MOCK** generic | Tamper alerts |
| 35 | iOS Screen Time / FamilyControls camera | **UNKNOWN** / **DOCUMENTED ONLY** adjacent | SCREEN_TIME_IOS enum only |
| 36 | Uninstall resistance for capture agent | **MISSING** FS-004; Anti-tamper separate | FS-003 OD-15 spirit |

**Capability rows counted:** **36**

---

## Rollup

| Bucket | Count (approx) |
|---|---|
| IMPLEMENTED (OS parental control) | **0** |
| PARTIAL | few (transparency enum gap, UI fragments) |
| MOCK/SIMULATION | FAT-034 camera row · FAT-065 toggle · FakeCamera · calls · tamper alerts |
| DOCUMENTED ONLY | P-7 · prototype · Domain 1 · platform gates · P-4 audio |
| MISSING | Most (B) enforcement, schema, sync, audit pipeline |
| UNKNOWN | Ownership splits, safety exceptions, iOS promise, blueprint folder |

---

## Non-additions

Do **not** treat as present: Always-on MDM camera kill, commercial DLP screenshot block, Play Protect camera policy, invented MediaProjection agents.
