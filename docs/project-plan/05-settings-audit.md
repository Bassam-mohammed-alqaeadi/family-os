# 05 — Settings Completeness Audit
**Mission:** Discovery phase 4 · Branch `discovery/master-plan`  
**Date:** 2026-09-19 · **Authority:** Section A · Rule 24 (every setting REAL) · Policy Register  
**Counting:** 129 active screens + 1 tombstone (ADR-034)

---

## 1. Method

For every visible setting (toggle, slider, choice, level picker, list editor) we ask the 14 questions from the Master Discovery Command:

1. Why does it exist?  
2. Who controls it?  
3. What does it control?  
4. Default?  
5. What happens when it changes?  
6. Where stored?  
7. Who is affected?  
8. Which screens react?  
9. Which backend/policy reacts?  
10. Which DB field?  
11. Permissions?  
12. Validation?  
13. Notifications?  
14. Cross-role effect?

**Evidence sources:** frozen HTML (`family_os_app.html`), `_REGISTRY/screens.csv`, Policy Register, ADR-035/036/038.

**Prototype honesty:** many toggles call only `this.classList.toggle('on')` — **visual only**. Some bind to in-memory `S.*` (webFilter, antiTamper, smartModes) — **partial**: state exists for the session, but there is no Drift/policy/child-device enforcement yet (Flutter not started). Both classes are gaps under Rule 24 until conversion closes them.

**Status codes used below:**

| Code | Meaning |
|---|---|
| `VISUAL` | Toggle flips CSS only — no `S.*`, no persistence |
| `SESSION` | Writes `S.*` in the HTML prototype; lost on reload; no policy engine |
| `LAW-BOUND` | Behavior fully specified by Register / ADR; ready to implement |
| `OWNER-ONLY` | Father OWNER only (RoleGuard / ADR-035) |
| `SUPERSEDED` | Registry label legacy; use minutes mapping (ADR-036) |
| `POST-V1` | Explicitly deferred (e.g. ADR-037 P2) |

---

## 2. Inventory of settings-bearing screens

**36** registry screens are settings-like (`نموذج` / `إعدادات` / tab الإعدادات / name contains إعداد|فلتر|قفل|…). Tombstone `SCR-FAT-039` excluded from active audit.

| Cluster | Active screens (IDs) | Focus |
|---|---|---|
| A · Identity & roles | SHR-002/003, FAT-001/002/003/008/027/031 | Account, invite, mother level |
| B · Time & apps | FAT-032/033/034/035/037, CHD-020 | Caps, wallets, lock, requests |
| C · Web & network | FAT-036, FAT-078 | Filter levels, router |
| D · Safety | FAT-028, FAT-038, CHD-005 | SOS ladder, anti-tamper |
| E · AI & privacy | FAT-029/059/060/067/068/079 | Brain panel, monitoring, audit |
| F · Notifications & billing | FAT-058/056/057 | Channels, quiet hours, plans |
| G · Modes | **FAT-085** (T-1 host), CHD-004/018 status | Smart modes incl. school |
| H · Child personal | CHD-011/037-ish prefs | Appearance only |

Full row-by-row audit for the **constitutional spine** is §3. Remaining screens are batched in §5 with the same checklist applied at cluster level (detail expandable in phase 7 UI audit).

---

## 3. Spine settings — full audit

### 3.1 `SCR-FAT-032` — وقت الشاشة لابن (daily / schedules / per-app)

| Setting | Why | Who | Controls | Default | On change | Store | Affected | React screens | Policy | DB | Perm | Validate | Notify | Cross-role |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Daily entertainment cap | Limit countable time | Father; Mother FULL | TimeEngine daily budget | Product TBD (must be required, not silent) | Recalc countdown | policy store | Child | CHD-004 countdown, lock overlay | `TimeEngine` + Ruling B | **Missing** (D-1) | rules+ | `Minutes` ≥ 0 | T-5 before end | Child sees new remaining |
| Sleep schedule | Bedtime calm | Father; Mother FULL | Night window | Prototype sample 9:30–6:30 | Enter bedtime screen | schedule | Child | CHD bedtime | Ruling / S-4 | D-1 | rules+ | End > start | Gentle notice | Child calm UI |
| Prayer pause | Soft pause | Father; Mother FULL | 15-min pause windows | On in prototype | Pause entertainment | schedule | Child | App grid | S-1 adjacent | D-1 | rules+ | — | Soft | Child pause |
| Study window | Focus block | Father; Mother FULL | Allowed study apps | Off in prototype | Restrict grid | schedule | Child | CHD-018 | Modes | D-1 | rules+ | — | — | Child |
| Per-app caps / countable flags | S-2 wallets | Father; Mother FULL | Per `appId` wallet + countable | Entertainment counted; Quran/edu/calls not | Wallet stream | wallet | Child | CHD-019 «محافظ تطبيقاتي» | Ruling A + S-1/S-2 | **Missing** (D-2) | rules+ | app exists | Per-app T-5 | Child wallets update |
| Education never counted | Governing `S-EDU-044` | System invariant | Countable=false for edu | Always | Cannot disable for protected classes | policy | Child | — | **LAW-BOUND** | policy flag | n/a | n/a | n/a | Child free edu time |

