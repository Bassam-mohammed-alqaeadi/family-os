# 04 — FS-007 AI Policy and Human Authority Discovery

**Mode:** Evidence of authority boundaries — **not** L2 freeze.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Frozen sovereignty laws (must not be weakened by FS-007)

| Law | Source | Implication for FS-007 |
|---|---|---|
| AI suggests, never executes | Constitution R7 · Register RULE 26 | Classification ≠ auto policy |
| `AiSuggestion` has **no `execute()`** | RULE 26 · ADR-038 | Approve / reject only |
| Father (owner) final decision | R-1 | Parent confirmation path required for policy effects |
| Mother suggest→father | R-3 | Mother may see/notify; not silent execute |
| Child never authors policy | R-5 | Child may get transparency, not admin |
| RulesEngine ≠ AI | ADR-038 | Deterministic father rules may auto-run under authored conditions; AI may not |
| SOS never AI-gated / AI-fired | P-4 · SOS Final | No autonomous emergency actions |
| No silent surveillance | P-7 | Child knowledge mandatory for monitoring tools |

---

## 2. What “authority” means for classifications

Discovery stance (not law):

| Artifact | Authority level |
|---|---|
| Raw classifier output | **Signal / fact** with confidence + provenance |
| Parent review decision | **Human authority** |
| Policy Kernel interpretation | Only if **explicit contract** maps signal → action |
| Web Filter / App Control stores | Remain **human-authored** (or mode-tighten under FS-005 L2) — AI may **suggest**, not silently rewrite |
| SOS ladder | Human / frozen SOS contract only |

**Never claim:** “AI protected the child” merely because a local classifier returned a value.

---

## 3. Existing human-authority loops (evidence)

| Loop | Status | Notes |
|---|---|---|
| Advisor suggestion → approve → RulesEngine rule | **MOCK/SIMULATION** | Works in-memory; FatherSession intended |
| Advisor reject | **MOCK/SIMULATION** | Memory decision map |
| Smart Alert “dialogue suggestion” | **MOCK/SIMULATION** | Scripted; not classify review |
| Education / studio preview-approve | Adjacent | Content approve — not FS-007 |
| Quran recitation approve → earn | Adjacent | Minutes — not FS-007 |

**Missing:** dedicated parent review of **safety classification hits** (confirm FP, open ticket, dismiss, escalate) with audit.

---

## 4. Advisory vs blocking (OPEN)

Whether a safety classification may:

- notify only,
- create a review ticket,
- temporarily tighten (via Kernel + Mode / WF / AC contracts),
- or never block until human approval,

is **not frozen for FS-007**. See **Q-AI-02**, **Q-AI-03**.

FS-002 / FS-003 already have their own enforcement planes — FS-007 must not invent a parallel silent blocker.

---

## 5. Role matrix (discovered gaps)

| Action | Primary | Co-Parent | Child | Evidence |
|---|---|---|---|---|
| Configure safety tools (search/image) | Intended father | Mother per R-2 level — **UNKNOWN for FS-007** | ⛔ | FAT-065 mock; no RoleGuard audit for AI safety |
| Approve Advisor suggestions | ✅ | ⛔ direct execute | ⛔ | Docs + mock inbox |
| Review classification hits | **UNKNOWN** | **UNKNOWN** | ⛔ | No surface |
| See transparency | — | — | ✅ intended P-7 | **PARTIAL** UI |
| Wipe advisor memory | Owner privacy path | — | ⛔ | Documented; separate from audit |

**Q-AI-04** — Co-Parent authority for offline AI safety configuration and review.

---

## 6. Anti-overreach checklist (discovery)

FS-007 must **not** silently become:

| Forbidden role | Current evidence |
|---|---|
| Permanent policy author | No silent mutation found (**good absence**) |
| Autonomous moderation engine | No engine (**absence**) |
| Surveillance system without transparency | Prototype/P-7 require transparency; Flutter incomplete |
| Replacement for Web Filter | Must stay FS-002 |
| Replacement for App Control | Must stay FS-003 |
| Replacement for SOS | Forbidden by SOS Final |
| Replacement for parental judgment | Approve patterns exist for Advisor only |

---

## 7. Open Owner questions (product)

Full text in [12_FS007_GAP_AND_CONTRADICTION_REGISTER.md](12_FS007_GAP_AND_CONTRADICTION_REGISTER.md) §D:

- **Q-AI-01** — Reconcile Rule 26 vs Charter/P-7/on-device copy  
- **Q-AI-02** — Advisory vs blocking effects of classifications  
- **Q-AI-03** — Whether AI results may create tickets / alerts automatically  
- **Q-AI-04** — Co-Parent AuthZ for configure/review  
- **Q-AI-05** — What parents see (detail level, raw content)  
- **Q-AI-06** — What children see (transparency depth)  
- **Q-AI-07** — Harmful-content categories in v1 scope  
- **Q-AI-08** — Severity taxonomy ownership  
- **Q-AI-09** — Escalation behavior (notify / ticket / Kernel)  
- **Q-AI-10** — Cloud fallback permitted?  
- **Q-AI-11** — Model update authority  
- **Q-AI-12** — Retention of raw vs signal-only  

**Not appended to `QUESTIONS.md`** in this tick (would block harness); live in this package until Owner opens L2.
