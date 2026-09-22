# PRD — Family OS («عائلتي»)
**Version:** 0.1 (discovery draft) · **Date:** 2026-09-19 · **Branch:** `discovery/master-plan`  
**Sources:** Frozen prototype v1.0 · Policy Register · Constitution (26 rules) · Discovery docs 01–04 · Decision register ADR-034…038  
**Status:** Draft for owner alignment — **not** an implementation green light. Open product decisions are listed in §7.4.

---

## 1. Summary

Family OS («عائلتي») is a family digital-wellbeing product: one Arabic-first app where the father sets the rules, children earn **minutes** (not points), and safety tools (SOS, location, family chat) always work. This PRD states who it is for, what must ship, how we measure success, and what is still blocked by open decisions.

---

## 2. Contacts

| Name | Role | Comment |
|---|---|---|
| Bassam Alqaeadi | Executive Director / Product Owner | Final decision on law, ADRs, and release gates |
| Cursor agent (discovery) | Discovery / analysis | Produces blueprint under constitution; does not invent product law |
| Future Flutter / backend agents | Implementation | Execute only against approved `docs/project-plan/` + handoff law |

---

## 3. Background

### Context
The product already has a **frozen** visual and behavioral source of truth: a single HTML prototype with **129 active screens** (plus one tombstone row for a deleted school-mode screen). Around it sit 240 registered services, 73 journeys, a 20-table database contract, and a Policy Register that is supreme law.

What is missing is not another design pass. What is missing is an **implementation-ready specification**: every setting must change real state, every action must close its loop across father / mother / child, and the app must stay ready for a real backend and AI gateway without rewriting screens.

### Why now
1. Design is sealed (ADR-030). Changing UI by taste is forbidden.
2. Constitution and hooks now enforce minutes-only, AI-suggests-only, and one-feature commits.
3. Discovery phases 0–3 mapped inventory, actors, permissions, and a spine of 12 end-to-end services. Three naming / sovereignty conflicts still need the owner before the education and delegated-agent batches can finish.

### What just became possible
A clear path from “beautiful prototype” to “shippable Flutter OS”: feature-first architecture, mock repositories today / API later with zero UI change, and AI as three gateways (Advisor, Insights, Tutor) with no on-device inference.

---

## 4. Objective

### Objective
Turn Family OS from a frozen prototype into a coherent production system where every screen has a purpose, every setting has an effect, every role has clear permissions, and every important action is complete across UI, state, policy, data, and the other family members who feel the change.

### Why it matters
Parents need control without turning the home into a points game or a surveillance trap. Children need honest rules, real rewards (minutes), and a way to call for help that never depends on a subscription. The company needs a product that can pass store review for family-safety apps and grow from mock data to a real backend without rewriting the UI.

### Alignment
- Father sovereignty and AI that only suggests (never acts alone on the device).
- Minutes as the only reward currency.
- Safety free forever: SOS, location, family chat.
- Offline-first, Arabic-first, one app for all roles.

### Key Results (SMART)

| KR | Measure | Target |
|---|---|---|
| KR1 — Spec completeness | Discovery phases 0–21 package + readiness verdict | Package complete; verdict ≠ READY FOR IMPLEMENTATION until open ADRs close |
| KR2 — Loop integrity | Spine services (pairing, time, earn, SOS, chat, audit) specified end-to-end | 12 spine specs done; remaining 228 batched; zero orphan services (already true) |
| KR3 — Law compliance | Minutes-only, RoleGuard, no AI execute in app | ADR-036/038 closed before EDU gamification and delegated-agent build |
| KR4 — Conversion quality | Screens ported from frozen HTML with ARB, tokens, tests, CONVERSION_LOG | Per constitution: one system/screen per task; green tests; loop closure |
| KR5 — Safety always on | SOS / chat / location usable with expired time and expired plan | Explicit PASS tests in release checklist |

---

## 5. Market Segment(s)

Markets are defined by **jobs**, not demographics alone.

