# 03 — Role–Permission Matrix
**Mission:** Discovery phase 2 (role matrix) · Branch `discovery/master-plan`  
**Date:** 2026-09-19 · **Authority:** Section A3 actor model + `20_MOTHER_PERMISSIONS.md` + Policy Register §6 + schema CHECKs  
**Status:** CHECKPOINT — awaiting owner audit before phase 3

---

## 1. Actor cast (do not expand)

| # | Actor | Kind | Schema / runtime |
|---|---|---|---|
| 1 | Father | PRIMARY | `OWNER` + `FULL` |
| 2 | Mother | PRIMARY | `PARENT` + OBSERVER \| PARTNER \| FULL |
| 3 | Child | PRIMARY | `child` row + `CHILD_*` device mode |
| 4 | Guardian | SECONDARY | `GUARDIAN` + **OBSERVER only** (non-upgradable) |
| 5 | Family Advisor | SECONDARY (SYSTEM) | AI repos / `ai_suggestion` — no login role |

**UI note:** Mother and Father share the **الوالدان (FAT)** screen set; access is enforced by **RoleGuard** (constitution Rule 8), not by a separate Mother app. Guardian, if present in UI, is view-degraded FAT surfaces only.

---

## 2. Permission legend

| Symbol | Meaning |
|---|---|
| ✅ | Allowed |
| ⛔ | Forbidden |
| ◐ | Allowed only at stated mother level |
| — | Not applicable |
| 🔔 | Always receives (cannot be stripped) |

Mother levels (father-set, default **PARTNER / مشاركة**):

| Level | Arabic | Schema `perm_level` |
|---|---|---|
| ① Viewer | مطّلعة | `OBSERVER` |
| ② Partner | مشاركة (default) | `PARTNER` |
| ③ Full | كاملة | `FULL` |

---

## 3. Master capability matrix

### 3.1 Family administration

| Capability | Father | Mother ① | Mother ② | Mother ③ | Guardian | Child | Advisor |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Create family / become owner | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Invite mother / set her level | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Change mother level (audit + notify) | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Downgrade mother (double confirm) | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Invite guardian (observer only) | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Add / remove child profile | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Pair child device (QR) | ✅ | ⛔ | ⛔ | ⛔ | ⛔ | ✅ scan | ⛔ |
| Subscription / billing | ✅ owner-only | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Privacy / audit log screens | ✅ owner-only | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Delete / wipe family (regret window) | ✅ owner-only | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| Transfer ownership | Deferred wave 2 | — | — | — | — | — | — |

### 3.2 Visibility & reassurance (never stripped from mother/guardian where marked)

| Capability | Father | Mother ①②③ | Guardian | Child | Advisor |
|---|:-:|:-:|:-:|:-:|:-:|
| See family dashboard / child cards | ✅ | ✅ | ✅ view | Own only | Suggest context |
| See child location | ✅ | 🔔 ✅ | 🔔 ✅ | Self (policy) | — |
| Receive SOS / critical alerts | ✅ | 🔔 ✅ | 🔔 ✅ | Initiates | May surface alert types |
| Family chat & calls | ✅ | 🔔 ✅ | ✅ observe/participate per invite | ✅ | ⛔ (not a chat member) |
| View monitoring transparency (child-side) | Configures | Sees reports | Sees | **Must see** card | — |

### 3.3 Approvals & time economy

| Capability | Father | Mother ① | Mother ② | Mother ③ | Guardian | Child | Advisor |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Create task with **minutes** reward | ✅ sets amount | ⛔ | ◐ add/edit task | ◐ | ⛔ | Complete/proof | Suggest only |
| Assign task to mother (help request) | ✅ | Receives (no minutes) | same | same | ⛔ | — | — |
| Approve child proof → deposit minutes | ✅ | ⛔ | ✅ | ✅ | ⛔ | — | Propose; father/mother²⁺ approve |
| Approve time-extension request | ✅ | ⛔ | ✅ (≤30 min per doc 20) | ✅ | ⛔ | Request | Suggest |
| Manual grant / wallet gift | ✅ | ⛔ | ◐ if delegated | ◐ | ⛔ | — | Suggest |
| Edit rules / daily caps / blocks | ✅ | ⛔ | ⛔ | ✅ | ⛔ | ⛔ | Suggest |
| **Instant lock** child device/apps | ✅ | ⛔ | ⛔ | **✅** (protective; father reversible) | ⛔ | ⛔ | ⛔ |
| **Unlock a father-blocked app** | ✅ **owner-only** | ⛔ | ⛔ | **⛔** | ⛔ | ⛔ | ⛔ |
| **Edit the delegation level itself** | ✅ **owner-only** | ⛔ | ⛔ | **⛔** | ⛔ | ⛔ | ⛔ |
| Smart modes create/edit | ✅ | ⛔ | ⛔ | ✅ | ⛔ | Sees tint/card | Suggest |
| Bypass father limits | — | ⛔ | ⛔ | ⛔ | ⛔ | **Never** | ⛔ |

