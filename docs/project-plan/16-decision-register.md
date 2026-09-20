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
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** The service/screen/journey registry still uses legacy points/XP vocabulary, which constitution **Rule 4** and Register **E-1** forbid.

**Owner ruling — LEGACY NAMING, NOT BEHAVIOR:**
- The frozen HTML has **ZERO** points/XP surfaces. `SCR-CHD-019` already renders **«محافظ تطبيقاتي»** (per-app wallets), repurposed under ق-٢ / Register **S-2**.
- **Do NOT edit** `_REGISTRY` CSVs (additive-only law).
- Discovery / implementation mapping (docs + code domain only):

| Registry ID | Legacy label | Binding meaning |
|---|---|---|
| `S-EDU-030` | نقاط | **Minutes-earning ledger** (wallet deposits via `PolicyEngine.earn()`) |
| `S-EDU-032` | استبدال النقاط بوقت شاشة | **`SUPERSEDED-BY-E-1`** — no exchange step; minutes *are* the currency |
| `S-EDU-033` | XP ومستويات | **Celebration badges / progress levels with NO exchange value** (never a currency) |

- Currency CI / Rule 4 hooks ban **CODE** (`points`/`coins`/`xp` in Dart), **not** historical CSV strings.
- Domain vocabulary everywhere in Flutter: **`Minutes` / `Duration` only**.

**Consequences:** Screen ports use minutes ARB copy matching the frozen HTML. Registry rows kept as historical labels. `S-EDU-032` is a no-op / documentation tombstone in the service catalog.

---

## ADR-037 — `S-EDU-036` “competitive divisions” vs no-leaderboard law
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** `S-EDU-036` «أقسام تنافسية» appeared to conflict with Register **G-8**.

**Owner ruling — REINTERPRET:**
- `S-EDU-036` = **cooperative family challenges**: one shared family goal; **each child’s own progress is celebrated**; **NO ranking / leaderboard** (G-8 wins).
- Remains **P2**, **post-v1**.

**Consequences:** No descending cross-child ranking may ship. UI shows personal progress + shared goal completion only.

---

## ADR-038 — Delegated agent (`S-AIC-030…034`) vs “AI never executes”
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** Auto-execution in `S-AIC-031` appeared to conflict with Rules 7 and 26, while Register **A-5** sanctions a father-built rules agent.

**Owner ruling — TWO SYSTEMS, NO CONFLICT:**
1. **A-5’s agent = deterministic father-authored if/then `RulesEngine`** (the father’s pre-written will) — **not** an `AiSuggestion`.
2. **Rule 26** governs **AI proposals only** (`AdvisorRepository` / `InsightsRepository` / `TutorRepository`).
3. **`S-AIC-031` auto-execution is ALLOWED** when all of the following hold:
   - (a) Rules authored by the **father only**
   - (b) Every action → `audit_log` **and** a visible action feed
   - (c) **10-minute undo** mandatory (`S-AIC-033`)
   - (d) **NEVER** performs ADR-035 owner-only actions (anti-tamper, unlock father-blocked apps, edit delegation level)
   - (e) Never mints minutes beyond father-defined rule amounts
   - (f) AI may only **SUGGEST** rules → father approves them into the RulesEngine
4. **Architecture:** `RulesEngine` lives **OUTSIDE** the three AI gateways.

**Consequences:** Architecture docs must show two paths: AI suggest→approve vs RulesEngine execute-under-authored-rule. Type system still forbids `AiSuggestion.execute()`.

---

## T-1 — School-mode services rebound off tombstone FAT-039
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-19)  
**Problem:** `S-SEC-058/059/060` were bound only to tombstoned `SCR-FAT-039`, while «وضع المدرسة» is still alive in the frozen HTML (exactly **5** string hits).

**Evidence (frozen HTML):**
| Location | Screen | Role |
|---|---|---|
| `smartModes.modes.school` + management UI | **`SCR-FAT-085`** الأوضاع الذكية | **Primary config host** (schedule, kids, allowed apps, activate) |
| Status card «وضع المدرسة نشط» | **`SCR-CHD-004`** لوحة يومي | Child-facing active status |
| Timeline stop «وضع المدرسة نشط» | **`SCR-FAT-063`** الخط الزمني للفرد | Parent insight timeline |
| Focus / school focus state | **`SCR-CHD-018`** (already lists `S-SEC-060`) | Focus state surface |
| State comment (`activeId` / day-board notes) | supporting | Prototype notes only |

**Binding (docs only — registry CSV not edited):**

| Service | Rebind hosts |
|---|---|
| `S-SEC-058` جدول وضع المدرسة | **`SCR-FAT-085`** (primary) · journey `JRN-FAT-20` |
| `S-SEC-059` التفعيل التلقائي بالموقع | **`SCR-FAT-085`** |
| `S-SEC-060` حالة Focus | **`SCR-CHD-018`** + status mirrors on **`SCR-CHD-004`** / **`SCR-FAT-063`** |

Tombstone `SCR-FAT-039` remains unroutable (ADR-034).

---

## ADR-035-b — Anti-tamper invisible in mother’s UI
**Status:** `RESOLVED-BY-OWNER-AUDIT` (2026-09-20)  
**Problem:** ADR-035 correctly makes anti-tamper **father-only**, but “non-editable” controls still leak owner capability into the mother’s UI if the surface is shown (disabled toggles, greyed rows). Phase 4 flagged this as `SET-OWNER-LEAK` / `SET-007`.

**Context:** Register **R-2** (mother = delegated agent), ADR-035 (anti-tamper OWNER-only even at FULL), constitution Rule 8 (RoleGuard), owner audit of Phase 4 settings.

**Decision:** Anti-tamper controls must be **INVISIBLE** in the mother’s UI at **every** delegation level (OBSERVER / PARTNER / FULL) — not merely non-editable. RoleGuard / UI composition **omits the surface**; the mother must not see anti-tamper rows, switches, or related affordances.

**Consequences:**
- `SET-007` / `SET-OWNER-LEAK` closure = **not rendered** for `member_role = PARENT` (and GUARDIAN), regardless of permission level.
- Instant lock remains allowed at Mother FULL (ADR-035) — that is a separate permission key (`INSTANT_LOCK`), not anti-tamper.
- Encoded in `03-role-permission-matrix.md` §3.4 / §5 and cross-role maps in `06-cross-role-dependencies.md`.

**Does not replace ADR-035** — lettered extension only. Next free numeric ADR remains **ADR-039**.

---

## Register hygiene
- Next free ADR ID: **ADR-039**.
- ADR-035-b is a lettered extension of ADR-035 (not a new numeric slot).
- Doc-drift items (CWF-002 "22 rules", CWF-003 stale counts in `README`/`START_HERE`) are **documentation hygiene**, not product decisions; they need an owner-approved doc commit because `handoff/` is outside discovery's write scope.