**Prototype status:** schedule toggles often `VISUAL` (`classList.toggle`); web/app cards mix `SESSION`.  
**Gaps:** `SET-001` visual sleep/prayer/study toggles · `SET-002` no DB for policy/wallets · `SET-003` child-side must reflect within same session after sync.

---

### 3.2 `SCR-FAT-036` — فلترة الإنترنت

| Setting | Why | Who | Controls | Default | On change | Store | Affected | React | Policy | DB | Perm | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Filter level (صارم/متوازن/مفتوح) | P-8 | Father; Mother FULL | Category strictness | balanced (prototype) | Rebuild block decisions | `S.webFilter.level` SESSION→Drift | Child | Block page | WebFilterPolicy | need `web_filter_policy` | rules+ | **SESSION** today |
| Banned-words dictionary | P-8 | Father; Mother FULL | Extra blocks | sample list | Immediate | dict array | Child | Block page | same | same | rules+ | **SESSION**; must persist |
| Category toggles (بالغين، قمار، غرباء، تسوق…) | P-8 | Father; Mother FULL | Category on/off | mix | Immediate | categories | Child | Block page | same | same | rules+ | Many rows **VISUAL** only |
| Force safe search | P-8 | Father; Mother FULL | Search engines | on | Immediate | flag | Child | Search | same | same | rules+ | |
| Block private browsing | P-8 | Father; Mother FULL | Incognito | on | Immediate | flag | Child | Browser | same | same | rules+ | |
| Manual allow/block lists | P-8 | Father; Mother FULL | Site exceptions | sample | Immediate | lists | Child | Block/allow | same | same | rules+ | Child unlock-request loop required |

**Gaps:** `SET-004` category rows that only toggle CSS · `SET-005` polite block page + father preview must be wired · `SET-006` child→father unlock request missing as first-class setting effect.

---

### 3.3 `SCR-FAT-037` + anti-tamper (often co-located / related `S-SEC-042…046`)

| Setting | Why | Who | Controls | Default | On change | Store | Affected | Policy | Perm | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| Instant lock / internet-only / timed | Ladder top | Father; **Mother FULL** (ADR-035) | Device lock | off | Overlay on child; audit | lock state **D-5 missing** | Child, Father (if mother acts) | TimeEngine short-circuit | INSTANT_LOCK | Exempt chat/Quran/SOS |
| Anti-tamper ×6 (noDelete, noClockChange, noVPN, simAlert, settingsPin, bypassAlert) | P-6 | **OWNER only** (ADR-035) | Device defenses | mix in prototype | Enable OS intents + alerts | `S.antiTamper` SESSION | Child device, Father alerts | P-6 | OWNER-ONLY | **SESSION** in HTML; mother FULL must not see editable controls |

**Gaps:** `SET-007` RoleGuard must hide anti-tamper from mother even at FULL · `SET-008` each switch needs a documented “what happens when enabled” line (Register already requires it) · `SET-009` conflict: mother lock vs father unlock → father wins + audit.

---

### 3.4 `SCR-FAT-058` — الإشعارات

| Setting | Why | Who | Controls | Default | Cross-role |
|---|---|---|---|---|---|
| Critical / SOS channel | P-4, C-4 | System + father prefs for non-critical | Pierce silent | Always on for SOS | **Cannot disable SOS** (Rule 9) |
| Child requests | Time/app requests | Father; Mother by level | Inbox noise | on | Mother ① still sees; approve only ②+ |
| Advisor alerts | AIC | Father; Mother notified (R-3 / `S-AIC-029`) | Urgency tiers | on | Mother informed, not controller |
| Quiet hours | Reduce noise | Father | Schedule | sample | Must **never** silence SOS/critical |
| Digest instead of spam | `S-ADM-029` | Father | Bundle | on | |
| Evening summary | Convenience | Father | 8:30pm sample | on | |

**Prototype:** several rows `VISUAL`.  
**Gaps:** `SET-010` quiet hours must hard-exclude critical channel · `SET-011` mother notification identity (R-3) not a father clone.

---

