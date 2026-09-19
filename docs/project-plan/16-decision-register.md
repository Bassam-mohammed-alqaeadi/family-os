# 16 — Decision Register
**Mission:** Discovery (phase 14 artifact, opened early to capture owner rulings)  
**Branch:** `discovery/master-plan` · **Numbering:** continues repo ADR series (last sealed: ADR-033)  
**Rule:** Frozen decisions are inputs. Conflicts are flagged `CONFLICT-WITH-FROZEN`, never re-decided by the agent.

| Status value | Meaning |
|---|---|
| `RESOLVED-BY-OWNER-AUDIT` | Owner adjudicated with evidence; binding |
| `REQUIRES PRODUCT DECISION` | Agent cannot resolve safely from project evidence |
| `PROPOSED` | Agent recommendation awaiting owner |

---

## ADR-034 — Screen count: 129 active + 1 tombstone
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** `_REGISTRY/screens.csv` contains 130 rows while the sealed count (Register §G-2, constitution Rule 3, `00_START_HERE`) is 129 — logged during discovery as CWF-001.

**Context / evidence:**
- `SCR-FAT-039` («وضع المدرسة») is a **tombstone row**; its `name` field carries `[محذوفة نهائيًا بقرار أد-١٢ + ق-١٢ في 37]`.
- Register **§G-2**: "Official screen count: 129 (FAT-039 permanently deleted)."
- Verified during discovery: FAT-039 is the **only** tombstone row in the registry.
- `SCR-FAT-086` (لحظات عائلتنا) is legitimate — present in the frozen prototype, bound to `JRN-FAT-45` (wave 1), services `S-AIC-019; S-EDU-030; S-COM-016`.

**Options considered:** (a) reseal count at 130; (b) delete the tombstone row; (c) keep registry as-is and adopt an explicit counting convention.

**Selected:** (c). Active screens = 130 rows − 1 tombstone = **129**. Sealed count **stands**.

**Consequences:**
- `screens.csv` is **not edited** (additive-only law, Register §G-4).
- All discovery documents state counts as **“129 active + 1 tombstone (FAT-039)”**.
- Parent-app split reconciles exactly: 86 FAT rows − 1 tombstone = **85 active FAT** / 37 CHD / 7 SHR.
- Future router generation must **skip tombstoned rows**; a registry-validation check should assert "tombstone rows are never routed".

---

## ADR-035 — Mother FULL delegation: edge-case boundaries
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** `20_MOTHER_PERMISSIONS.md` grants FULL the right to edit rules, limits, and safe zones, but is silent on instant lock, anti-tamper, unlocking father-blocked apps, and editing the delegation level itself.

