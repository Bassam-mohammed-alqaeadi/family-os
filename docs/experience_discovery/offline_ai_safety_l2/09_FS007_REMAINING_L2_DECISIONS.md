# 09 — FS-007 Remaining L2 Decisions (Consolidated Freeze)

**Status:** **FROZEN** — 2026-09-24 (Owner-authorized consolidated L2 closure pass)  
**Register:** [01_FS007_L2_OWNER_DECISIONS.md](01_FS007_L2_OWNER_DECISIONS.md)  
**Prior freezes:** AI-OD-01…05 already Owner-chosen; this doc freezes **AI-OD-03-GATE** and **AI-OD-06…12**.

```
FS-007 L2 POLICY: COMPLETE
FS-007 IMPLEMENTATION: NOT YET AUTHORIZED
```

---

## AI-OD-03-GATE = B1 (CLOSED)

**Rule:** Create a **review ticket** only when classification **certainty** is `analysis` or `confirmed` (AI-OD-08).  
Do **not** create a ticket when certainty is `unknown` or `preliminary` (or equivalent low-certainty class).  
**Notification** still fires on every **completed** classification (AI-OD-03), including preliminary/unknown (notify-only).  
**No numeric confidence % thresholds.**

**Rationale:** Explicit, bounded, schema-aligned; avoids vague parent-configured gates (B3) and avoids inventing high-concern sets before category ops mature.

---

## AI-OD-06 = B + B1 (CLOSED) — Child transparency

**Rule:**

1. **Permanent transparency card** (or equivalent persistent child surface) is **mandatory** when any of Search analysis / Image classification / Screenshot monitoring is configured on for that child.  
2. Card **explicitly lists** which of those tools are active.  
3. **Offline / on-device local classification is named** when the local plane applies (AI-OD-01).  
4. If configured but **degraded / unsupported / missing model / stale model**: show **per-tool honest state** — never “protected” / “classifying” when capability unavailable.  
5. Child: **no** configure, review, or ticket admin (AI-OD-04).

**Rationale:** Resolves P-7 vs Charter toward P-7 with AI-OD-01 honesty; FS-004 remains policy owner for screenshot monitoring.

---

## AI-OD-07 (CLOSED) — Harmful-content categories v1

**In-scope closed set:**

| ID | Meaning (product) |
|---|---|
| `sexual_content` | Sexual / pornographic text signals |
| `sensitive_visual` | Sensitive imagery (incl. sexual/violent imagery class) |
| `violence_or_threat` | Violence / credible threat language or imagery signals |
| `self_harm_signal` | Self-harm / crisis **signal** only — **never** auto SOS |
| `predatory_or_grooming_signal` | Predatory / grooming-adjacent language signals |
| `substance_or_gambling` | Drugs / gambling related signals |
| `suspicious_language` | Flagged phrase / arabizi-suspicious language class |
| `uncategorized_concern` | Model/heuristic concern without stable category |

**Out of v1:** free-form sentiment product, Advisor dinner questions, peer-compare, education scoring, location risk scoring as FS-007 categories.

---

## AI-OD-08 (CLOSED) — Severity / certainty taxonomy

| Axis | Values | Role |
|---|---|---|
| **Certainty** | `unknown` · `preliminary` · `analysis` · `confirmed` | Ticket gate (B1); parent metadata |
| **Severity** | `low` · `elevated` · `high` | Parent triage label; **not** an auto-enforce trigger |

No invented percentage cutoffs. Calibration = **T-AI-16**.

---

## AI-OD-09 (CLOSED) — Escalation behavior

| Allowed | Forbidden |
|---|---|
| Parent safety notification | SOS trigger / escalate |
| Gated review ticket | Silent FS-002 list rewrite |
| Human-approved suggestion toward WF / App Control / Modes / RulesEngine | Silent FS-003 package mutation |
| Append-only audit | Silent FS-005 Mode activate/rewrite |
| | Permanent policy from classification alone |
| | Hidden Policy Kernel authorship |

---

## AI-OD-10 (CLOSED) — Cloud fallback

| Plane | v1 law |
|---|---|
| **On-device classification** | In scope (AI-OD-01) |
| **Cloud classification inference** | **Out of v1** |
| **Family sync** of signals / notifications / tickets / device ack | **In scope** (G-1 offline-first) |
| Offline with no sync | Queue honestly; never fake cloud classify success |

---

## AI-OD-11 (CLOSED) — Model update authority

- Execute only **signed + versioned** assets.  
- **Primary + Full** authorize apply / activate / rollback.  
- Partner / Observer / Child: no apply authority.  
- Integrity fail → do not run; show honesty (parent + child card if tool configured).  
- Transport/packaging = T-AI.

---

## AI-OD-12 (CLOSED) — Retention

| Artifact | Retention law |
|---|---|
| Full raw text/image | **Not retained by default** |
| Redacted preview | Only while needed for **open/active** review; **purge on resolve / FP dismiss / close** |
| Signal metadata | Retain for history + parent surfaces as product requires |
| Audit log | Append-only; not deleted by preview purge |
| Exact day counts | **Not invented** — legal/T-AI later |

---

## Real-capability honesty (cross-cutting)

Implementation must use **real** local classification, OCR (when used), model assets, integrity/versioning, local persistence, and device execution — or show **unsupported/unavailable**.  
**Forbidden in production paths:** fixture alerts as live detections, hardcoded confidence-as-truth, fake classifier success, fake cloud success.
