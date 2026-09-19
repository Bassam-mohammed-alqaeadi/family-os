# 02 — Product Model
**Mission:** Discovery phase 2 (product understanding) · Branch `discovery/master-plan`  
**Date:** 2026-09-19 · **Authority:** Section A wins · Policy Register = supreme law  
**Status:** CHECKPOINT — awaiting owner audit before phase 3

---

## 1. Product in one paragraph

**Family OS («عائلتي»)** is an offline-first family digital-wellbeing operating system: **one Flutter app**, role-based experiences for parents and children. The father (owner) holds full sovereignty over rules, rewards, and AI approvals. The **only reward currency is minutes** (set by the father at task creation). Safety surfaces — **SOS, location, family chat** — are free forever and never gated by subscription or time expiry. AI (“**Family Advisor**”) suggests only; it never executes. UI is Arabic-first (RTL) with i18n from day one.

---

## 2. Value proposition (by primary actor)

| Actor | Core job-to-be-done |
|---|---|
| **Father (OWNER)** | See the family at a glance; set limits; approve work; grant minutes; stay reachable in emergencies; retain final say on every AI suggestion. |
| **Mother (PARENT)** | Participate within father-set trust level — see, reassure, communicate; optionally approve requests / edit rules when delegated. |
| **Child** | Know the rules transparently; earn minutes through real effort; chat/call family; call for help; never bypass father limits. |

Secondary:
| Actor | Core job |
|---|---|
| **Guardian** | Observe / reassure only — no transactional control. |
| **Family Advisor (SYSTEM)** | Propose insights and actions for father approval; tutor children Socratically; never generate Quran text or execute policy. |

---

## 3. Actor model (BINDING — Section A3 / schema CHECKs)

### 3.1 Primary (3)

| Product actor | Schema mapping | Permission posture |
|---|---|---|
| Father | `member.role = OWNER`, `permission_level = FULL` (CHECK) | Full sovereignty; one owner per family |
| Mother | `member.role = PARENT`, level OBSERVER \| PARTNER \| FULL set by father | Delegated; see `20_MOTHER_PERMISSIONS.md` |
| Child | **`child` table** (not `member_role`) + device `CHILD_LOCKED` / `CHILD_PREVIEW` | Locked triple-gate; parametric `ChildId`; display prefs only |

### 3.2 Secondary (2) — never promote to primary

| Product actor | Schema / system mapping | Rule |
|---|---|---|
| Guardian (e.g. grandfather) | `member.role = GUARDIAN` ⇒ **OBSERVER only** (CHECK `guardian_is_observer`) | Initiates **no** transactional use case |
| Family Advisor | `ai_suggestion` / `ai_event` + Rule 26 gateways | SYSTEM; `AiSuggestion` has **no** `execute()` — only approve/reject under FatherSession |

### 3.3 Entry paths (frozen)

| Who | How they enter |
|---|---|
| Father | Mode screen «وليّ الأمر» → creates family (becomes OWNER) |
| Mother | **Invitation from father only** (not onboarding role pick) |
| Guardian | Father invite — observer, non-upgradable |
| Child | Mode screen «ابني» → QR pairing |
| Advisor | Not a login — system surface (FAB ✨ / control panel) |

**Cancelled forever:** SCR-SHR-004 role picker, OTP, two-app model, green v1.

---

## 4. Product pillars (from Policy Register)

1. **Economy (highest sanctity)** — Minutes only; five earning channels via `PolicyEngine.earn()`; father sets reward at creation; mother’s tasks carry no minutes.
2. **Time engine** — Per-app wallets; blocked apps never open via balance; priority ladder ends with father’s instant lock.
3. **Sovereignty & safety** — Child cannot bypass; SOS always works; chat/Quran/SOS never locked by expiry; anti-tamper switches.
4. **Communication** — E2EE family chat; critical-alert check-ins; LiveKit metadata-only calls.
5. **Intelligence** — Advisor / Insights / Tutor repositories; server-side stage flags; on-device identity abstraction before events leave device.
6. **Platform** — Offline-first last-synced state; 129/130 screens (see CWF-001); Arabic human copy; additive fixes only.

---

## 5. Experience shells (prototype / architecture)

| Shell | Tabs / structure | Notes |
|---|---|---|
| Parent (FAT) | 5 tabs (اليوم، أبنائي، العائلة، …، الإعدادات) | Mother uses **same shell** under RoleGuard — not a separate app binary |
| Child (CHD) | 4 tabs | `child-ui` theme; parametric per `ChildId` |
| Shared (SHR) | Welcome, auth, mode | Auth = email/password only (ADR-003) |

---

## 6. Core product loops (summary — detail in later flow docs)

| Loop | Happy path | Constitutional constraint |
|---|---|---|
| Link child device | Father QR → child scan → transparency acknowledgment → first value (location) | Device knows role from linking |
| Earn minutes | Father creates task with minutes → child completes/proof → father ✓ → wallet deposit instant | No points/XP; `PolicyEngine.earn()` only |
| Time request | Child requests → parent approve (mother if PARTNER+) → minutes / grant rules | Mother OBSERVER cannot approve |
| SOS | Child long-press → pierce silent → parents + escalation ladder | Never gated by plan/network/time |
| AI suggestion | Advisor proposes → father approve/reject | No auto-execute |
| Invite mother | Father picks level → invite → mother joins at that level | Level changes audited; downgrade double-confirm |

---

## 7. What “done” means for the product (discovery framing)

A feature is complete only when (Rule 24 + Register):
- Setting binds → persists → enforced in `core/policy/`
- Principal action closes the loop (feedback + downstream effect on other roles)
- Full UI state range (empty/loading/one/many/error)
- Data behind Repository interfaces (Rule 25)
- Traceable to registry service + screen IDs

---

## 8. Out of scope for first implementation wave (frozen / deferred)

| Item | Status |
|---|---|
| Two-household / guardianship complexity | Schema reserve only (`guardianship` empty) — G3 |
| Real AI Gateway / inference | Mock Advisor first; Rule 26 seam |
| Real backend sync server | Mock repos; Project 2 per preflight D3 |
| Ownership transfer on death/divorce | `S-ADM-013` P1 / wave 2 — open future item in doc 20 |
| OTP / phone auth | Cancelled |

---

## 9. Open items requiring owner later (not re-deciding frozen law)

| ID | Topic | Why not decided here |
|---|---|---|
| CWF-001 | Seal 129 vs CSV 130 screens | Count authority |
| Preflight A1–A2 | Flutter/Dart pin + Arabic font | Owner pick before F0 |
| Preflight C1 | Bundle ID / display name | Store identity |
| Doc 20 future | Ownership transfer | Explicitly wave 2 |

No new product pillars invented. No secondary actor elevated.