### 3.5 `SCR-FAT-059` — الخصوصية والبيانات

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| Location / messages / AI collection scopes | P-7, G | Father (privacy owner-only screens) | What is collected | Child transparency card must mirror (`S-ADM-035`) |
| Export / delete | Rights | OWNER | Data lifecycle | Wipe: double confirm + 7-day regret + audit |
| Forget button (`S-AIC-017`) | Advisor memory | Father | Advisor memory only | **Never** touches messages or audit log |
| Link to audit log | R10 | OWNER | Navigate FAT-060 | Append-only |

**Gaps:** `SET-012` child «ماذا يُجمع عني» must update when father flips collection switches · `SET-013` forget vs wipe are separate settings with separate confirmations.

---

### 3.6 `SCR-FAT-029` — لوحة تحكم العقل

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| AI stage flags (monitor→…→agent) | Charter stages | **Father only** (doc 20 / `S-ADM-033`) | Server feature flags | UI shows coming-soon for inactive stages (Rule 26) |
| Per-child monitoring scopes (screen, mood categories, places…) | P-7 | Father only | What Advisor may see | Child transparency required |
| Mother notification of analyses | `S-AIC-029` | System | Notify mother | Not a control for mother |

**Gaps:** `SET-014` stages are server flags, not local toggles that unlock inference in-app · `SET-015` mother cannot open brain control even at FULL.

---

### 3.7 `SCR-FAT-067` / `SCR-FAT-068` — رقابة ذكية / المنصات

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| Stranger / new-friend alerts | P-9 | Father; Mother FULL for rules | Contact policy | Approve friends one-by-one |
| Keyword / sentiment switches | P-7 | Father | Monitoring | Honesty badge; child knows |
| Per-platform (WhatsApp, Snap, IG, TikTok) | P-7 + G1 iOS honesty | Father | Platform monitors | **FAT-068** already states Android full / no false claims — must bind to `ios_reality.dart` |

**Gaps:** `SET-016` every platform toggle must read capability table (full / reports-only / unavailable) · `SET-017` disabled iOS claims must not look “on”.

---

### 3.8 `SCR-FAT-085` — الأوضاع الذكية (T-1 school-mode host)

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| Mode cards (sleep, school, study, Ramadan, exams, vacation, custom) | §3 M-A | Father; Mother FULL | Allowed apps + schedule + scope | School mode **lives here** (not FAT-039) |
| Activate / preview | M-D | Father (manual = instant) | Active mode | Grace 0–5 min default 2; manual skips grace |
| Per-mode kids scope | M-A | Father | Which children | |
| Exceptions (child×app×mode) | Ruling A | Father | Wallet exception? | Triple key |
| Conflict: stricter wins | M-B | System | Intersection | Father notified |

**Gaps:** `SET-018` registry still lists school services on tombstone — docs rebound to FAT-085 (T-1); conversion must not generate a route to FAT-039 · `SET-019` child CHD-004 status card must follow active mode stream.

---

### 3.9 `SCR-FAT-028` — إعداد الطوارئ

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| Escalation contacts | P-5 | Father | Backup after N seconds | Parents always step 1 (ungradeable) |
| Enable/disable contact | P-5 | Father | Ladder membership | **SESSION**/prototype `toggleEmergencyContact` |
| Delay seconds | P-5 | Father | Timing | |
| Location/call permissions per contact | P-5 | Father | What backup receives | |
| National emergency link | P-4/P-5 | Father | Last rung | |

**Gaps:** `SET-020` cannot remove parents from rung 1 · `SET-021` SOS receipt settings for mother/guardian must not exist (always receive).

---

### 3.10 `SCR-FAT-031` — مستوى صلاحية الأم

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| OBSERVER / PARTNER / FULL | R-2, doc 20 | **OWNER only** (ADR-035) | Mother PermissionMatrix | Default PARTNER; downgrade double-confirm; notify mother; audit |

**Gaps:** none in law — implementation must match ADR-035 exactly (`DELEGATION_EDIT` owner-only).

---

### 3.11 Economy-adjacent settings (FAT-045 / FAT-055 / CHD-019)

| Setting | Status | Binding |
|---|---|---|
| Reward amount on task create | **LAW-BOUND** E-2 | Required `Minutes`; no hidden default |
| Mother as assignee | **LAW-BOUND** E-4 | No minutes field |
| CHD-019 wallets UI | **LAW-BOUND** ADR-036 / S-2 | Minutes wallets — not points exchange |
| `S-EDU-032` exchange | **SUPERSEDED** | No setting ships |

---

### 3.12 `SCR-FAT-079` / RulesEngine (ADR-038)

| Setting | Why | Who | Controls | Notes |
|---|---|---|---|---|
| Father-authored if/then rules | A-5 | Father only | Deterministic automation | **Outside** AI gateways |
| Enable rule | A-5 | Father | Auto-run under (a–f) | Audit + feed + 10-min undo |
| AI-suggested rule draft | Rule 26 | Advisor suggests → father approves | Becomes RulesEngine rule only after approve | Never `AiSuggestion.execute()` |

