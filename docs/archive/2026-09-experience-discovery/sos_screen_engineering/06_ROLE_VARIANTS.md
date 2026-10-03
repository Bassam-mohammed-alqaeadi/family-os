# 06 — Role Variants

**Authority:** Frozen role matrix OD-01…04 + Q-SOS-RD-02A  
**Screens:** CHD-005/006 · FAT-018 · FAT-028

---

## 1. Capability × role (UI must enforce)

| Capability | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| CHD-005 trigger | lean | lean | lean | lean | ✅ |
| CHD-006 active / cancel | lean | lean | lean | lean | ✅ |
| FAT-018 view essential | ✅ | ✅ | ✅ | ✅ | lean |
| FAT-018 contact child | ✅ | ✅ | ✅ | ✅ | — |
| FAT-018 acknowledge | ✅ | ✅ | ✅ | ❌ | ❌ |
| FAT-018 escalate | ✅ | ✅ | ✅ | ❌ | ❌ |
| FAT-018 resolve | ✅ | ✅ | ✅ | ❌ | ❌ |
| FAT-018 Break-glass | ✅ | ✅ | ❌ | ❌ | ❌ |
| FAT-028 configure | ✅ | ✅ | ❌ | ❌ | ❌ |
| Panic Quiet configure | ✅ | ✅ | ❌ | ❌ | effect only |

---

## 2. Per-screen deltas

### CHD-005 / CHD-006

- Child: interactive bodies.  
- Any parent: lean empties. No config.

### FAT-018

| Role | Visible actions |
|---|---|
| Observer | Contact child, map (if usable), read-only timeline/delivery |
| Partner | + Acknowledge, Escalate, Resolve, Contact |
| Full / Primary | + Setup link, Break-glass when needed |

Observer must **not** see Resolve, Escalate, Configure, Break-glass (hide, not merely disable—prefer hide to avoid tease).

### FAT-028

| Role | UI |
|---|---|
| Primary / Full | Full editor |
| Partner / Observer / Child | RoleGuard lean or redirect |

---

## 3. SosRoleGuard component duty

Input: `AppRole`, `MotherLevel?`, `actionId`.  
Output: `allowed` bool.  
Used by FAT-018 action bar and FAT-028 route/body.
