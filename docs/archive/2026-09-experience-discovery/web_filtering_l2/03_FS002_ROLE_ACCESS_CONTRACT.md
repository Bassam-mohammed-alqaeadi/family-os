# 03 — FS-002 Role Access Contract (L2 Target) — FROZEN

**Status:** FROZEN · WF-OD-02 / WF-OD-03 / WF-OD-15  
**Vocabulary:** Primary Parent · Co-Parent Observer · Partner · Full · Child

---

## 1. Hard rules

| Rule | Law |
|---|---|
| Configure policy | **Primary + Co-Parent Full** only (WF-OD-02) |
| Partner / Observer configure | **Forbidden** |
| Unlock approve/deny | **Primary + Partner + Full** (WF-OD-03) |
| Observer unlock decide | **Forbidden** |
| Child configure / lists / admin | **Forbidden** |
| Child surfaces | Block interstitial + non-interactive filter-active disclosure (WF-OD-15) |
| Stage-1 father-only edit | **Rejected** as target |
| RBAC only | WF-SF-05 |
| Co-Parent Full ≠ Primary for owner-only classes | WF-SF-06 (export of evidence remains Primary-leaning unless later OD) |

---

## 2. Capability matrix

| Capability | Primary | Observer | Partner | Full | Child |
|---|:-:|:-:|:-:|:-:|:-:|
| View effective/family policy summary | ✅ | ✅ | ✅ | ✅ | ⛔ |
| Edit family baseline / child override / lists | ✅ | ⛔ | ⛔ | ✅ | ⛔ |
| Preview interstitial | ✅ | ✅ | ✅ | ✅ | — |
| Request unlock | — | — | — | — | ✅ |
| Approve / deny unlock | ✅ | ⛔ | ✅ | ✅ | ⛔ |
| See enforcement degraded honesty | ✅ | ✅ | ✅ | ✅ | disclosure only |
| Child block + filter-active disclosure | — | — | — | — | ✅ |
| See lists/categories/rules/admin | ✅* | view summary only | view summary only | ✅* | ⛔ |

\* Edit rights only for Primary/Full; view of configured lists for editors.

---

## 3. Audited actions

Policy save · list mutations · unlock request · unlock decide · (Primary) any future evidence export.
