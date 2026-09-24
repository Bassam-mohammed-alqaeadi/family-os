# 12 — FS-007 Gap and Contradiction Register

**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## A. Contradictions

| ID | Tension | Severity | Notes |
|---|---|---|---|
| **AI-C-01** | **RULE 26** “no inference in the app” vs **AI Core Charter** hybrid on-device stages 1–2 vs **P-7** image classification vs **ARB/prototype** “on-device image classification” vs **N-09 TFLite P2** | **Critical** | Core constitutional conflict for FS-007 — **Q-AI-01** |
| **AI-C-02** | UI copy claims on-device classify / offline analysis while **no classifier exists** | **High** | Honesty / Rule 23–24 |
| **AI-C-03** | Architecture tests **ban** on-device inference symbols while product UX sells on-device classify | **High** | Same root as AI-C-01 |
| **AI-C-04** | Charter child “general notice” vs P-7 “permanent transparency card” detail | **Medium** | **Q-AI-06** |
| **AI-C-05** | Schema `ai_suggestion.confidence*` vs Dart `AiSuggestion` without confidence | **Medium** | Backend-readiness gap |
| **AI-C-06** | Registry S-SEC-* marked present vs Flutter mocks only | **Medium** | CSV ≠ reality |
| **AI-C-07** | `InsightsRepository` / `TutorRepository` named in Rule 26 vs **types missing**; CHD-017 uses different repo | **Medium** | Gateway incompleteness (STAGE3-AI adjacent) |
| **AI-C-08** | FS-004 owns P-7 screenshot policy vs FAT-065 hosts toggles that look like ownership | **Medium** | SC-OD-09 already froze FS-004; presentation remaining |
| **AI-C-09** | FS-002 keyword dictionary ownership vs future “AI safety dictionary” temptation | **Medium** | Keep lists in FS-002 |
| **AI-C-10** | Planted Smart Alert fixtures vs Rule 23 “notifications from real event pipeline” | **Medium** | Mock debt |

---

## B. Gaps

| ID | Gap | Severity |
|---|---|---|
| **AI-GAP-01** | No offline text/image safety classifier | Critical |
| **AI-GAP-02** | No OCR | High |
| **AI-GAP-03** | No model assets / signing / update lifecycle | High |
| **AI-GAP-04** | No classification result type (confidence + provenance + versions) | High |
| **AI-GAP-05** | No parent review workflow for safety hits | High |
| **AI-GAP-06** | No audit/event emission for classify/review | High |
| **AI-GAP-07** | No sync/outbox/multi-device ack for AI safety | High |
| **AI-GAP-08** | Child transparency incomplete for search/image/screenshot tools | High |
| **AI-GAP-09** | No FP/FN/unknown/explainability paths | High |
| **AI-GAP-10** | No degraded/missing/stale model honesty states | High |
| **AI-GAP-11** | No FS-007 AuthZ matrix / RoleGuard | Medium |
| **AI-GAP-12** | No Kernel typed safety-signal contract | Medium |
| **AI-GAP-13** | No cloud↔local reconciliation rules | Medium |
| **AI-GAP-14** | No test datasets for safety AI | Medium |
| **AI-GAP-15** | Architecture gate does not ban ML package names | Low |
| **AI-GAP-16** | Retention / raw egress semantics unset | High (product) |
| **AI-GAP-17** | Category + severity taxonomy unset | High (product) |
| **AI-GAP-18** | Advisory vs blocking unset | High (product) |

---

## C. Good absences (keep)

| Absence | Why good |
|---|---|
| No silent AI policy mutation | Sovereignty |
| No AI→SOS fire path | SOS Final |
| No AI package/URL silent block | FS-002/003 ownership |
| No ML deps shipped yet | Avoids unauthorized implementation |

---

## D. Owner questions (Q-AI) — OPEN

Do **not** silently decide these. Live in this package until L2; **not** appended to root `QUESTIONS.md` this tick.

### Q-AI-01 — Constitutional placement of Offline AI Safety
**Why:** Rule 26 forbids in-app inference; Charter/P-7/prototype/ARB/TFLite-P2 imply local classification.  
**Question:** For FS-007 v1, choose the binding interpretation:  
**(A)** Charter Stage-1 **rules/heuristics only** offline (no neural weights; Rule 26 intact for ML);  
**(B)** Amend Rule 26 to allow **signed on-device ML/OCR** for safety classification only;  
**(C)** **Capture/queue locally**, classify only via **cloud gateway** (honest offline = pending);  
**(D)** Hybrid of A+C or B+C with explicit honesty states.  
**Blocks:** L2 architecture, T-AI runtime work, ARB honesty fixes.

