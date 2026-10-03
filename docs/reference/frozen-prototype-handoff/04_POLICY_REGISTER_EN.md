# Policy Register — English Engineering Digest (SUPREME LAW)
Faithful English digest of `family-os/40_POLICY_REGISTER_FOR_FLUTTER.md` (Arabic original remains authoritative for wording disputes). Every line is a signed owner decision or a sealed constitutional ruling. **No class or service may violate a clause here.** Changes require a new owner decision logged in `02_DECISION_LOG.md`.

## §1 — Rewards & Economy Constitution (highest sanctity ⚖️)
| # | Policy | Flutter impact |
|---|---|---|
| E-1 | The ONLY currency app-wide is **minutes**. No points, no XP, no virtual coins — ever. | No `Points` class exists in the domain. `RewardService` deals in `Duration`/`Minutes` only. |
| E-2 | **The father sets the minute amount at creation** of a task/challenge/Quran assignment — no system-imposed defaults. | `rewardMinutes` is a required field on creation models, filled by the father. |
| E-3 | **The five earning channels are constitutionally protected** — changes may only be additive: (1) Quran daily portion FAT-072⇄CHD-025 (2) Athkar CHD-027 (3) learning challenges FAT-049⇄CHD-015 (4) family tasks FAT-054/055 — children only (5) conditional app unlocking. | A permanent CI integration test walks all five loops: create → complete → approve → wallet deposit. |
| E-4 | **Mother's tasks carry NO minutes** (decision A, doc 39): assigning a task to Nawal = "help request 🤝" + thanks in Moments. Minutes are exclusively the children's currency — protecting the marital relationship from commodification. | `TaskAssignee.mother` is a separate path that never passes through `RewardService`. |
| E-5 | **Instant approval**: father reviews proof, taps ✓ → minutes deposit **instantly** into the child's wallet and reflect on the child's home screen at approval moment. | `TaskApproved` event → `WalletService.deposit()` → immediate push to child device. |

## §2 — Time Engine Constitution (rulings A/B/C/D — doc 33, sealed)
| Ruling | Binding text | Code impact |
|---|---|---|
| **A** | Earned balance opens **only what exhausted its daily limit** — **it NEVER opens blocked apps**. During an active mode, balance works **only with an explicit father exception** (child × app × mode, with a "deduct from wallet?" option). | `TimeEngine.canUse(app)`: `blocked → false` always, regardless of balance. `ModeExceptions` is a triple-keyed table. |
| **B** | Wallet minutes count within **the total daily cap by default** + a father switch "allow exceeding cap with earned balance" (**off by default**). | `dailyCapIncludesWallet = true` default; `allowWalletOverflow` flag per child. |
| **C** | A manual grant intersecting a scheduled mode → **immediate warning to the father at grant time**, and in that same dialog two buttons pre-decide its fate: "complete the grant to its end" / "freeze it when the mode starts (remainder returns after)". Case-by-case decision, no hidden rule. | `GrantConflictDialog` is mandatory before saving an intersecting grant; `grant.onModeStart: complete|freeze` is stored with the grant. |
| **D** | **The more specific individual setting overrides the shared one** — and the shared-settings screen lists "active individual exceptions". | Resolution order: `perChild > shared > default`; shared UI queries and displays exceptions. |
| Priority ladder | **Father's instant lock above everything** → then permanent block → then active mode (with its exceptions) → then daily limit → then earned balance. | `TimeEngine.resolve()` is a chain of responsibility in this literal order — instant lock short-circuits. |

## §3 — Smart Modes (rulings M-A/B/C/D — doc 34, ADR-028)
| Ruling | Binding text | Code impact |
|---|---|---|
| M-A | **6 ready modes + custom**: Sleep, School, Study, Ramadan, Exams, Vacation + "create your own". | `FamilyMode` entity with the six-property structure below. |
| Mode structure | Six properties: (1) identity name+icon (2) scheduling: weekly / manual-only / seasonal between two dates (3) scope: all children or selected (4) allowed apps — **and what is allowed remains governed by its remaining time** (5) special exceptions (ruling A) (6) entry behavior (grace period). | Each property is a model field; #4 passes through `TimeEngine`, never bypasses it. |
| M-B | Two modes conflicting on one child: **the stricter wins + father is notified**. | `ModeConflictResolver`: intersect allowed lists (narrowest) + notification. |
| M-C | Active mode shows a **top card + app-grid tinting** on the child device. | `activeMode` state streams to child UI and re-tints the grid. |
| M-D | **Gentle-finish grace before activation: 2 minutes default (0–5, father-set)** — child notified "to finish what's in hand". **Father's manual activation is ALWAYS instant** (standing owner directive). | `mode.grace: 0..5 min`; manual activation skips grace (or father chooses in the moment). |
| Lock above modes | Instant lock overrides any active mode, always. | Same ladder as §2. |

