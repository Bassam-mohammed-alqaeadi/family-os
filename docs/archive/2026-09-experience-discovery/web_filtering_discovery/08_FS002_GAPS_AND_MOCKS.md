# 08 — FS-002 Gaps and Mocks

---

## 1. UI / mock-only

| Item | Evidence | Risk if mistaken for real |
|---|---|---|
| FAT-078 home router DNS | InMemory repo; fake device counts | Parents believe home LAN is filtered |
| `runProtectionCheck` | Returns same snapshot | False “protected” confidence |
| Platform `webFilter=full` (Android) | Static table | UI may imply full enforcement |
| Evaluator fixture hosts | `adult.example`, keywords | Demo ≠ category intel |
| Children list “shared web filter” | Copy | Ambiguous vs per-child storage |

---

## 2. Partial implementations

| Item | Missing half |
|---|---|
| Allowlist unlock | No timed expiry / temporary grant |
| policyVersion | No cross-device snapshot sync |
| AuditAppend | Not full immutable audit product seam |
| Decision bus | Not push notification |
| WebBlockPage | Not proven as system interstitial |
| 6 categories | Not 29; no dict |

---

## 3. Referenced but not implemented

| Reference | Where |
|---|---|
| WFP/WFR SQL tables | `08-gap-closure-specs.md` |
| `safe_search`, `block_private`, `block_list`, `dict` | Same + catalog S-SEC-016/017 |
| 29 categories | `screens.csv` FAT-036 |
| Child last-synced offline enforce | Cross-role dependency docs |
| VPN/DNS enforcement | Experience discovery risks / exploration order |

---

## 4. Missing (no code path)

- OS enforcement plane  
- Backend policy sync  
- Schema tables  
- Safe-search force  
- Incognito/private block  
- Explicit blocklist model  
- Schedule-bound filter  
- Browse event telemetry pipeline  
- Bypass/uninstall resistance for filter  
- Dedicated child CHD block route (optional product — currently widget-only)

---

## 5. Conflicts with Family OS direction / docs

| Conflict | Detail |
|---|---|
| Registry 29 cats + safe search + private | Code 6 cats; fields absent |
| Mother Full configure | Docs ✅ · FAT-036 `_canEdit` father-only |
| Capability table “full” | No Android enforcer |
| SET closed in GAP_LOG | Means in-app loops, not FS-002 complete product |

---

## 6. Placeholders / empty handlers

| Pattern | Location |
|---|---|
| Home router check no side effects | `HomeRouterFilterRepository.runProtectionCheck` |
| Drift deferred comments | Policy repositories |
| Stage-1 singletons | `stage1WebFilterPrefsStore`, unlock stores |

No empty `onPressed: () {}` called out as primary FAT-036 save path — save hits repository (real in-app write).
