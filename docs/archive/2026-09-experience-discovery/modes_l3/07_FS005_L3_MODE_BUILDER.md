# 07 — FS-005 L3 Mode Builder

**Authority:** MODE-OD-01…04 · MODE-OD-07 · MODE-OD-12 · MODE-SF-05…08  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Purpose

Single builder for **built-in customization** and **custom Modes** — same canonical entity and lifecycle.

---

## 2. Sections (order)

| # | Section | Required | Notes |
|---|---|---|---|
| 1 | Identity | Yes | Name + icon; built-ins keep canonical id; customs parent-named |
| 2 | Scope | Yes | All children **or** explicit multi-select; confirm changes; **no silent expand** |
| 3 | Overlay intents (tighten-only) | Yes (≥1 plane or explicit empty = full situational tighten narrative) | App · Web · Camera/capture · Location context · ST context |
| 4 | Schedule | Optional at create; required before auto-activate | Opens unified scheduler |
| 5 | Grace | Optional | Manual skips; duration = parent param within Register reference — **no new invented defaults in L3 copy beyond reference** |
| 6 | ModeExceptions | Optional | Link to exception manager |
| 7 | Preview | Recommended before first save/activate | F12 |

---

## 3. Built-in catalog UX

| Built-in | Builder affordance |
|---|---|
| Sleep · School · Study · Ramadan · Vacation · Family Time | Enable/customize; cannot delete canonical identity |
| Study | May host education/exam-style **configuration**, not a separate `exams` Mode |
| Vacation | Tighten-only banner; **no widen allow-list CTA** |
| Family Time | Label normalized from `famtime` |

**Forbidden:** creating alias Modes `exams` / `famtime` as separate catalog rows.

---

## 4. Custom Mode

| Step | Behavior |
|---|---|
| Create | Empty entity → fill identity/scope/overlays |
| Lifecycle | Same activate/schedule/exception/delete as built-in |
| Prototype toast | Non-authority |

---

## 5. Overlay intent controls (conceptual)

Each plane offers **tighten intents** (e.g. “narrow entertainment apps”, “stricter web”, “tighten camera during Mode”) that emit **Mode overlay facts** for Kernel — **not** editors of:

- FS-003 package policy store  
- FS-002 URL lists  
- FS-004 permanent policy store  
- ST wallets/minutes  
- FS-001 geofence geometry  

Deep-links: “Edit permanent App rules → App Control”, etc.

---

## 6. Validation gates

| Gate | Block save if |
|---|---|
| Identity | Empty name |
| Scope | Selected children empty when “selected” chosen |
| Tighten | Any control that would loosen vs baseline (Vacation widen) |
| AuthZ | Partner/Observer |

---

## 7. AI assist

Suggestion card → Approve (Primary/Full) writes via builder · Reject. AI never auto-saves.
