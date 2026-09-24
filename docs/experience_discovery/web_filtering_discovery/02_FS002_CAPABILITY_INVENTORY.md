# 02 — FS-002 Capability Inventory

**Mode:** Evidence-only. Capabilities appear only if supported by repo evidence, or explicitly marked **Missing / Unknown**.  
**Do not** add parental-control “industry defaults” as if present.

Classification key:

| Tag | Meaning |
|---|---|
| **I** | Exists and implemented (in-app / in-process) |
| **P** | Exists but partial |
| **U** | UI/mock only |
| **R** | Referenced (docs/catalog/gap specs) but not implemented |
| **M** | Missing |
| **C** | Conflicts with stated Family OS docs/direction |
| **?** | Cannot be verified from repository |

---

## Matrix

| Capability | Class | Evidence | Confidence |
|---|---|---|---|
| Host/URL evaluation (in-app) | **I/P** | `WebFilterEvaluator.decide` — host normalize; fixture/keyword classify | High |
| Real-time browser URL interception | **M** | No VPN/proxy/WebView hook | High |
| Category filtering (6 keys) | **I** | `WebFilterCategories` + toggles on FAT-036 | High |
| Category filtering (29 categories per registry) | **C/R** | `screens.csv` FAT-036 note vs 6 keys | High |
| Safe-search / restricted search (`S-SEC-016`) | **M/R** | Catalog; absent from `WebFilterPolicy` | High |
| Block private/incognito (`S-SEC-017`) | **M/R** | Catalog/registry; no `block_private` field | High |
| Allowlist (host exceptions) | **I** | `allowList`; unlock approve adds host | High |
| Explicit blocklist | **M/R** | Gap spec WFP `block_list`; not in policy class | High |
| Custom dictionary / keywords | **M/R** | Gap spec `dict text[]`; not in policy | High |
| Per-child policy | **I** | Repo key `web_filter_policy:{childId}` | High |
| Family-wide shared level | **P/C** | UI copy “one level for everyone” on children list; storage is per-child | Medium |
| Schedules tied to filter | **M** | No schedule×filter binding found | High |
| Temporary timed allow | **M/P** | Unlock → permanent allowList entry (no expiry found) | Medium |
| Exception / unlock ticket request | **I** | `WebUnlockRequest` + service | High |
| Parent approve / deny | **I** | Inbox on FAT-036; AuthZ in service | High |
| Child denial / polite block UI | **I** | `WebBlockPage` | High |
| Child day-board “site blocked?” request loop | **M/?** | Prototype polish mentions it; not found in `n02_day` Dart | Medium |
| Offline device enforcement | **M/?** | No child filter agent; prefs only in app process | High |
| Policy caching | **P** | Memory/prefs JSON | High |
| Policy versioning | **I/P** | `policyVersion` bumped on save; used in snapshot | High |
| Local evaluation | **I** | Evaluator pure function | High |
| Enforcement result → OS | **M** | No platform bridge | High |
| Interstitial as system block page | **U/P** | Widget exists; not proven as system interstitial | High |
| Father preview parity | **I** | Shared `WebFilterDecisionSnapshot.evaluate` | High |
| Event generation (canonical filter events) | **P** | Unlock decision bus; no rich geofence-style event model for browses | Medium |
| Push notifications | **M/P** | In-process `WebUnlockDecisionBus` only | High |
| Audit trail | **P** | `AuditAppend` strings on unlock; filter **save** audit not verified as first-class | Medium |
| Evidence pack | **M** | No dedicated evidence store for browses | High |
| Sync / replay / outbox | **M** | No web-filter outbox | High |
| Degraded / unsupported honesty | **P** | Platform capability table claims levels; no runtime probe | Medium |
| Device Owner enforcement | **M** | No DO code | High |
| Profile Owner | **M** | — | High |
| Accessibility enforcement | **M** | — | High |
| VPN / local proxy filter | **M** | — | High |
| Usage Access | **M** | Not used for filter | High |
| Router / family DNS | **U** | FAT-078 InMemory mock | High |
| Browser coverage matrix | **?** | Cannot verify — no enforcement surface | High |
| App-level WebView coverage | **?** | No hooks found | High |
| Bypass resistance (VPN kill for filter) | **M/R** | Anti-tamper has VPN-related product ideas elsewhere; not wired to evaluator | Low–Med |
| Uninstall resistance | **M** | Not web-filter specific | High |
| Feature flags for filter | **?** | No dedicated flag found | Low |
| Backend/Firestore policy sync | **M** | Firebase absent from pubspec | High |
| SQLite/Drift web_filter tables | **M/R** | Drift deferred; schema.sql lacks tables | High |

---

## Notes on partials

1. **Classifier** is intentional Stage-1 fixture (`adult.example`, token heuristics) — real category DB **Missing**.  
2. **Unlock** is a working in-app loop, not OS temporary exception tickets with expiry.  
3. **Mother configure** capability is **documented** as Full-allowed but **code `_canEdit` is father-only** — see AuthZ audit.
