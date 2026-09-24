# 10 — FS-002 Discovery Master

# FS-002 WEB FILTERING — DISCOVERY COMPLETE (EVIDENCE ONLY)

**Date:** 2026-09-23  
**Status:** CURRENT STATE audited — **NEW TARGET DESIGN not started**  
**App code modified:** **NO**  
**Screens / wireframes / policy freezes:** **NO**

**Package:** `docs/experience_discovery/web_filtering_discovery/`

---

## 1. Exact current FS-002 scope found

In-repository “web filtering” = **Flutter in-process parental control demo/spine**:

1. Parent configures `WebFilterPolicy` (3 levels, **6** categories, allowList, version) on **SCR-FAT-036**.  
2. `WebFilterEvaluator` classifies **fixture/heuristic hosts** and returns allow/deny.  
3. `WebBlockPage` shows polite deny + unlock request CTA; father preview shares the same snapshot.  
4. `WebUnlockService` implements child→parent approve/deny → host added to allowList (+ string audit + in-process bus).  
5. **SCR-FAT-078** home router DNS is a **mock** settings screen.

There is **no** OS traffic enforcement, **no** `schema.sql` web_filter tables, **no** Firebase/API filter sync.

---

## 2. Document index

| # | File |
|---|---|
| 01 | [01_FS002_CURRENT_STATE.md](01_FS002_CURRENT_STATE.md) |
| 02 | [02_FS002_CAPABILITY_INVENTORY.md](02_FS002_CAPABILITY_INVENTORY.md) |
| 03 | [03_FS002_CODE_AND_DATA_MAP.md](03_FS002_CODE_AND_DATA_MAP.md) |
| 04 | [04_FS002_PLATFORM_ENFORCEMENT_AUDIT.md](04_FS002_PLATFORM_ENFORCEMENT_AUDIT.md) |
| 05 | [05_FS002_OFFLINE_SYNC_AUDIT.md](05_FS002_OFFLINE_SYNC_AUDIT.md) |
| 06 | [06_FS002_SECURITY_AND_AUTHZ_AUDIT.md](06_FS002_SECURITY_AND_AUTHZ_AUDIT.md) |
| 07 | [07_FS002_TEST_AND_VALIDATION_AUDIT.md](07_FS002_TEST_AND_VALIDATION_AUDIT.md) |
| 08 | [08_FS002_GAPS_AND_MOCKS.md](08_FS002_GAPS_AND_MOCKS.md) |
| 09 | [09_FS002_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md](09_FS002_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md) |
| 10 | this file |

---

## 3. Implemented capabilities (in-app)

- Level presets (strict / balanced / open)  
- Six category toggles with persistence seam  
- Allowlist + unlock approve path  
- Shared preview/block verdict (`policyVersion`)  
- Unlock AuthZ (Observer denied; Partner/Full/Father)  
- Widget/unit tests for those loops  
- Mother/Father read paths on FAT-036 (edit = father-only today)

---

## 4. Partial capabilities

- Host classifier (fixtures/keywords, not intel DB)  
- Audit (lightweight `AuditAppend`)  
- Decision notify (same-process bus)  
- Platform capability **claims** without probes  
- Per-child storage vs “shared family filter” copy  
- Temporary allow (unlock is lasting allowList, no expiry found)

---

## 5. Mock / UI-only

- FAT-078 router DNS / protection check  
- Android `webFilter=full` table entry as enforcement implication  
- Decorative “protected device count” style router fixtures  

---

## 6. Missing capabilities

- Device Owner / Profile Owner / VPN / DNS / Accessibility enforcement  
- Safe-search force; private-browse block; explicit blocklist; keyword dict  
- 29-category model  
- Schedules; timed temporary allow  
- Backend/Drift schema; outbox; multi-device sync  
- System interstitial in real browsers  
- Bypass/uninstall resistance tied to filter  
- Browse evidence packs / rich event pipeline  

---

## 7. Enforcement reality

**In-process UI evaluation only.**  
No repository evidence that Family OS blocks third-party browser/app network requests using WFP.

---

## 8. Offline reality

Prefs may persist in-app.  
**No** verified child-device offline enforcement agent or filter outbox.

---

## 9. Security / AuthZ reality

| Topic | Reality |
|---|---|
| Unlock AuthZ | **Real in code** |
| Configure AuthZ | **Father-only in FAT-036** — **conflicts** with Mother Full docs |
| OS boundary | **Missing** |
| Audit | **Partial** |

---

## 10. Test / validation reality

Strong Flutter coverage for SET-004/005/006/UI-009 **in-app**.  
**Zero** OS/VPN/DNS integration proof.

---

## 11. Cross-system dependencies

See [09](09_FS002_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md).  
Key ambiguities: Mother Full edit; enforcement plane ownership; AuditAppend vs AuditLog; filter vs app-block vs modes; FAT-078 vs on-device filter.

---

## 12. Contradictions (CURRENT)

1. Registry/catalog (29 cats, safe search, private browse) ≠ code model.  
2. Mother Full configure docs ≠ `_canEdit` father-only.  
3. Platform capability “full” ≠ no Android enforcer.  
4. Gap-spec SQL ≠ `schema.sql`.  
5. GAP_LOG “CLOSED” ≠ product-complete OS filter.

---

## 13. Unknowns requiring future Owner / design (not decided here)

| ID | Unknown |
|---|---|
| U-WF-01 | Which enforcement plane(s) are in-scope (VPN, DO, DNS, hybrid)? |
| U-WF-02 | Align Mother Full configure with code or amend docs? |
| U-WF-03 | Per-child vs family-shared policy product law? |
| U-WF-04 | Keep 6 Stage-1 categories vs build toward 29? |
| U-WF-05 | Safe-search / incognito — still P0 for FS-002? |
| U-WF-06 | Unlock = permanent allow vs timed temporary? |
| U-WF-07 | FAT-078 router — same system as on-device filter or separate? |
| U-WF-08 | How filter interacts with Smart Modes / app blocks / SOS availability on device |

These are **discovery unknowns**, not silent assumptions.

---

## 14. What this package does **not** do

- Redesign FS-002  
- Freeze policy  
- Choose VPN vs Device Owner  
- Write Flutter/Android code  
- Create L2/L3 target contracts  

---

## 15. Recommended next phase (outside this package)

Only when Owner commissions: **FS-002 L2 Policy Freeze** (or equivalent), using this discovery as evidence baseline — same pattern as Location `location_final/` after discovery.

---

## 16. Verdict

| Gate | Status |
|---|---|
| Discovery package complete | **YES** |
| CURRENT STATE documented | **YES** |
| NEW TARGET DESIGN | **L2 package delivered** — [`../web_filtering_l2/11_FS002_L2_MASTER_CONTRACT.md`](../web_filtering_l2/11_FS002_L2_MASTER_CONTRACT.md) |
| L2 Owner decisions | **REQUIRED** (Q-WF-01…15) |
| L3 / Implementation | **NOT STARTED / NOT AUTHORIZED** |

**STOP (discovery).** Continue Owner decisions in `web_filtering_l2/`.
