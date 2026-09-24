# 04 — FS-002 Platform Enforcement Audit

**Rule:** Never describe a mechanism as enforcing browsing unless repository evidence supports it.

---

## 1. Mechanism checklist

| Mechanism | Present in repo? | Used for web filter? | Evidence |
|---|---|---|---|
| **Device Owner** | **No** | No | No DO APIs; matrix H; bare `MainActivity` |
| **Profile Owner / work profile** | **No** | No | — |
| **Accessibility service** | **No** (for filter) | No | No filter Accessibility code |
| **VPNService / local proxy** | **No** | No | No VpnService; experience discovery: “No real filter / H VPN” |
| **Usage Access** | Unrelated / not for URL | No | — |
| **DNS (on-device private DNS API)** | **No** | No | — |
| **Router DNS configuration API** | **No** | UI mock only | FAT-078 InMemory |
| **Browser extension / content filter** | **No** | No | — |
| **Managed configurations / MDM web rules** | **No** | No | — |
| **In-app WebView shouldOverrideUrlLoading** | **Not found** as product filter path | No | Evaluator not hooked to a browsing WebView product |
| **Flutter `WebFilterEvaluator`** | **Yes** | **Decision only when UI invokes it** | Preview + `WebBlockPage` |

---

## 2. Claimed vs actual

| Claim | Source | Actual |
|---|---|---|
| Android `MonitoringFeature.webFilter` = `full` | `platform_capability_table.dart` | **Claimed capability level** for honesty UI — **not** an OS enforcer |
| iOS webFilter = `reportsOnly` | Same table | Honesty that iOS may not fully enforce — still no iOS filter bridge in app |
| FAT-078 “Family DNS on router” | ARB + screen | **Mock** guide/check; no router protocol |
| Registry “حجب التصفح الخفي” | screens.csv | **No** platform private-browse API usage |

---

## 3. Enforcement reality statement

**CURRENT enforcement plane = Flutter in-process decision + UI.**  

There is **no** verified path where a child opens Chrome/Safari/YouTube and Family OS blocks the navigation via Device Owner, VPN, DNS, or Accessibility based on `WebFilterPolicy`.

Any product copy implying “the phone is filtered” beyond the in-app demo is **unsupported by repository evidence**.

---

## 4. Fallback / unsupported paths

| Path | Status |
|---|---|
| Primary enforcement (future) | **Unknown / not chosen** in this discovery |
| Fallback capability plane | **Not implemented**; platform table is the only “honesty” scaffold |
| Degraded mode when OS denies VPN/DO | **Not implemented** for filter |

---

## 5. Confidence

| Finding | Confidence |
|---|---|
| No VPN/DO/Accessibility filter code | **High** |
| Evaluator does not see system traffic | **High** |
| FAT-078 non-enforcing | **High** |
| Future intended mechanism (VPN vs DO vs DNS) | **Unknown** — docs discuss options; no locked choice in code |