**ADR-035 (owner ruling, 2026-09-19):** At Mother **FULL**, *instant lock* is **allowed** as a protective action that the father can reverse. **Father-only even at FULL:** anti-tamper switches, unlocking a father-blocked app, and changing the delegation level. On simultaneous conflicting actions, **the father always wins**; every such action and conflict resolution writes to `audit_log`.

### 3.4 Safety, location, network

| Capability | Father | Mother ① | Mother ② | Mother ③ | Guardian | Child | Advisor |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Configure geofences / safe zones | ✅ | ⛔ | ⛔ | ✅ | ⛔ | — | Suggest |
| Configure SOS escalation ladder | ✅ | ⛔ | ⛔ | ⛔* | ⛔ | Trigger SOS | — |
| Web filter level / lists | ✅ | ⛔ | ⛔ | ✅ | ⛔ | Sees block page | Suggest |
| **Anti-tamper switches** | ✅ **owner-only** | ⛔ | ⛔ | **⛔** | ⛔ | Subject to | — |
| Contact whitelist / strangers block | ✅ | ⛔ | ⛔ | ✅ | ⛔ | Uses approved | — |

\*Emergency contact setup is father-owned in registry (`SCR-FAT-028`); mother always **receives** SOS (right that does not grade).

### 3.5 Intelligence (Family Advisor)

| Capability | Father | Mother | Guardian | Child | Advisor (system) |
|---|:-:|:-:|:-:|:-:|---|
| Open Advisor FAB / control panel | ✅ | View / notify father (per Register R-3) | View-only if exposed | Tutor surfaces only | Serves content |
| Approve / reject `AiSuggestion` | ✅ required FatherSession | ⛔ direct execute | ⛔ | ⛔ | **No execute()** |
| Configure AI monitoring level per child | ✅ alone (doc 20) | ⛔ all levels | ⛔ | Transparency line | Flags server-side |
| Socratic tutor / stories / recitation | Oversees logs | May view | — | Uses | TutorRepository |
| Emit anonymized `FamilyEvent`s | Device emits | Device emits | — | Device emits | Consumes via gateway |

### 3.6 Child-only personalization

| Capability | Child | Others |
|---|:-:|---|
| Appearance / tools prefs (CHD-037 scope) | ✅ | Father does not micromanage cosmetics |
| Policy / limits / unlock blocked apps | ⛔ | Father only (balance never opens blocked) |

---

## 4. Owner-only screen classes (RoleGuard)

Per constitution Rule 8 + Register RoleGuard amendment:

| Class | Examples (IDs illustrative) | Who |
|---|---|---|
| Subscription / billing | FAT settings billing | Father OWNER |
| Privacy | Privacy center | Father OWNER |
| Audit log | Append-only audit UI | Father OWNER |
| AI brain control (level per child) | `SCR-FAT-029` | Father only (doc 20) |

Mother FULL still **cannot** take owner-only billing/privacy/audit/wipe.

---

## 5. Cross-role propagation rules (matrix companions)

Every mutating action must define the other side (phase 5 will expand). Minimum laws already sealed:

| When… | Then… |
|---|---|
| Father approves task | Child wallet updates **instantly**; Moments/thanks paths as designed |
| Mother ②/③ approves request | Same deposit path via PolicyEngine; audit shows actor |
| Father changes mother level | Mother notified; approval log append-only; downgrade double-confirm |
| Time expires | Entertainment locks; **chat / Quran / SOS stay up** |
| Advisor suggests | UI shows approve/reject; no silent apply |
| Child goes offline | Last-synced state; honest offline template |

---

## 6. Journey coverage vs actors (registry)

| Actor | Journey count (CSV) | Implication |
|---|---:|---|
| Father | 45 | Full transactional breadth |
| Mother | 9 | Consume / reassure / approve-within-level — **no rule-creation journeys without father** |
| Child | 18 | Pairing, day board, SOS, chat, earn, transparency |
| Shared | 1 | Auth / mode entry |

Absence of a “Mother app” in `screens.csv` is **consistent** with dual-mode + RoleGuard — not a missing primary actor.

---

## 7. CONFLICT-WITH-FROZEN / clarity items

| ID | Item | Notes |
|---|---|---|
| — | Schema has no `CHILD` in `member_role` | **Consistent** with A3 (child = `child` table). Not a conflict. |
| — | Guardian secondary | **Consistent** with CHECK + doc 20. |
| **CWF-001** | 129 vs 130 screens | **Resolved** (ADR-034) — 129 active + tombstone FAT-039. |
| ~~Mother FULL edges~~ | Instant lock / anti-tamper / block-unlock / level edit | **Resolved** (ADR-035) — encoded in §3.3–§3.4 above. |

---

## 8. Enforcement map (implementation preview — not coding now)

| Concern | Mechanism |
|---|---|
| Route access | `RoleGuard` in go_router only |
| Mother level | `PermissionMatrix.can(perm_key)` |
| Economy writes | `PolicyEngine` only |
| AI execution | Type system: no `execute()` on suggestions |
| Audit | Append-only repository API |
| Device role | Set at pairing — never self-declared |

---

**Checkpoint:** Phases 0–2 complete. No phase 3 (service catalog) until owner audit of this matrix + inventory conflicts.