## §4 — Protection & Safety (hard constraints)
| # | Policy | Code impact |
|---|---|---|
| P-1 | **The child can never bypass father limits** — neither via UI nor backend. | All availability decisions resolve in a local policy layer on the child device, signed by the father device; child UI is display-only. |
| P-2 | **Balance exhausted ⇒ automatic lock** of countable apps. | `TimeEngine` countdown fires `LockOverlay` at zero. |
| P-3 | **A father-blocked app is hard-locked** until the father himself reopens it — balance never opens it (ruling A). | `blockedApps` readable only by `FatherSession`. |
| P-4 | **SOS works under ALL conditions**: no internet, time expired, subscription expired — 3-second press → location+audio broadcast → **siren that pierces silent mode** on father & mother + live map. | SOS channel sits outside every lock/subscription gate; critical-alert notifications bypass DND (special iOS/Android permissions). |
| P-5 | Emergency escalation ladder: parents unresponsive → backup contact after father-set seconds (e.g., uncle after 60s → national emergency). Enable/disable and delays are father-controlled. | `EscalationLadder`, ordered, with configurable delays. |
| P-6 | **Anti-tamper — 6 switches**: uninstall prevention · clock-change prevention · VPN detection · SIM-change alert · settings PIN · bypass-attempt alert — each with a "what happens when enabled" line. | `antiTamper{noDelete,noClockChange,noVPN,simAlert,settingsPin,bypassAlert}` — Device Admin / Screen Time APIs. |
| P-7 | **Smart monitoring WITH the child's knowledge — "protection without deception"**: search analysis / image classification / screenshots via father-set switches + app picker + on detection: save snapshot & report to father — **with a permanent transparency card on the child device**. | No silent surveillance; child screen shows current monitoring state. |
| P-8 | Web filtering: **3 levels** (strict/balanced/open) + extendable banned-words dictionary + manual block/allow lists + **a polite block page** the child sees (father gets a "how the child sees it" preview) + a child→father "request site unlock" loop. | `WebFilterPolicy` with levels & lists; local DNS/VPN. |
| P-9 | **Strangers are always blocked**: all external contact passes parental approval — trusted-relatives circle with contact schedules, friends approved by the father one by one. | `ContactPolicy`: whitelist-only; nothing received from outside it. |
| P-10 | Driving mode: vehicle-motion detection → teen phone secured + speed/distraction report — **honestly labeled "Android first, iPhone per Apple permissions"**. | Activity Recognition API; iOS limits documented explicitly in UI. |

## §5 — Family Communication
| # | Policy | Code impact |
|---|---|---|
| C-1 | **Family chat is an untouchable right**: never locked — even at time expiry or under lock mode. | `FamilyChat` fully exempt from `TimeEngine`. |
| C-2 | **Full end-to-end encryption**, servers cannot read — and it is user-visible ("E2E encrypted" in UI). | E2EE (Signal protocol or equivalent); server relays ciphertext only. |
| C-3 | Message editing within **15 minutes** + delete-for-all. | `editableUntil = sentAt + 15min`. |
| C-4 | **Check-in calls ring even on silent** + one-tap answer. | Same critical-alert channel as P-4; single answer button. |
| C-5 | Calls via **LiveKit — metadata only, no recording**. | No call media storage; metadata only for the log. |
| C-6 | Media stays **inside the trusted family circle** — no external leaks + voice notes arrive **auto-transcribed**. | Share-blocking at API level; local/private transcription service. |
| C-7 | Child calling opens **the native phone contacts** (decision B, doc 39) with an "approved family contacts first" banner. | OS intent + approved-first ordering. |

## §6 — Roles & Permissions
| # | Policy | Code impact |
|---|---|---|
| R-1 | **The father (owner) controls all settings** — full sovereignty; every feature assumes the final decision is his. | `Role.fatherOwner` full permission; every decision point routes to him. |
| R-2 | **The mother is a delegated agent with levels** (doc 20): father-set (view-only / partial "rules" editing / full) — screens honor `can()`. | `PermissionMatrix` for mother; UI auto-degrades to view-only. |
| R-3 | Mother's notifications carry **her dashboard identity** and her suggestions go to the father for approval. | Suggest→approve channel; no direct mother execution beyond delegation. |
| R-4 | **Role is determined exclusively by device linking** — the old role-picker screen was permanently deleted (it was a security hole). | Device knows its role from registration (QR / 8-digit code) — no role picker. |
| R-5 | The child customizes only personal appearance/tools (CHD-037) — never touches policy. | Child write scope: display preferences only. |