| Segment | Job to be done | Constraints |
|---|---|---|
| **Father (owner)** | “Keep my children safe and balanced without fighting every night about screens.” | Needs final say; must trust that AI does not change rules behind his back |
| **Mother (delegated parent)** | “Stay close to my children’s day and help when my husband trusts me to.” | Level set by father (viewer / partner / full); never locked out of SOS, chat, or location |
| **Child** | “Know the rules, earn more time fairly, talk to my family, get help when scared.” | Cannot bypass father limits; must see what is monitored (no deception) |
| **Guardian (observer)** | “Know they are safe without running the house.” | Observer only; no transactional control |

**Geography / language:** Arabic UI first (RTL); English engineering docs and i18n keys.  
**Platform:** One Flutter app; Android capabilities may exceed iOS — honesty badges required where the OS limits us.  
**Business model constraint:** Safety features are never sold behind a paywall.

---

## 6. Value Proposition(s)

### Jobs we address
- Set and enforce screen time and app rules per child.
- Reward real effort with **minutes**, not fake coins.
- Stay reachable in emergencies (SOS that pierces silent mode).
- Talk as a family with encryption and without time-lock cutting chat.
- Get AI help that advises the father and tutors the child without giving away homework answers or inventing Quran text.

### Gains
- One place for the whole family (not two apps).
- Clear trust levels for the mother instead of “all or nothing.”
- Instant feedback when a parent approves a request (minutes appear on the child’s side).
- Works offline with an honest “last synced” state.

### Pains we remove
- Points/XP games that turn the home into a shop.
- Silent surveillance (child must see a transparency line).
- Safety tools that die when the trial ends.
- AI that changes settings without a parent tap.

### Better than typical competitors (value curve)
| Dimension | Typical parental-control apps | Family OS |
|---|---|---|
| Reward model | Points / coins / streaks as currency | **Minutes only** |
| AI | Auto-block or auto-punish | Suggest → father approves |
| Safety vs paywall | Often gated | SOS / location / chat **always free** |
| Mother role | Missing or same as admin | Three trust levels, father-set |
| Honesty to child | Often opaque | Transparency card + no deception |
| Language | English-first | Arabic-first RTL |

---

## 7. Solution

### 7.1 UX / prototypes
- **Source of truth:** `family-os/family_os_app.html` (Design v1.0 frozen). Port as-is: text, order, behavior.
- **Shells:** Parent (5 tabs) shared by father and mother via RoleGuard; Child (4 tabs); Shared (welcome / auth / mode).
- **Screen count:** **129 active** + 1 tombstone (`SCR-FAT-039`). Router must skip tombstones (ADR-034).
- **State range:** Every screen must support empty, loading, one item, many items, error — not only the prototype’s happy snapshot.
- **Flows (spine):** device pairing by QR · invite mother · daily cap / per-app wallet · time request · earn minutes · SOS · instant lock · family chat · risk alerts · audit log. Full specs live in `docs/project-plan/04-service-catalog.md` §4.

### 7.2 Key features

| Area | What ships | Non-negotiable rule |
|---|---|---|
| **Identity & roles** | Email+password account; father creates family; mother by invite; child by QR; guardian = observer | No role picker; no OTP |
| **Time engine** | Daily cap, per-app wallets, modes, instant lock | Blocked apps never open via balance; lock never kills chat/Quran/SOS |
| **Economy** | Tasks, Quran, learning, challenges, gifts → minutes | Only `PolicyEngine.earn()`; father sets reward at creation; mother’s tasks = help, not minutes |
| **Safety** | SOS, live location, geofences, escalation ladder | Works offline / expired time / expired plan |
| **Communication** | Family chat (E2EE), calls (LiveKit), safe contacts | Chat never locked |
| **Intelligence** | Family Advisor FAB, insights, Socratic tutor | Three repos only; no in-app inference; suggestions have no `execute()` |
| **Privacy & audit** | Audit log, AI control panel (father-only), child “what is collected about me” | Audit is append-only |

**Mother FULL (ADR-035):** may instant-lock (father can reverse). May **not** change anti-tamper, unlock a father-blocked app, or edit the delegation level. On conflict, father wins; everything is audited.

### 7.3 Technology (relevant constraints)
| Choice | Why |
|---|---|
| Flutter + Riverpod + Drift + go_router | One offline-first app; routes generated from registry |
| Feature-first folders | Traceability from audited systems |
| Repository interfaces + mock/ | Real backend later = zero UI change |
| ARB from day one | No hardcoded UI strings |
| Design tokens only | No raw colors in features |
| Hooks + CI | Constitution enforced locally and in PRs |

