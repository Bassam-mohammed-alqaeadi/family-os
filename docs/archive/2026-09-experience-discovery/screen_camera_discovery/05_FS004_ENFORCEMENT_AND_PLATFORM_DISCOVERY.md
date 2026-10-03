# 05 — FS-004 Enforcement and Platform Discovery

**Mode:** Prove what is **actually in the tree**. Do not select final mechanisms.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Hard rule

| Layer | Meaning |
|---|---|
| API present | Native/class/permission exists in repo |
| Enforcing parental policy | API applied to child camera/screenshot policy |

Docs naming Device Owner / Accessibility / MediaProjection are **DOCUMENTED ONLY**, not selection.

---

## 2. Claim matrix

| Claim | API in repo? | Enforces FS-004 policy? | Class |
|---|---|---|---|
| Device Owner `setCameraDisabled` | **No** | **No** | **MISSING** / docs only |
| `setScreenCaptureDisabled` | **No** | **No** | **MISSING** |
| MediaProjection detect/block | **No** | **No** | **MISSING** |
| FLAG_SECURE / FlutterSecureWindow | **No** | **No** | **MISSING** |
| AppOps camera | **No** | **No** | **MISSING** |
| Package hide Camera app | **No** (FS-003 audit) | **No** | **MISSING** |
| Accessibility foreground + screenshot agent | **No** | **No** | **MISSING** / docs risk |
| UsageStats for app-open trigger | **No** native | **No** | **MISSING** |
| Android CAMERA permission (app) | **No** in manifest | N/A for (B) | **MISSING** |
| RECORD_AUDIO | **No** | **No** | **MISSING** |
| FakeCameraPermissionSeam | **Yes** (Dart fake) | Only (A) UI | **MOCK** |

---

## 3. Android tree proof

- `MainActivity.kt` = empty `FlutterActivity`  
- Manifest = launcher + Flutter embedding + PROCESS_TEXT queries  
- No Device Admin, AccessibilityService, MediaProjection permission, camera permission  

Consistent with FS-003 platform audit substrate emptiness.

---

## 4. Documented strategy (non-binding)

| Doc | Note |
|---|---|
| `18_PLATFORM_GATES.md` | UsageStats / DPM / Accessibility tiers |
| `00_READINESS_BRIEF.md` | Accessibility Play risk; DPM fragile assumptions |
| Domain 1 | Ambient mic + playback screenshot prevention (product fiction vs code) |

---

## 5. Technical questions (T-SC-*) — OPEN

| ID | Topic | Open parameter |
|---|---|---|
| **T-SC-01** | Camera enforcement plane | DO / AppOps / package-block-only / hybrid honesty |
| **T-SC-02** | Screenshot **block** feasibility | FLAG_SECURE (own app) vs third-party block |
| **T-SC-03** | Screen **recording** detection | MediaProjection vs honesty-only |
| **T-SC-04** | P-7 screenshot-on-open agent | Accessibility vs UsageStats heuristics vs unsupported |
| **T-SC-05** | Persist screenshot app picker | Schema / JSON policy — no invented table |
| **T-SC-06** | Extend `perm_key` | CAMERA / RECORD_AUDIO / SCREEN_CAPTURE? |
| **T-SC-07** | Extend MonitoringFeature / CollectionScope | Screenshot/camera transparency sync |
| **T-SC-08** | Tamper S-SEC-044 scope | Which permissions trigger alerts |
| **T-SC-09** | Real camera plugins vs “camera blocked” child UX | Conflict if (A) needs camera while (B) blocks |
| **T-SC-10** | OEM / Android restricted permission interaction | Honesty matrix |
| **T-SC-11** | Ack/TTL/sync algorithms for FS-004 policy | Numbers not invented |
| **T-SC-12** | iOS FamilyControls / Screen Time API mapping | Feasibility |

**No mechanism frozen. No durations invented.**

---

## 6. Honesty pattern to reuse (future)

FS-002 / FS-003 defined `enforced` / `degraded` / `unsupported` / `unknown` / `unavailable` / `pending_policy` / `disabled_by_permission`.  
FS-004 has **no** dedicated honesty UI today — **MISSING** product surface; pattern is **DOCUMENTED** adjacent.

---

## 7. Verdict

**Zero OS parental Screen/Camera enforcement implemented.**  
Mock toggles and documented P-7 must not be read as enforcement.
