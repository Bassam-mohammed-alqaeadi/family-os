# 08 — FS-003 Gaps and Mocks

**Mode:** Inventory of mocks, stubs, placeholders, incomplete loops, and closed-vs-incomplete contradictions.  
**Do not close gaps here. Do not redesign.**  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Explicit mocks / fixtures

| Artifact | Nature |
|---|---|
| `child_apps_mock.dart` / `kDefaultChildAppsByChild` | Seeded product-name inventory; slug IDs |
| `InMemoryChildAppsRepository` | Stage-1 default seam |
| `stage1AppAccessRulesStore` | In-memory prefs stand-in |
| FAT-069 usage report | Fixture / `simulated` honesty class (adjacent) |
| `PolicySyncBus` | Same-isolate simulation without FCM |
| Child Mode Lock password | Mock account password constant |
| Instant Lock / Anti-tamper | Prefs flags — not MDM |

---

## 2. Partial / incomplete product loops

| Loop | Status |
|---|---|
| Allow/block on FAT-034 → persist `AppAccessRule` | **Works in-process** |
| Persist → live `TimeContext` in features | **Incomplete** (`AppAccessRuleQuery` test-only) |
| Persist → child device | **Missing** |
| Persist → OS block | **Missing** |
| Pending install → FAT-035 | **UI works** on mock pending rows |
| Real install detection → pending | **Missing** |
| Child requests unlock of blocked app | **Missing** (minutes/web only) |
| Per-app instant lock toggle | Prototype has it; Flutter field **display/unwired** |

---

## 3. Referenced-but-missing (docs/catalog)

| Reference | Gap |
|---|---|
| S-SEC-008…013 registry services | Category rules / new-install — UI partial; no OS |
| Platform gates UsageStats / DO / Accessibility | No Android implementation |
| WF-OD-12 stricter intersection | Contract text only |
| Schema `USAGE_STATS` / `ACCESSIBILITY` perm keys | Enum presence ≠ enforcement |
| FAT-034 engineering `app_rule.*` events | Not proven as emitted event pipeline |
| `schema.sql` app policy tables | **Absent** |

---

## 4. Closed gap records vs incomplete behavior

| Observation | Classification |
|---|---|
| `GAP_LOG.md` has no open FAT-034 enforcement row | Risk of **silent incompleteness** — UI shipped ≠ OS control |
| CONVERSION_LOG marks FAT-034 shipped | ScreenBuild done; **enforcement substrate empty** |
| Screen Time truth doc still says FAT-034 disconnected from TimeEngine | **C/P** — code added query+persist; features still disconnected |

---

## 5. Placeholders / aspirational copy

- Empty inventory: “when this child’s device reports installed apps” — aspirational (no PackageManager).  
- Shared allow/block between parents — care copy, not a family policy store.  
- Tip language implying child-device reflection — honesty conflict with sync audit.

---

## 6. Unknowns (not invented)

1. Target package-ID mapping model  
2. Install detection pipeline owner  
3. Product intent for app-specific unlock vs minutes-only / lock exception  
4. Category-level policy entity vs display headers only  
5. Backend tables deferred beyond Wave-1 schema?  
6. iOS Screen Time API path (`SCREEN_TIME_IOS` enum) — out of Android enforcement evidence  

---

## 7. Gap list (discovery IDs — for L2/L3 later)

| ID | Summary | Class |
|---|---|---|
| FS003-GAP-01 | No OS enforcement substrate | **M** |
| FS003-GAP-02 | No package-ID inventory | **M/U** |
| FS003-GAP-03 | App rules off PolicySyncBus | **M** |
| FS003-GAP-04 | AppAccessRuleQuery not in features | **P** |
| FS003-GAP-05 | No app unlock ticket | **M** |
| FS003-GAP-06 | No policyVersion/ack for app rules | **M** |
| FS003-GAP-07 | AuthZ eng doc ≠ Partner edit code | **C** |
| FS003-GAP-08 | No schema app_rule tables | **M** |
| FS003-GAP-09 | WF ∩ App Control evaluator absent | **R** |
| FS003-GAP-10 | instantLocked unwired in Flutter | **P/U** |