### 7.4 Assumptions and resolved decisions

**Assumptions (believed true; validate in later discovery phases)**
- The frozen HTML behavior is the intended product behavior unless Policy Register says otherwise.
- Mock family data in the prototype is sample rendering, not content (Rule 23).
- Schema grows by `ALTER`-style proposals only (no parallel schema).

**Resolved by owner audit (2026-09-19) — no longer blocking**

| ID | Ruling (short) |
|---|---|
| **ADR-036** | Registry “نقاط/XP” = **legacy labels only**. Frozen UI already uses minutes / per-app wallets (`SCR-CHD-019` = محافظ تطبيقاتي). Map: `S-EDU-030`→minutes ledger · `S-EDU-032`→`SUPERSEDED-BY-E-1` · `S-EDU-033`→celebration badges (no exchange). Currency CI bans **code**, not historical CSVs. Domain: `Minutes`/`Duration` only. |
| **ADR-037** | `S-EDU-036` = **cooperative** family challenges (shared goal, personal progress, **no ranking**). P2, post-v1. G-8 wins. |
| **ADR-038** | **Two systems:** AI suggestions (Rule 26, no `execute()`) vs father-authored deterministic **`RulesEngine`** (A-5). Auto-run allowed under six hard conditions (a–f); RulesEngine **outside** AI gateways. |
| **T-1** | School-mode services rebound: **`SCR-FAT-085`** (config) · status on **`SCR-CHD-004`** / **`SCR-FAT-063`** · focus **`SCR-CHD-018`**. Tombstone FAT-039 stays unroutable. |

**Still open for later phases (mechanical, not product-law)**
- Schema gaps for time policy, wallets/ledger, time requests/grants, tasks, lock state → Phase 10 `ALTER` proposals.
- Doc hygiene: START_HERE still says “22 rules” (CWF-002) — needs owner-approved handoff edit.
---

## 8. Release

### Relative timeframes (not calendar dates)
| Stage | Scope | Rough duration |
|---|---|---|
| **Now** | Finish discovery blueprint (phases 4–21) | Weeks of analysis, not coding |
| **Foundation** | Flutter pin, tokens, components, router, RoleGuard, PolicyEngine, mock repos + RulesEngine seam (F0–F2) | Slow and careful; must be correct |
| **Wave 1 conversion** | Critical pairing, day board, SOS, chat, core limits | Screens go faster once foundation is solid |
| **Later waves** | Education studio, advanced AI stages, social monitoring | After spine loops are green |
| **Project 2** | Real backend, E2EE transport, LiveKit, AI gateway | Separate effort; UI stays behind the same interfaces |

### First version (must include)
- Pairing + roles + mother levels (with ADR-035 edges).
- Time limits + request/approve loop that really deposits minutes.
- Earn-minutes path (no points in UI or code).
- SOS + family chat always available.
- Advisor suggestions with approve/reject only.
- Offline honest state + audit log.

### Later versions
- Full education studio depth.
- Delegated agent (only after ADR-038).
- Advanced social monitoring where OS allows.
- Ownership transfer / two-household (already deferred in law).

### Definition of “ready for implementation”
Use the discovery readiness model (NOT READY / READY FOR FOUNDATION / READY FOR IMPLEMENTATION).  
ADR-036/037/038 and T-1 are **closed**. Remaining blockers for READY FOR IMPLEMENTATION are unfinished discovery phases (settings audit through release checklist) and preflight owner actions (FVM pin, fonts, branch protection).

---

## Appendix — Document map

| Need | Where |
|---|---|
| Inventory | `docs/project-plan/01-project-understanding.md` |
| Product model | `docs/project-plan/02-product-model.md` |
| Role matrix | `docs/project-plan/03-role-permission-matrix.md` |
| Service catalog | `docs/project-plan/04-service-catalog.md` |
| Decisions | `docs/project-plan/16-decision-register.md` |
| Supreme law | `handoff/04_POLICY_REGISTER_EN.md` |
| UI ground truth | `family-os/family_os_app.html` |

---

*End of PRD v0.1. Next: continue discovery phase 4 (settings completeness audit). Owner actions remaining are preflight (handoff/10), not ADR-036/037/038.*
