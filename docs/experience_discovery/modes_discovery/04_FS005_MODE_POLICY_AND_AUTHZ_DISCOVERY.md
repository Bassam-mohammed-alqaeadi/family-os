# 04 — FS-005 Mode Policy and AuthZ Discovery

**Mode:** Evidence of policy surfaces and authorization — **no Owner freeze**.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Register policy model (target text)

From Register §3 — each mode should carry:

| # | Property | Stage-1 Flutter evidence |
|---|---|---|
| 1 | Identity name + icon | Labels via ARB; icon field **MISSING** in prefs |
| 2 | Scheduling (weekly / manual-only / seasonal) | School TOD only; seasonal **MISSING**; weekly days **MISSING** |
| 3 | Scope (all children or selected) | Per-`childId` store; multi-select **MISSING** |
| 4 | Allowed apps (still time-governed) | Not stored on `SmartModeRow`; TimeEngine supports flag |
| 5 | Special exceptions | Flag `hasModeException` only |
| 6 | Entry behavior (grace) | Domain clamp; runtime UX **MISSING** |

---

## 2. Authorship candidates (OPEN)

| Question | Evidence | Status |
|---|---|---|
| Who may create custom modes? | Register: father sovereignty; prototype CTA | **Q-MODE-04** |
| Who may activate? | FAT-085 any session user today | **Q-MODE-02 / Q-MODE-13** |
| Who may edit schedules? | Same | **Q-MODE-02** |
| Family vs child scope | Proto `kids[]` vs prefs `childId` | **Q-MODE-01** |

Screen-time eng doc (`09_FAT_085_ENGINEERING.md`) proposes: Primary + Mother Full configure/activate; Partner/Observer read — **engineering proposal only**, not frozen FS-005 L2.

---

## 3. Identity / RoleGuard evidence

| Surface | Guard found? |
|---|---|
| `/scr-fat-085` route | **No** RoleGuard in builder |
| `SmartModesScreen` | **No** mother ceiling / can() checks |
| CHD-004 | Child display of activation — appropriate for visibility |

Constitution Rule 8: role guarding via RoleGuard in router — **gap for Modes host**.

---

## 4. Priority / conflict / stacking

| Mechanism | Evidence | Product freeze? |
|---|---|---|
| Single active in prefs | `SmartModePrefs.withRow` deactivates others | Matches prototype `setFamilyMode` |
| M-B stricter intersect | `ModeConflictResolver.stricter` | Implies multi-mode possible — **contradicts single-active UI** |
| Instant lock / permanent block above mode | `TimeEngine` | Register law — already frozen |
| ScheduleWindow vs SmartMode both set `modeActive` | Two producers | **Q-MODE-06 / Q-MODE-08** — do not freeze |

---

## 5. Tighten vs loosen

| Source | Stance |
|---|---|
| FS-002 L2 WF-OD-13 | Modes **tighten only** for filter |
| FS-003 L2 APP-OD-11 | Modes **tighten only**; cannot reopen Permanent Block |
| FS-004 L2 | Modes tighten Screen/Camera; must not permanently remove |
| Prototype vacation | Wider `allowedApps`, `strict:0` — **loosens** |
| Register M-A | Allowed list can be nonempty (school allows whatsapp) — not explicitly “never widen vs baseline” |

**Owner decision required:** **Q-MODE-07**. Discovery does **not** adopt sibling tighten-only as FS-005 law yet — it records the contradiction.

---

## 6. Exceptions vs grants vs app unlock

| Instrument | Owner (frozen elsewhere) | Mode relation |
|---|---|---|
| ModeException | Register Ruling A | Pierce mode allow-list; still time-governed |
| Temporary Grant | Screen Time | Minutes/time; Ruling C when intersects mode start |
| App Access Exception | FS-003 APP-OD-06 | Package timed override — **not** ModeException |
| Web unlock | FS-002 | URL timed allow — Modes must not rewrite lists |

Stage-1: ModeException store/UI on FAT-085 **MISSING**; GrantOnModeStart dialog **MISSING**.

---

## 7. Child AuthZ / visibility

| Topic | Evidence |
|---|---|
| Child cannot author policy | Register R-5; CHD-004 display-only for mode |
| Child ends grace (proto) | GAP-A-CHILD-015 — unilateral clear | **Q-MODE-10** |
| Child sees active mode | CHD-004 tint + label | **PARTIAL** |

---

## 8. Open Owner questions (policy / AuthZ)

See full list in closure report: **Q-MODE-01…14** (subset here: 01, 02, 03, 04, 05, 07, 10, 11, 12, 13).
