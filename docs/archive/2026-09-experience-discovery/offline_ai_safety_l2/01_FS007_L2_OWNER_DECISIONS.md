# 01 — FS-007 L2 Owner Decisions Register (COMPLETE)

**System:** FS-007 — Offline AI Safety (classification / signal plane only)  
**Status:** **OWNER DECISIONS FROZEN** — L2 COMPLETE — 2026-09-24  
**Evidence baseline:** `docs/experience_discovery/offline_ai_safety_discovery/` (non-authority)  
**Target AuthZ:** Primary Parent · Co-Parent (Observer / Partner / Full) · Child  
**L3:** [`../offline_ai_safety_l3/`](../offline_ai_safety_l3/)  
**Closure:** [14_FS007_L2_L3_CLOSURE_REPORT.md](14_FS007_L2_L3_CLOSURE_REPORT.md)

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: COMPLETE
FS-007 L3: COMPLETE
FS-007 IMPLEMENTATION: NOT YET AUTHORIZED
```

---

## A. Structural freezes — FROZEN

| ID | Law |
|---|---|
| **AI-SF-01** | Vocabulary: Primary · Co-Parent · Child |
| **AI-SF-02** | AuthZ = RBAC; never device-possession inference |
| **AI-SF-03** | Primary ≠ Co-Parent Full for owner-only / sensitive global classes |
| **AI-SF-04** | AI suggests/classifies/assists only; never autonomous policy, emergency, or silent override |
| **AI-SF-05** | FS-007 outputs = typed safety facts/signals with confidence + provenance — not final policy |
| **AI-SF-06** | Kernel may drive notify + gated tickets only; never deny/block/list/Mode/SOS/permanent policy from classify alone |
| **AI-SF-07** | FS-002 owns URL/keyword lists — no silent rewrite |
| **AI-SF-08** | FS-003 owns package policy — no silent mutation |
| **AI-SF-09** | FS-004 owns P-7 screenshot monitoring **policy**; FS-007 consumes approved inputs / emits signals |
| **AI-SF-10** | FS-005 owns Modes — no activate/rewrite from classify alone |
| **AI-SF-11** | FS-006 / SOS — no AI trigger/escalate |
| **AI-SF-12** | Screen Time minutes/wallets/grants outside FS-007 |
| **AI-SF-13** | Advisor/Insights/Tutor gateways adjacent — no general on-device inference |
| **AI-SF-14** | RulesEngine (ADR-038) outside AI gateways |
| **AI-SF-15** | Offline honesty; no fake protection / fake cloud success |
| **AI-SF-16** | Audit append-only |
| **AI-SF-17** | Child-transparent monitoring when active |
| **AI-SF-18** | Stage-1 mocks / planted fixtures / hardcoded confidence = non-authority |
| **AI-SF-19** | Narrow scope: classification/signal plane only |
| **AI-SF-20** | Signed+versioned on-device ML/OCR for FS-007 only (AI-OD-01) |
| **AI-SF-21** | Heuristics/rules also emit signals only |
| **AI-SF-22** | Classification alone must not permanently change family policy |
| **AI-SF-23** | Always notify on completed classification; ticket only when gate satisfied |
| **AI-SF-24** | No invented numeric confidence thresholds |
| **AI-SF-25** | AuthZ matrix AI-OD-04 |
| **AI-SF-26** | Global export/wipe Primary-only rules unchanged |
| **AI-SF-27** | Parent visibility = metadata + redacted preview (AI-OD-05); full raw not default |
| **AI-SF-28** | Ticket gate = certainty-class gate **B1** (AI-OD-03-GATE) |
| **AI-SF-29** | Child permanent transparency card + explicit tools + offline/local named when applicable (AI-OD-06) |
| **AI-SF-30** | v1 category set closed (AI-OD-07); severity/certainty taxonomy (AI-OD-08) |
| **AI-SF-31** | Escalation catalog (AI-OD-09); local-only classify v1 (AI-OD-10) |
| **AI-SF-32** | Model update AuthZ (AI-OD-11); retention (AI-OD-12) |
| **AI-SF-33** | **Real-capability honesty:** no fixture alerts, hardcoded confidence-as-truth, fake classifier success, or fake cloud success |

---

## B. Owner / Product freezes (COMPLETE)

| ID | Q | Choice | Frozen law |
|---|---|---|---|
| **AI-OD-01** | Q-AI-01 | **B** | Narrow Rule 26 amendment: signed/versioned on-device ML/OCR for FS-007 safety classify only. No general Advisor/Tutor/Insights inference; no brain unlock; no unsigned models; signals ≠ policy. [02](02_FS007_Q_AI_01_CONSTITUTIONAL_PLACEMENT.md) · [03](03_FS007_RULE26_NARROW_AMENDMENT.md) |
| **AI-OD-02** | Q-AI-02 | **B** | Advisory + auto notify and/or review ticket. Classification alone must not deny content, mutate FS-002/003/005, permanent policy, or SOS. [04](04_FS007_Q_AI_02_ADVISORY_VS_BLOCKING.md) |
| **AI-OD-03** | Q-AI-03 | **B** | Always notify on completed classification; ticket only when explicit gate satisfied. [05](05_FS007_Q_AI_03_AUTO_TICKETS_ALERTS.md) |
| **AI-OD-03-GATE** | (sub) | **B1** | **Ticket when certainty/state is not `unknown` and not `preliminary` (or equivalent low-certainty class).** Tickets fire for `analysis` and `confirmed` (AI-OD-08). No numeric % thresholds. Notify still always on completed classification (including preliminary/unknown as notify-only). |
| **AI-OD-04** | Q-AI-04 | **A** | Configure: Primary+Full. Notify+review tickets: Primary+Partner+Full. Observer: no push, no review action. Child: transparency only. [06](06_FS007_Q_AI_04_CO_PARENT_AUTHZ.md) |
| **AI-OD-05** | Q-AI-05 | **B** | Metadata + redacted preview when available; full raw not default; honest unavailable preview. [07](07_FS007_Q_AI_05_PARENT_RAW_CONTENT_VISIBILITY.md) |
| **AI-OD-06** | Q-AI-06 | **B+B1** | **Permanent child transparency card** required when any Search / Image / Screenshot-related monitoring-or-classify capability is configured on. Card **explicitly lists** active tools among Search analysis · Image classification · Screenshot monitoring (FS-004 owns screenshot **policy**; listing reflects effective configured state). **Name offline/local on-device classification** when the local plane applies (AI-OD-01). Configured-but-degraded/unsupported → **per-tool honest state** on the card; never claim active protection when plane missing. Child has **no** admin. [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-07** | Q-AI-07 | **Closed v1 set** | v1 harmful-content **categories** (closed): `sexual_content` · `sensitive_visual` · `violence_or_threat` · `self_harm_signal` · `predatory_or_grooming_signal` · `substance_or_gambling` · `suspicious_language` · `uncategorized_concern`. **Out of v1:** general free-form sentiment product, Advisor coaching categories, peer-compare, education grading. Mapping/models = T-AI. [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-08** | Q-AI-08 | **Dual taxonomy** | **Certainty** (ticket-relevant, schema-aligned): `unknown` · `preliminary` · `analysis` · `confirmed`. **Severity** (product labels, non-numeric): `low` · `elevated` · `high`. Category→severity defaults = content/T-AI follow-up — **no invented score cutoffs**. Gate uses **certainty** (AI-OD-03-GATE). [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-09** | Q-AI-09 | **Notify · gated ticket · suggest-only** | Allowed escalations from a hit: (1) parent safety **notification**; (2) **review ticket** if gate passes; (3) optional **human-approved suggestion** toward FS-002/003/005 or RulesEngine — never auto-apply. **Forbidden:** SOS trigger/escalate; silent list/package/Mode mutation; permanent policy from AI alone. [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-10** | Q-AI-10 | **Local classify only (v1)** | **Cloud-assisted classification inference is out of v1.** Classification runs on-device per AI-OD-01. **Family sync** of signals, notifications, tickets, and ack metadata remains permitted under offline-first G-1 (not “cloud classify”). Unavailable sync → honest queued/pending — never fake delivered cloud classify. Future cloud classify requires new Owner OD. [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-11** | Q-AI-11 | **Primary+Full apply** | Model/OCR assets must be **signed + versioned**. Unsigned/unversioned **must not execute**. **Primary + Full** authorize **apply/activate/rollback** of model updates (same configure class as AI-OD-04). Partner/Observer/Child cannot authorize model apply. Integrity failure → refuse run + honesty. Exact transport = T-AI. [09](09_FS007_REMAINING_L2_DECISIONS.md) |
| **AI-OD-12** | Q-AI-12 | **Minimize raw; bind preview to review** | **Do not retain full raw text/image by default.** **Redacted preview** may be retained only while needed for open/active review tickets; **purge preview** on ticket resolve, false-positive dismiss, or equivalent close. **Classification signal metadata** may be retained for parent history + **append-only audit**. Exact day counts / legal hold = **not invented** (legal/T-AI parameter later). Deletion of previews does not delete audit rows. [09](09_FS007_REMAINING_L2_DECISIONS.md) |

**Owner/Product decisions remaining:** **NONE**  
**Silent closures:** **NONE** — remaining items closed in consolidated L2 pass documented in [09](09_FS007_REMAINING_L2_DECISIONS.md).

---

## C. Q-AI closure map

| Q-ID | Status | Maps to |
|---|---|---|
| Q-AI-01…12 | **CLOSED** | AI-OD-01…12 |
| AI-OD-03-GATE | **CLOSED** | **B1** |

---

## D. Technical T-AI still OPEN (no mechanisms selected)

| ID | Topic | Frozen product side |
|---|---|---|
| **T-AI-01** | Local inference runtime feasibility | AI-OD-01 permits signed on-device ML/OCR |
| **T-AI-02** | Arabic OCR quality / RTL | OCR in scope for classify inputs |
| **T-AI-03** | OCR uncertainty → certainty mapping | AI-OD-08 classes |
| **T-AI-04** | AR+EN (+ arabizi) classify models | AI-OD-07 categories |
| **T-AI-05** | Dictionary packaging vs FS-002 lists | FS-002 owns lists; FS-007 signals only |
| **T-AI-06…09** | Packaging, size, battery, quantization | No vendor/size chosen |
| **T-AI-10…11** | Signing, secure update, rollback | AI-OD-11 authority |
| **T-AI-12** | Offline last-good model cache | Honesty when missing/stale |
| **T-AI-13** | Android/iOS device matrix | Honesty when unsupported |
| **T-AI-14** | Cloud transport | **N/A for classify v1** (AI-OD-10); sync transport separate |
| **T-AI-15** | Workers / background execution | — |
| **T-AI-16** | Confidence calibration → certainty classes | No numeric product thresholds |
| **T-AI-17** | Adversarial robustness | — |
| **T-AI-18** | Test datasets AR+EN | Real capability; no fixture-as-production |
| **T-AI-19** | Event/audit catalog binding | AI-SF-16 |
| **T-AI-20** | Local↔cloud reconcile | Deferred (no cloud classify v1) |
| **T-AI-21** | Redaction implementation for previews | AI-OD-05 product law only |
| **T-AI-22** | Sync/outbox for signals/tickets | G-1 · AI-OD-10 |

**Forbidden until Implementation Commission:** TFLite/ONNX/ML Kit selection, model downloads, production code, Rule 26 file edits without engineering card.

---

## E. Gate

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: COMPLETE
FS-007 L3: COMPLETE
FS-007 IMPLEMENTATION: NOT YET AUTHORIZED
```
