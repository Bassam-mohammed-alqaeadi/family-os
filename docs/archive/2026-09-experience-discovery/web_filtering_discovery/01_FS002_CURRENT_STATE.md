# 01 — FS-002 Web Filtering · Current State

**System label:** FS-002 Web Filtering (discovery only)  
**Date:** 2026-09-23  
**Mode:** Read-only evidence audit — **no** redesign, **no** policy freeze, **no** app changes  
**Authority for CURRENT STATE:** repository + prior experience-discovery matrices + gap logs  
**Authority for NEW TARGET:** **none yet** — explicitly out of scope  

**Entry:** [10_FS002_DISCOVERY_MASTER.md](10_FS002_DISCOVERY_MASTER.md)

---

## 1. What “FS-002” means in this repo today

There is **no** folder or symbol named `FS-002`. The closest implemented cluster is:

| Cluster | Location |
|---|---|
| Feature UI | `app/lib/features/n04_web_filter/` |
| Policy core | `app/lib/core/policy/web_filter_*`, `web_unlock_*` |
| Screens (registry) | `SCR-FAT-036` فلترة الإنترنت · `SCR-FAT-078` فلترة الراوتر المنزلي |
| Services (catalog) | `S-SEC-014`…`S-SEC-018` |

**CURRENT STATE definition:** in-app **WebFilterPolicy** editor + **fixture/heuristic evaluator** + **polite block widget** + **unlock→allowList loop** + **mock home-router DNS screen**.  
**Not present:** OS/VPN/DNS/MDM traffic enforcement, backend `web_filter` tables, 29-category catalog, safe-search, private-browse block fields.

---

## 2. CURRENT STATE vs NEW TARGET DESIGN

| | CURRENT STATE (this package) | NEW TARGET DESIGN |
|---|---|---|
| Status | Documented from evidence | **Not started** |
| Source | Code, tests, GAP_LOG, discovery matrices, catalogs | Future L2/L3 packages |
| Rule | Classify only | Do not invent here |

Existing Stage-1 screens are **evidence**, not the future UX authority (same stance as Location L3 vs Stage-1).

---

## 3. Snapshot verdict (prior discovery alignment)

From `docs/experience_discovery/10_IMPLEMENTATION_STATUS_MATRIX.md`:

> Web filter | **A→H** | … | evaluator | **No real filter** | `web_filter_*`, `web_unlock_*`

Interpretation used here:

- **A (in-process):** policy UI, evaluator, unlock loop, widget tests.  
- **H (device/backend):** VPN/DNS/Device Owner / live browser interception / cloud policy store.

---

## 4. Actor experience (as coded)

| Actor | What exists today |
|---|---|
| **Father / Primary** | FAT-036: set level, toggle 6 categories, save, preview child block, approve/deny unlock inbox |
| **Mother** | **Configure UI:** `_canEdit` is **father-only** in current `web_filter_screen.dart` (Mother Full **cannot** edit levels/categories despite role-matrix docs saying Full can). **Unlock approve:** Partner/Full/Father; Observer denied. `motherLevel` is passed into unlock inbox, not into `_canEdit`. |
| **Child** | `WebBlockPage` widget (preview-embeddable); unlock request CTA; **no** dedicated CHD route found as primary block destination; **no** live “site request” day-board loop found in `n02_day` |
| **Guardian** | Not specially wired in web-filter screens (falls under parent RoleGuard patterns elsewhere) |

---

## 5. Closed Stage-1 gaps (in-app only — not OS)

From root `GAP_LOG.md` (2026-09-20/21):

| ID | Claim closed | Honest limit |
|---|---|---|
| SET-004 | Category rows → `WebFilterPolicy` + evaluator | Fixture hosts; 6 categories |
| SET-005 | Block page + father preview parity | Same evaluator; not OS interstitial |
| SET-006 | Unlock request approve/deny → allowList + audit append | Same-process bus |
| UI-009 | Preview verdict == child block verdict | Widget-level |

**Confidence:** High that these are closed **as Flutter loops**.  
**Confidence:** High that they do **not** equal OS enforcement.

---

## 6. Documentation / catalog claims exceeding code

| Claim source | Claim | Code reality |
|---|---|---|
| `screens.csv` FAT-036 | ٢٩ فئة + استثناءات + بحث آمن + حجب التصفح الخفي | 6 categories; allowList; **no** safe_search / block_private fields |
| Service catalog `S-SEC-016` | فرض البحث الآمن | **Missing** |
| Service catalog `S-SEC-017` | حجب التصفح الخفي | **Missing** |
| Gap spec WFP table | `dict`, `safe_search`, `block_private`, `block_list` | Policy has level/categories/allowList/version only |
| Platform capability table | Android `webFilter=full` | **No** Android filter implementation |
| `schema.sql` | — | **No** `web_filter_*` tables |

These are **CURRENT contradictions**, not resolved by this discovery.

---

## 7. Confidence legend (used across package)

| Level | Meaning |
|---|---|
| **High** | Direct code + tests |
| **Medium** | Code path exists; cross-device/OS not proven |
| **Low** | Doc/catalog only, or UI copy without backing model |
| **Unknown** | Cannot verify from repository |
