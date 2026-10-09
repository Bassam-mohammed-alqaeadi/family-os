# 06 — FS-002 Security & AuthZ Audit

---

## 1. Role matrix (docs) vs code

| Capability | Docs (`03-role-permission-matrix` / doc 20) | Code evidence |
|---|---|---|
| Configure web filter level/lists | Father ✅ · Mother Full ✅ · lower ⛔ | FAT-036 `_canEdit` → **`role == AppRole.father` only** — Mother Full **cannot** edit |
| Approve web unlock | Father; Mother Partner/Full (SET-006) | `WebUnlockService` + `WebUnlockActor.canApproveUnlock` — Observer throws |
| Child configures filter | ⛔ | Parent routes; child uses block page |
| Advisor executes filter change | Suggest only | No AI execute path found |

**Conflict (C):** Documented Mother Full configure right **≠** current FAT-036 edit gate.  
`motherLevel` is used for unlock inbox AuthZ, **not** for category/level edit.

**Confidence:** High (direct `_canEdit` read).

---

## 2. Unlock AuthZ (implemented)

| Actor | Approve/Deny |
|---|---|
| Father | Allowed |
| Mother Partner | Allowed |
| Mother Full | Allowed |
| Mother Observer | **Denied** (`WebUnlockNotAllowedException`) |
| Child | Requests only |

Father-wins conflict covered in tests (`web_unlock_service_test.dart`).

---

## 3. Identity & tenancy

| Topic | Finding |
|---|---|
| Child scoping | Policy/unlock keyed by `ChildId` |
| FamilyId on filter events | **Not first-class** on `WebFilterPolicy` model |
| Device/enrollment on decisions | **Missing** on web-filter types |
| RBAC from device ownership inference | Unlock uses explicit `WebUnlockActor` — good pattern |

---

## 4. Audit / evidence

| Action | Audited? | How |
|---|---|---|
| Unlock approve/deny | **Partial** | `AuditAppend` string list on service |
| Policy save (level/categories) | **Not verified** as append to product `AuditLogRepository` | Toast only on save |
| Preview open | No | — |
| Router check | No real audit | Mock |

**Ambiguity:** Whether Stage-1 `AuditAppend` is the same seam as constitution R-10 audit log — **ownership unclear**.

---

## 5. Tamper / bypass

| Topic | Finding |
|---|---|
| Child disable filter UI | No child configure surface |
| VPN bypass of filter | **No** filter-VPN coupling; anti-tamper is separate product area |
| Uninstall resistance | **Missing** for filter |
| Entitlement gating of filter | Not observed on FAT-036 (safety-adjacent; forever-free location/SOS are separate) |

---

## 6. Data sensitivity

| Data | Handling |
|---|---|
| Requested URLs | Stored in unlock requests (prefs) |
| Category decisions | Local policy JSON |
| Encryption at rest | **Unknown** (memory/prefs; no KMS) |

---

## 7. Summary classes

| Area | Class |
|---|---|
| Unlock AuthZ | **Implemented** (in-app) |
| Configure AuthZ vs docs | **Conflict / partial** |
| OS security boundaries | **Missing** |
| Audit completeness | **Partial** |