## §7 — AI ("Family Advisor")
| # | Policy | Code impact |
|---|---|---|
| A-1 | Official app-wide name: **"Family Advisor"** — accessed via the **floating ✨ button only** (no scattered icons). | One naming constant; one FAB opens gateway FAT-074. |
| A-2 | **The smart tutor is Socratic**: explains stepwise with hints and **categorically refuses to give the direct answer** — age-appropriate language, warm tone. | Fixed system prompt with this constraint + a ready-answer refusal layer. |
| A-3 | Child↔tutor conversations are **logged and visible to the father — and the child knows**. | Conversation log in father dashboard + transparency line on child side. |
| A-4 | Recitation corrector: **licensed Madinah Mushaf exclusively** — generating any Quran text/interpretation not matching the authenticated source is absolutely forbidden + gentle correction. | Quran text from a fixed licensed source — the LLM never generates verses. |
| A-5 | Father's delegated assistant: father-built "if/then" rules + **a log of everything it did**. | Rules engine + visible audit log. |
| A-6 | Peer comparison is **fully anonymous**: general age averages — no names, no families; "your data never leaves". | Anonymized statistical aggregation only. |
| A-7 | Interactive stories: moral decisions for the child + **a warm educational moral at the end** — from a vetted values library. | Pre-approved paths; no free generation for children. |

## §8 — Screen Time & Definitions
| # | Policy | Code impact |
|---|---|---|
| S-1 | **"Screen time" = entertainment only**: Quran / educational / family calls **do not count** toward the daily limit — each app has a countable switch the father can flip. | `screenTimePolicy.countable{appId: bool}` — defaults: entertainment=counted; Quran/education/calls=not. |
| S-2 | **Every app on the child device has its own time wallet.** | A `Wallet` per `appId` — not one global wallet. |
| S-3 | **Countdown notification 5 minutes before time ends** — gentle, so the child finishes what's in hand. | Scheduled `T-5min` notification + progress bar. |
| S-4 | Night-time expiry → **calm bedtime screen** (not a punitive lock). | `BedtimeScreen`, gentle character. |
| S-5 | Focus sessions: **two channels** — father-scheduled sessions (time + closed apps + child) AND the child's self-discipline channel with automatic reward (**rewardSelfDiscipline is untouchable**). | Two separate entities in `FocusService`. |
| S-6 | Juz' Amma **automatic gift with notification**: father taps a surah → arrives at the child as text + recitation with a gift notification. | `QuranGift` pipeline. |

## §9 — General Platform Principles
| # | Policy | Code impact |
|---|---|---|
| G-1 | **Offline-first**: works with the last synced family state, updates on connection — always showing "last synced". | Local-first DB (Drift) + sync engine + sync indicator in UI. |
| G-2 | Official screen count: **129** (FAT-039 permanently deleted). | Navigation map matches `_REGISTRY`. |
| G-3 | UI language is **human, not programmer IDs** — full Arabic RTL. | All texts from reviewed Arabic i18n; no IDs in UI. |
| G-4 | **Fixes are always additive** — never remove an existing feature, never reopen a frozen decision (OTP cancelled, green v1 cancelled, two-app model cancelled, role-picker deleted). | Code review blocks regressions on cancelled items. |
| G-5 | Each child's tools are **cards inside their profile** (PERCHILD) — no global settings screens mixing children. | Navigation: child profile → tool cards. |
| G-6 | Event-driven screens (network error SHR-005, empty SHR-006, alert FAT-018, incoming call CHD-006/008) are **invoked by events, not navigation**. | Event routes via notification/deep-link. |
| G-7 | Reports are settings-aware and built from real data. | Preferences-aware weekly report generator. |
| G-8 | Family challenges have **no demotivating leaderboard** — "no ranking that embarrasses anyone". | No descending leaderboards; celebrate each child's progress. |
| G-9 | Deleted icons ≠ deleted screens: some screens are reached via alerts only. | Reachability via notifications covered by tests. |