**Context:** Register **R-2** (mother = delegated agent with levels), **R-3** (her suggestions route to father), **E-4** (mother's tasks carry no minutes), **P-3** (father-blocked app stays hard-locked until the father himself reopens it), doc 20 ("gradation in authority, never in reassurance").

**Decision:**

| Capability | At Mother FULL |
|---|---|
| Instant lock (device / apps) | **ALLOWED** — protective action; father can reverse |
| Anti-tamper switches | **FATHER-ONLY (OWNER)** |
| Unlock a father-blocked app | **FATHER-ONLY (OWNER)** |
| Edit the delegation level itself | **FATHER-ONLY (OWNER)** |
| Simultaneous conflicting action | **Father always wins** |
| All of the above | **Everything writes to `audit_log`** |

**Consequences:**
- `PermissionMatrix` needs explicit permission keys for `INSTANT_LOCK`, `ANTI_TAMPER`, `BLOCK_OVERRIDE`, `DELEGATION_EDIT` — the first allowed at FULL, the rest owner-gated.
- Conflict resolution needs a deterministic precedence rule (owner action supersedes concurrent parent action) plus an audit entry describing the superseded action.
- Consistent with P-3: balance never opens a blocked app, and now neither does delegation.
- Encoded in `03-role-permission-matrix.md` §3.3–§3.4.

---

## ADR-036 — Registry names “points / XP” while law says minutes only
**Status:** `REQUIRES PRODUCT DECISION`  
**Problem:** The service/screen/journey registry still uses legacy points/XP vocabulary, which constitution **Rule 4** and Register **E-1** forbid ("no points, no XP, no virtual coins — ever").

**Evidence (found in phase 3):**

| Artifact | ID | Legacy name |
|---|---|---|
| Service | `S-EDU-030` | نقاط (points) |
| Service | `S-EDU-032` | استبدال النقاط بوقت شاشة (exchange points for screen time) |
| Service | `S-EDU-033` | XP ومستويات (XP and levels) |
| Screen | `SCR-CHD-019` | نقاطي وشاراتي — "نقاط + شارات + مستويات + استبدال بوقت" |
| Screen | `SCR-CHD-004` | note: "وقتي ونقاطي" |
| Screen | `SCR-CHD-012` | note: "موادي + XP + سلسلة الأيام" |
| Screen | `SCR-FAT-045` | note: "مكافأة نقاط/وقت" |
| Screen | `SCR-FAT-055` | note: "مكافأة نقاط أو وقت" |
| Journey | `JRN-CHD-07` | goal: "كسب نقاطًا" |
| Journey | `JRN-CHD-10` | goal: "استبدل نقاطًا بوقت لعب" |

**Why it matters:** Register is supreme, so the *behavior* is already settled (minutes only, no exchange step). The open question is **naming/semantics of these registry entries**, which affects screen titles, ARB keys, and whether `S-EDU-032` (exchange) and `S-EDU-033` (XP/levels) survive at all.

**Options (not selected — owner call):**
1. **Reinterpret** — treat these as minutes-domain services: `S-EDU-030` = minutes wallet, `S-EDU-032` = **void** (no exchange needed, minutes are already the currency), `S-EDU-033` = progress levels **without XP currency**; rename UI copy to minutes language.
2. **Retire** — mark `S-EDU-030/032/033` as superseded by minutes services; add replacement IDs additively.
3. **Registry amendment** — owner-logged rename inside `_REGISTRY` (touches a LAW file; needs explicit authorization).

**Agent recommendation:** Option 1 for behavior + Option 3 for naming hygiene, as one logged owner decision — because leaving "نقاط/XP" in the registry will collide with the `check_hardcoded_strings` / currency CI checks and the Rule 4 hook tripwire on every related screen.

**Blocked:** Phase 3 full specs for `S-EDU-030/032/033` and the CHD-019 screen family.

---

## ADR-037 — `S-EDU-036` “competitive divisions” vs no-leaderboard law
**Status:** `REQUIRES PRODUCT DECISION`  
**Problem:** `S-EDU-036` «أقسام تنافسية» (competitive divisions/leagues, P2, wave 3) conflicts with Register **G-8**: family challenges have no demotivating leaderboard, "no ranking that embarrasses anyone".

**Options (not selected):**
1. Retire `S-EDU-036`.
2. Redefine as **non-ranking** cohorts (e.g. personal-progress tiers visible only to the child and parents).
3. Keep as-is → would require amending G-8 (supreme law) — not recommended.

**Agent recommendation:** Option 2 if the owner wants to keep the motivational idea; otherwise Option 1. Either way, no descending cross-child ranking may ship.

**Blocked:** Phase 3 spec for `S-EDU-036`; phase 13 gap classification for the gamification subsystem.

---

## ADR-038 — Delegated agent (`S-AIC-030…034`) vs “AI never executes”
**Status:** `REQUIRES PRODUCT DECISION`  
**Problem:** The AIC subsystem و «الوكيل المفوَّض» contains `S-AIC-031` **التنفيذ التلقائي ضمن التفويض** (automatic execution within delegation) and `S-AIC-033` **زر التراجع خلال ١٠ دقائق** (10-minute undo). Constitution **Rule 7** ("all intelligence suggests, never executes — every AI action ends with a parent-approval button") and **Rule 26** ("`AiSuggestion` has NO `execute()` method") appear to forbid exactly that, while Register **A-5** explicitly sanctions a father-built if/then rules agent with a log of everything it did, and the AI charter lists *delegated agent* as stage 5.

**Context:** All three sources are sealed law. The tension is about **where consent lives in time**: pre-authorized rule vs per-action button.

**Options (not selected):**
1. **Pre-approval reading** — the father's authored rule *is* the approval; execution occurs **server-side** under that rule; the app still has no `execute()` path, and every action is logged + undoable for 10 minutes. (Preserves Rule 26's type-level guarantee.)
2. **Strict reading** — the delegated agent only ever *queues* actions and each still needs a tap; `S-AIC-031` is downgraded to "auto-prepare, manual confirm".
3. **Amend Rule 7** to carve out father-authored rules explicitly (touches highest-sanctity sovereignty law).

**Agent recommendation:** Option 1 **if and only if** the owner confirms that a father-authored rule counts as prior approval, with three hard conditions: execution never happens app-side, every action writes to `audit_log` (`S-AIC-034`), and the 10-minute undo is guaranteed offline as well. Otherwise Option 2. The agent will not assume which reading is intended, because Rule 7 and Rule 26 are in the highest-sanctity tier.

**Blocked:** Phase 3 batch B7 (5 services), phase 8 AI architecture section, phase 13 severity ranking for the delegated-agent subsystem.

---

## Register hygiene
- Next free ADR ID: **ADR-039**.
- Doc-drift items (CWF-002 "22 rules", CWF-003 stale 71/128 counts in `README`/`START_HERE`) are **documentation hygiene**, not product decisions; they need an owner-approved doc commit because `handoff/` is outside discovery's write scope.