**Gaps:** `SET-022` UI must separate “AI suggestions” from “My rules” · `SET-023` rule editor must block ADR-035 owner-only actions as consequents.

---

## 4. Cross-cutting defect classes

| ID | Class | Evidence | Impact | Resolution direction |
|---|---|---|---|---|
| **SET-VIS** | Cosmetic toggles | Widespread `classList.toggle('on')` without `S.*` | Rule 24 fail on conversion if ported literally | Every toggle → provider → repo → policy |
| **SET-SESSION** | In-memory only | `S.webFilter`, `S.antiTamper`, `S.smartModes` | Lost on restart; child device unaware | Drift tables (phase 10) + sync |
| **SET-ONE-SIDE** | Parent UI without child mirror | Filter/monitoring without transparency / block page | P-7 / P-8 violation | Pair every parent switch with child-visible effect |
| **SET-PAYWALL-RISK** | Subscription screens near safety | FAT-056 exists | Must never disable SOS/chat/location | RoleGuard + explicit non-gating tests |
| **SET-TOMBSTONE** | School mode on FAT-039 | Registry CSV | Dead config path | Use FAT-085 (T-1); skip tombstone in router |
| **SET-OWNER-LEAK** | Anti-tamper / delegation / brain if shown to mother FULL | HTML `can('rules')` vs ADR-035 | Sovereignty leak | Split `can('rules')` from owner-only keys |

---

## 5. Remaining settings screens — cluster checklist

Applied the same 14 questions at cluster level (expand to row-level in phase 7 if needed):

| Cluster | Screens | Completeness verdict | Top missing effect |
|---|---|---|---|
| Device health | FAT-025/026 | Intent repair paths specified in notes; not enforced | OS permission round-trip + health stream |
| Billing | FAT-056/057 | Owner-only; SOS never gated | Entitlement service must ignore safety modules |
| Language/help | FAT-061 | i18n + help links | ARB locale switch |
| Calendar/events | FAT-052/053 | Forms exist | Persist + notify members |
| Tasks | FAT-054/055 | Forms exist | Minutes path only (ADR-036) |
| Child lock/secret entry | CHD-011, FAT-030 | Dual-key parent mode | Attempt log (`mode_unlock_attempt` exists) |
| Coming soon | FAT-075 | Honest non-dates | Must not ship fake toggles |
| Router filter | FAT-078 | DNS guide amendment | Verify check after setup |

---

## 6. Explicit detections (phase-4 mandate)

| Detection | Finding |
|---|---|
| Visual but no behavior | Sleep/prayer/study toggles on FAT-032; several FAT-058 rows; many category rows on FAT-036 |
| Partial behavior | webFilter level/dict; antiTamper map; smartModes activate — session only |
| Affects one side only | Parent filter without guaranteed child block-page path in conversion plan |
| Unclear purpose | None in spine after ADR-036/037/038 — legacy names reinterpreted |
| Duplicates | School mode: tombstone FAT-039 vs live FAT-085 — **resolved by T-1** (do not implement both) |
| Contradictions | Points labels vs minutes — **resolved by ADR-036** (labels ignored in code) |
| Missing from correct role | Anti-tamper must not appear for mother FULL |
| Backend setting missing from UI | Wallet overflow flag (Ruling B) — needs explicit father switch (default off) — **flagged SET-024** |
| UI setting missing from backend | All SESSION settings above |
| Should be derived | Education countable=false — prefer derived invariant over manual father toggle where Register mandates |

---

## 7. Priority backlog for conversion (feeds GAP_LOG later)

| Priority | IDs | Why first |
|---|---|---|
| P0 | SET-007, SET-010, SET-015, SET-018, SET-020, SET-021 | Safety / sovereignty / tombstone |
| P0 | SET-001→003, SET-004→006 | Time + web are daily paths |
| P0 | SET-022, SET-023 | ADR-038 architecture seam |
| P1 | SET-008, SET-009, SET-011→014, SET-016, SET-017, SET-024 | Completeness + honesty |
| P2 | Cluster language/calendar polish | After spine |

Each conversion task that touches a settings screen must: bind → persist → enforce in `core/policy/` → close child/parent loop → append `GAP_LOG.md` if anything remains out of scope (Rule 24).

---

## 8. Phase 4 exit criteria

- [x] Settings-bearing screens inventoried (36 − 1 tombstone)
- [x] Spine settings audited against 14 questions
- [x] Visual / session / law-bound classes named
- [x] Cross-role and owner-only leaks flagged
- [x] ADR-036/037/038/T-1 applied (no open product blockers in this phase)
- [ ] Row-level audit for every remaining form control — deferred to phase 7 UI audit with the same codes

**Next:** Phase 5 — cross-role dependency maps.