## §10 — Reference Mock Family (official simulation data)
| Member | Role | Notes |
|---|---|---|
| Abdullah | Father — owner | Final decision always his |
| Nawal | Mother — delegated agent | Delegation level set by father |
| Khaled, 14 | Child k1 🦁 | Al-Noor high school |
| Noura, 11 | Child k2 🐱 | |
| Saad, 8 | Child k3 🐼 | |
| Grandpa Salem, Aunt Mona | Trusted relatives circle | Contact schedules |
| Fahd Al-Tamimi, Omar Abdulrahman | Approved friends (Khaled) | Father-approved individually |

## Amendments (2026-09-18, stations M8/M9 + ADR-031)
- **Permanent-wipe flow**: mandatory double confirmation (two consecutive sheets) + **7-day regret window** before execution + automatic audit-log entry. The "Forget button" (advisor-memory wipe) is separate and never touches messages or the audit log.
- **Dinner-question feature**: Family Advisor suggests discussion questions, sendable to family chat — never imposed.
- **Router setup**: interactive 3-step DNS guide + automatic verification check.
- **RoleGuard pattern**: subscription/billing/privacy/audit screens guarded centrally (owner only).
- **Offline template**: "work offline" shows last saved state and promises auto-sync — honest wording, never fakes connectivity.
- **Call-tools symmetry**: every child-side communication control (mute/speaker/camera/send) has a father-side mirror with identical actions.
- **Structural laws for Flutter (ADR-031)**: `Minutes` type instead of raw int; central `RoleGuard`; audit repo without update/delete; parametric contract (every child screen is a function of `ChildId`); all UI strings from ARB.

## Amendments (2026-09-18, logged owner decision — constitution rules 23–24)
- **RULE 23 — DATA DYNAMISM LAW**: Every value in the frozen prototype is a SAMPLE RENDERING, never content. Displayed values bind to state/providers/repositories — zero hardcoded display data in widgets. Every screen renders full state range (empty, loading, one, many, error). Prototype notifications define TYPES and appearance and must be emitted by a real event pipeline. Mock family (Register §10) lives exclusively in `mock/` behind the same Repository interfaces; deleting `mock/` must leave the app compiling and functional. CI/review flags widget literals mirroring prototype sample values.
- **RULE 24 — GAP-CLOSING MANDATE**: Every setting must be REAL (bind, persist, enforce via `core/policy/`). Every principal action must close its loop (visible feedback + real downstream effect). Incomplete settings, dead-ends, and unclosed circles go into `GAP_LOG.md` (close in-task if in scope and Policy Register–consistent; else `QUESTIONS.md`). Closures are additive only — complete frozen behavior, never remove or alter it; follow design tokens and the Policy Register (supreme law).

## Amendments (2026-09-18, logged owner decision — constitution rule 25)
- **RULE 25 — BACKEND-READINESS LAW (zero-UI-change integration)**: The UI must never know where data comes from. Widgets consume providers; providers consume Repository interfaces only — no network, DB, or JSON parsing in `features/` or `app/`. Repository interfaces live in each feature's `domain/`; `mock/` and `api/` share the same contract and swap via DI in one composition root. Every feature documents its contract in `API_CONTRACT.md` (models from `_CONTRACTS/schema.sql`, errors, sync/offline per Register §G-1). Models are freezed/immutable with json serialization ready under mocks. Repos return domain types (`Minutes`, `ChildId`…) never maps/dynamic. Permanent acceptance: swapping `mock/` for the real API = zero lines changed in `features/` and `app/`; CI compiles with a fake alternative implementation to prove the seam.

## Amendments (2026-09-18, logged owner decision — constitution rule 26)
- **RULE 26 — AI INTEGRATION LAW (the Brain is a backend service; the app is hooks)**: No inference runs inside the app. All AI features flow through exactly three repository gateways — `AdvisorRepository`, `InsightsRepository`, `TutorRepository` — same seam as rule 25 (mock now, AI Gateway later, zero UI change). Features emit typed `FamilyEvent`s to a local EventBus drained by the sync queue; identity abstraction is applied on device before any event leaves. The charter's five stages are server-side feature flags, not app versions; inactive stages render their designed coming-soon/inactive UI. Sovereignty is structural: `AiSuggestion` has no `execute()` — only `approve()` (FatherSession required) and `reject()`. Socratic refusal is part of the repository contract; Quran text comes only from the licensed source; child↔tutor conversations are logged to the father with a child-visible transparency line. Mock `AdvisorRepository` reproduces the frozen prototype's suggestions/insights so all 19 AI screens are built and tested before any real model exists.
