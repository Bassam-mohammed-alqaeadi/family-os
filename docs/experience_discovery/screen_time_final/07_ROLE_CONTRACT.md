# 07 — Role Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Authority:** Doc 20 Mother permissions · ADR-035/035-b/039 · Owner ST-OD-012 · Product freeze  

**Principle:** Level-specific experiences — do **not** clone Primary UI and hide buttons.

---

## Primary (Father / OWNER)

| Capability | Allowed |
|---|---|
| Full policy ownership | Yes |
| Caps / schedules / app rules / unlimited / countable | Yes |
| Overflow switch | Yes |
| Mother level + grant ceiling as rules | Yes |
| Approve/reject any grant amount | Yes |
| Instant lock / unlock | Yes |
| Anti-tamper visibility | Yes (father-only) |
| Unlock father-blocked apps | Yes |
| Attribution / earn approvals | Yes |
| Billing / privacy / delete family | Yes (owner-only domains) |

---

## Mother Observer

| Capability | Allowed |
|---|---|
| View screen-time state / history appropriate to “see what father sees” | Yes (read-only) |
| Approve/reject requests | **No** |
| Grant Minutes | **No** |
| Edit caps/schedules/overflow/apps | **No** |
| Instant lock | **No** |
| Anti-tamper | Invisible |
| SOS / chat / location | Always (outside gradation) |

**UX:** Status-first; no fake disabled primaries.

---

## Mother Partner

| Capability | Allowed |
|---|---|
| Approve/reject time requests | Yes |
| Grant within ADR-039 ceiling | Yes |
| Policy authoring (caps/schedules/apps/overflow) | **No** |
| Instant lock | **No** |
| Anti-tamper / father-block unlock | **No** |

**UX:** Decision-centric (inbox + remaining + last outcome).

---

## Mother Full

| Capability | Allowed |
|---|---|
| Approve/reject within ceiling | Yes (ceiling still applies — ADR-039) |
| Edit caps / schedules | Yes (operational) |
| Edit overflow switch | **Yes** (ST-OD-012) — audited, Primary-visible, not ownership transfer |
| Instant lock | Yes (Father can reverse) |
| Change mother level / ceiling rule ownership | **No** |
| Anti-tamper | Invisible |
| Unlock father-blocked app | **No** |
| Billing / Brain ownership / delete family | **No** |

**UX:** Operational console without owner controls.

---

## Child

| Capability | Allowed |
|---|---|
| View remaining (3-part model) | Yes |
| Request more time (one pending) | Yes |
| View wallets (per-app) | Yes |
| Chat / Quran / SOS | Always |
| Mutate policy | No |

---

## Conflict

Father unlock supersedes mother lock + audit (ADR-035). Unchanged.
