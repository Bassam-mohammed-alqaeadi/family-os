# 01 — FS-007 Scope and Mission (Discovery)

**System label:** FS-007 — Offline AI Safety  
**Date:** 2026-09-24  
**Mode:** Evidence audit only — **no** L2 product law · **no** wireframes · **no** app / ML / OCR code · **no** model downloads  
**Authority (frozen):** Identity (Primary / Co-Parent / Child) · Policy Kernel · Offline-first · Audit / Events / Notifications · SOS Final · Screen Time Final · FS-001 Location L2/L3 · FS-002 Web Filtering L2/L3 · FS-003 Application & System Control L2/L3 · FS-004 Screen & Camera Control L2/L3 · FS-005 Modes L2/L3 · FS-006 SOS L2/L3  
**Evidence baseline:** repository code + Policy Register (§4 P-7, §7 AI, RULE 26) + AI Core Charter + schema.sql + frozen prototype Smart Watch + sibling discovery/L2 packs  
**Treat as evidence only (not target authority):** current Flutter Advisor / Smart Alerts mocks, ARB “on-device” copy, deferred TFLite readiness notes, old charter hybrid-on-device language  

**Entry:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: COMPLETE
FS-007 L3: COMPLETE
FS-007 IMPLEMENTATION: NOT YET AUTHORIZED
```
---

## 1. Mission of this discovery

Inventory **current repository evidence** and **documented product language** related to:

- Offline AI safety (local content classification when connectivity is absent)
- Local text / image safety signals; OCR / text extraction
- Safety dictionary / keyword detection (Arabic + English)
- Harmful-content detection; child-safety categorization
- Risk scoring / confidence; classification provenance
- Local-only processing vs cloud-assisted classification
- Offline fallback; model / asset lifecycle; integrity / signing
- Privacy boundaries; retention; PII / sensitive-content handling
- Human review / parent confirmation; explainability
- False-positive / false-negative handling; unknown / uncertain states
- Audit / evidence; parent notifications; child transparency
- Multi-device / sync / outbox; degraded / unsupported AI states
- Battery / storage constraints; RTL / Arabic language handling
- Platform dependencies; security / adversarial considerations
- Interaction with FS-002 / FS-003 / FS-004 / FS-005 / FS-006 and Policy Kernel

**Hypothesis (evidence, not frozen here):** FS-007 is the **safety-classification signal plane** that may emit typed facts/signals with confidence and provenance — **never** a silent policy author, autonomous moderator, SOS escalator, or replacement for Web Filter / App Control / parental judgment.

---

## 2. Working definition (discovery, not law)

For this audit, **Offline AI Safety** means any capability that:

1. Takes local inputs (text, search terms, images, screenshots, or extracted OCR text), and  
2. Produces a **safety classification / risk signal** (category, severity, confidence, provenance), and  
3. Remains usable (or honestly degraded) with **zero connectivity**, and  
4. Does **not** itself mutate permanent policy, block packages/URLs, or fire SOS without an explicit frozen contract + human authority path.

Whether that signal is produced by **rules/heuristics**, **on-device ML**, **cloud gateway**, or **hybrid** is **Owner L2 + T-AI** — not decided here.

---

## 3. Explicit non-goals of this pack

| Non-goal |
|---|
| Closing Owner decisions (L2) |
| Selecting inference runtimes (TFLite / ONNX / ML Kit / etc.) |
| Selecting model vendors, sizes, quantization, or thresholds |
| Downloading / bundling models or OCR engines |
| Implementing classifiers, dictionaries, or background workers |
| Wireframes / Flutter / native changes |
| Freezing severity taxonomies or retention numbers |
| Absorbing Family Advisor chat / Insights / Tutor LLM product into FS-007 |
| Absorbing FS-002 Web Filter list ownership |
| Absorbing FS-003 package Allow/Block |
| Absorbing FS-004 capture monitoring policy ownership |
| Absorbing FS-006 SOS lifecycle |
| Claiming “AI protected the child” from a mock toggle or fixture score |

---

## 4. Three planes that must stay distinct

| Plane | What it is | FS-007 relation |
|---|---|---|
| **(A) Family Advisor / Insights / Tutor gateways** | Rule 26 suggest-only repos; stages as server flags | Adjacent intelligence UX — **not** the offline safety classifier |
| **(B) P-7 monitoring policy + honesty** | Search / image / screenshot switches; child transparency | FS-004 L2 owns **screenshot monitoring policy**; FAT-065 may present; FS-007 may later own **classification signals** on approved inputs — **OPEN** |
| **(C) Offline content safety classification** | Local/offline category + confidence + provenance | **This pack’s focus** — largely **MISSING** in code today |

Do **not** let “AI” redesign the entire Family OS. Adjacent capabilities are inventoried, not absorbed.

---

## 5. Critical constitutional tension (investigate, do not resolve)

| Source | Binding gist |
|---|---|
| **RULE 26** (Policy Register + constitution) | **No inference runs inside the app**; AI via Advisor / Insights / Tutor gateways; `AiSuggestion` has **no `execute()`** |
| **AI Core Charter** (14 Sep 2026) | Hybrid: stages 1–2 **on device**; 3–5 cloud with identity abstraction |
| **P-7** | Search analysis / **image classification** / screenshots + transparency |
| **Prototype + ARB** | “On-device image classification”; offline local analysis then sync |
| **Readiness N-09** | TFLite image analysis named as **P2 deferred** bridge |

This discovery **records** the tension. Reconciliation is **Q-AI-01** (and related) — Owner L2 only.

---

## 6. Global AI law (not inventable here)

**AI = suggest / classify / assist only.**  
**AI never autonomously changes policy, executes emergency actions, or silently overrides human decisions.**

Classifications are **facts/signals with provenance**, not final policy decisions.

---

## 7. Document index

| # | File |
|---|---|
| 01 | this file |
| 02 | [02_FS007_CURRENT_REPO_EVIDENCE.md](02_FS007_CURRENT_REPO_EVIDENCE.md) |
| 03 | [03_FS007_CAPABILITY_INVENTORY.md](03_FS007_CAPABILITY_INVENTORY.md) |
| 04 | [04_FS007_AI_POLICY_AND_HUMAN_AUTHORITY_DISCOVERY.md](04_FS007_AI_POLICY_AND_HUMAN_AUTHORITY_DISCOVERY.md) |
| 05 | [05_FS007_OFFLINE_CLASSIFICATION_DISCOVERY.md](05_FS007_OFFLINE_CLASSIFICATION_DISCOVERY.md) |
| 06 | [06_FS007_OCR_DICTIONARY_LANGUAGE_DISCOVERY.md](06_FS007_OCR_DICTIONARY_LANGUAGE_DISCOVERY.md) |
| 07 | [07_FS007_MODEL_ASSET_SECURITY_DISCOVERY.md](07_FS007_MODEL_ASSET_SECURITY_DISCOVERY.md) |
| 08 | [08_FS007_PRIVACY_DATA_RETENTION_DISCOVERY.md](08_FS007_PRIVACY_DATA_RETENTION_DISCOVERY.md) |
| 09 | [09_FS007_OFFLINE_SYNC_AND_UPDATE_DISCOVERY.md](09_FS007_OFFLINE_SYNC_AND_UPDATE_DISCOVERY.md) |
| 10 | [10_FS007_EVENTS_AUDIT_NOTIFICATIONS.md](10_FS007_EVENTS_AUDIT_NOTIFICATIONS.md) |
| 11 | [11_FS007_CROSS_SYSTEM_DEPENDENCIES.md](11_FS007_CROSS_SYSTEM_DEPENDENCIES.md) |
| 12 | [12_FS007_GAP_AND_CONTRADICTION_REGISTER.md](12_FS007_GAP_AND_CONTRADICTION_REGISTER.md) |
| 13 | [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md) |
