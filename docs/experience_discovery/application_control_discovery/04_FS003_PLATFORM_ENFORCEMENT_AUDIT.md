# 04 — FS-003 Platform Enforcement Audit

**Mode:** Prove what is **actually implemented**. Do not claim Device Owner, Accessibility, Usage Access, package blocking, launch interception, or uninstall resistance unless repository evidence supports it.  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Hard rule for this audit

Distinguish:

| Layer | Meaning |
|---|---|
| **API present** | Native class/permission/service/method exists in tree |
| **API actually enforcing a child policy** | That API is used to apply FAT-034/035 / `AppAccessRule` outcomes to third-party packages |

Docs / catalogs / readiness briefs are **not** enforcement.

---

## 2. Android tree proof

### MainActivity

```kotlin
package com.familyos.family_os

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

Path: `app/android/app/src/main/kotlin/com/familyos/family_os/MainActivity.kt`

### AndroidManifest

- Launcher `MainActivity` only  
- Flutter embedding meta-data  
- `PROCESS_TEXT` queries for Flutter engine  
- **No** Device Admin receiver  
- **No** AccessibilityService  
- **No** `PACKAGE_USAGE_STATS` permission declaration for enforcement  
- **No** Device Owner / Profile Owner provisioning metadata  

Path: `app/android/app/src/main/AndroidManifest.xml`

### Broader native search

Under `app/android`: no Kotlin/Java beyond MainActivity + standard Flutter resources.  
No matches in application code for: `DevicePolicyManager`, `UsageStatsManager`, `AccessibilityService`, `lockTask`, `setApplicationHidden`, `setUninstallBlocked`, `PackageManager` inventory loops.

---

## 3. Claim matrix

| Claim | API present in repo? | Enforces child app policy? | Classification |
|---|---|---|---|
| Device Owner | **No** | **No** | **R** (docs only) |
| Profile Owner | **No** | **No** | **R** |
| Accessibility enforcement | **No** | **No** | **R** |
| Usage Access / UsageStats | **No** (schema `perm_key` enum + UI labels only) | **No** | **R** |
| PackageManager inventory | **No** | **No** | **M** |
| Package hide / block | **No** | **No** | **M** |
| Launch interception | **No** | **No** | **M** |
| Foreground app detection | **No** | **No** | **M** |
| Uninstall resistance | **No** native | **No** | **U/R** (AntiTamper UI) |
| Force-stop resistance | **No** | **No** | **M** |
| Settings bypass resistance | **No** native | **No** | **U** |
| Lock Task / kiosk | **No** | **No** | **U** (in-app locks) |
| Safe Mode / alternate launch surfaces | **Not found** as enforced | **No** | **M/?** |

---

## 4. Docs-only platform claims (not code)

| Document | Claim | Status vs code |
|---|---|---|
| `family-os/18_PLATFORM_GATES.md` / prototype twin | UsageStats for metering; Device Owner for hard block; Accessibility for instant block | **Referenced, not implemented** |
| `family-os/00_READINESS_BRIEF.md` | Accessibility Play policy risk; Device Owner factory-reset caveat | Strategic risk — **no DO code** |
| Screen Time platform reqs / experience gaps | UsageStats / FamilyControls absent | Consistent with **M/R** |
| Web Filter discovery | DO/VPN/DNS/Accessibility absent for filter | Adjacent; same empty substrate |

---

## 5. In-app “enforcement” honesty

| Artifact | What it proves |
|---|---|
| `EnforcementStatusBadge` | Stage-1 enforcement is **simulated (not device MDM)** |
| `AppAccessRule.blocked` + FAT-034 | Parent UI state + prefs — **not** OS denial |
| `TimeEngine.deniedBlocked` | Algebra when inputs supplied — **tests supply inputs**; features do not |
| Instant Lock / Child Mode Lock | In-app services — **not** Lock Task / Device Admin |

---

## 6. Verdict

**Platform enforcement for Application & System Control is not implemented.**

Any product language implying that Family OS today:

- blocks third-party packages via Device Owner,  
- intercepts launches via Accessibility,  
- meters foreground apps via Usage Access, or  
- resists uninstall/force-stop at the OS layer  

…is **unsupported** by repository evidence.

---

## 7. What L2 must decide later (not decided here)

- Which enforcement mechanism(s)  
- Enrollment model (DO vs alternatives)  
- Honesty model when mechanism unavailable  
- Interaction with Play policy constraints  

**L2 POLICY: NOT STARTED**
