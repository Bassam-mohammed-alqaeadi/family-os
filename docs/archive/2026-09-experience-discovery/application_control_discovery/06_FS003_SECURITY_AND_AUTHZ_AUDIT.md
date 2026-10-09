# 06 — FS-003 Security and AuthZ Audit

**Mode:** Record **current** roles, gates, inconsistencies, and authorities.  
**Do not** adopt legacy Father/Mother behavior as target law.  
**Flag conflicts for later L2 Owner decisions — do not resolve here.**  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Current roles (evidence)

Observed in FAT-034/035 code:

| Role | Source |
|---|---|
| `AppRole.father` | Router / `CurrentRole` |
| `AppRole.mother` + `MotherLevel` (partner / full / observer) | Widget params + role notifier |
| `AppRole.child` | Lean empty variants |

---

## 2. Current gates — FAT-034 / FAT-035

### Router

- Global `roleGuardRedirect` blocks child from **owner-only** paths (billing, audit subset).  
- **FAT-034 and FAT-035 are NOT owner-only / father-only** in router lists.

### In-screen AuthZ (code)

```dart
bool get _canControl {
  if (_role == AppRole.father) return true;
  if (_role == AppRole.mother) {
    return widget.motherLevel == MotherLevel.partner ||
        widget.motherLevel == MotherLevel.full;
  }
  return false;
}
```

Evidence: `child_apps_screen.dart`, `new_app_approval_screen.dart`.

| Actor | FAT-034 | FAT-035 |
|---|---|---|
| Father | Full allow/block/unlimited | Approve/deny |
| Mother Partner | Full mutate | Approve/deny |
| Mother Full | Full mutate | Approve/deny |
| Mother Observer | View-only + hint | View-only |
| Child | Lean empty + SOS | Lean empty + SOS |

### SOS

SOS CTAs remain reachable on app-control screens (constitution / P-4 class behavior). **Ungated by subscription.**

---

## 3. Adjacent AuthZ (not FS-003 target, but related evidence)

| Domain | Current gate |
|---|---|
| Anti-tamper configure | Father-only (`canConfigureAntiTamper`) |
| Web Filter unlock | Observer denied; Partner/Full/Father (FS-002 evidence) |
| Time request approve | Partner+ with ADR-039 ceilings (Screen Time) |

---

## 4. Current child authority

- **Cannot** edit app allow/block from FAT-034 lean variant.  
- **Can** reach SOS from those surfaces.  
- **No** dedicated child “request unlock of blocked app” ticket path found (minutes + web unlock only).

---

## 5. Current parent authority

- Father and Mother Partner/Full can mutate app statuses in Stage-1 UI.  
- Permanent block reopen as **father-only** (ADR-035 / eng doc) — **not found as a distinct code gate**.

---

## 6. Conflicts for L2 (record only — do not resolve)

| ID | Conflict |
|---|---|
| **AUTHZ-C1** | `04_FAT_034_ENGINEERING.md`: Partner/Observer **read**; Primary + Mother Full **edit** — **code lets Partner edit** |
| **AUTHZ-C2** | Engineering/ADR-035: father-only reopen of permanent blocks — **not implemented as distinct gate** |
| **AUTHZ-C3** | UI “shared between parents” vs per-child store only |
| **AUTHZ-C4** | Policy Register P-3 (“blockedApps readable only by FatherSession”) vs Mother Partner/Full mutation in UI |
| **AUTHZ-C5** | Do not treat device ownership as AuthZ (SOS break-glass law elsewhere) — no DO layer exists anyway |

---

## 7. Security boundary reality

| Boundary | Reality |
|---|---|
| OS package isolation | **Missing** |
| Tamper resistance | **UI/prefs flags only** |
| Audit of app mutations | **Partial / largely missing** |
| RoleGuard structural | Present for owner-only screens; app control uses **in-screen** checks |

---

## 8. L2 Owner decisions deferred

- Who may permanently block / reopen  
- Mother Partner vs Full authority on app control  
- Shared vs per-child policy ownership  
- Child request rights for blocked apps  

**L2 POLICY: NOT STARTED**