### Q-AI-02 — Advisory vs blocking
**Why:** Not frozen whether a safety signal may deny content/apps.  
**Question:** Are FS-007 classifications **advisory-only** until human approval, or may Kernel/WF/AC apply **bounded** effects under explicit contracts?  
**Options:** Advisory-only · Notify+ticket · Bounded auto-tighten (specify planes) · Other.

### Q-AI-03 — Auto tickets / alerts
**Why:** P-7 says report to father on detection; Rule 23 forbids planted alerts.  
**Question:** May a classification **automatically** create a parent alert/ticket, or only after confidence gate / human-configured rule?  
**Do not invent thresholds here.**

### Q-AI-04 — Co-Parent AuthZ
**Question:** May Co-Parent configure offline AI tools and/or review hits at Full / Rules / Observer levels?

### Q-AI-05 — Parent visibility of raw content
**Question:** What may parents see on a hit: category+confidence only · redacted preview · full raw text/image · configurable?

### Q-AI-06 — Child transparency depth
**Question:** Resolve Charter “general notice” vs P-7 permanent card listing search/image/screenshot tools — mandatory detail level for FS-007?

### Q-AI-07 — Harmful-content categories in v1
**Question:** Which category set is in scope for v1 (do not invent; Owner must name or point to frozen list)? Out-of-scope categories?

### Q-AI-08 — Severity taxonomy
**Question:** Who owns severity labels (1–5 schema vs product names)? Mapping from categories?

### Q-AI-09 — Escalation behavior
**Question:** Allowed escalations from a hit: notify · ticket · suggest WF/AC/Mode change · **never SOS** (confirm)? Any other?

### Q-AI-10 — Cloud fallback
**Question:** When online, is cloud-assisted classification **permitted**, **forbidden**, or **parent-opt-in**? Raw vs signal-only egress?

### Q-AI-11 — Model update authority
**Question:** Automatic signed updates vs Owner-gated vs father-confirm each version?

### Q-AI-12 — Retention of raw vs signals
**Question:** Retention semantics for raw captures vs classification signals (without inventing day counts — Owner sets or defers to legal)? Deletion authority?

---

## E. Technical questions (T-AI) — OPEN

No mechanisms selected during Discovery.

| ID | Topic |
|---|---|
| **T-AI-01** | Local inference feasibility under Q-AI-01 outcome |
| **T-AI-02** | Arabic OCR feasibility / quality / RTL |
| **T-AI-03** | OCR uncertainty representation |
| **T-AI-04** | Arabic + English (+ arabizi) classification feasibility |
| **T-AI-05** | Safety dictionary packaging vs FS-002 list store |
| **T-AI-06** | Model packaging / distribution format |
| **T-AI-07** | Model size / storage budget (measure, do not invent product claim) |
| **T-AI-08** | CPU / battery / thermal impact |
| **T-AI-09** | Quantization options (feasibility only) |
| **T-AI-10** | Model integrity / signing |
| **T-AI-11** | Secure update + rollback / versioning |
| **T-AI-12** | Offline cache of last-good model/assets |
| **T-AI-13** | Device compatibility (Android/iOS / ABI / Neural Engine) |
| **T-AI-14** | Cloud fallback transport + privacy-preserving egress |
| **T-AI-15** | Inference runtime + worker/background execution |
| **T-AI-16** | Confidence calibration approach |
| **T-AI-17** | Adversarial / evasion robustness testing |
| **T-AI-18** | Test datasets / fixtures (AR+EN) |
| **T-AI-19** | Event/audit catalog binding (`ai_event` vs dedicated) |
| **T-AI-20** | Local↔cloud result reconciliation algorithms |

---

## F. Recommended L2 entry order

1. Answer **Q-AI-01** (constitutional).  
2. Answer **Q-AI-02/03/07/09/10/12** (effects, categories, privacy).  
3. Answer **Q-AI-04/05/06/08/11** (AuthZ, UX, severity, updates).  
4. Run **T-AI** verification **without** selecting vendors until Owner authorizes implementation phase.
