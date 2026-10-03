# 08 — FS-007 Privacy, Data, and Retention Discovery

**Mode:** Discover privacy surface — **do not invent** legal/compliance claims or retention numbers.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. What raw content may be processed (candidates)

From P-7 / prototype / FS-004 (not authorized pipelines):

| Content | Documented intent | Flutter reality |
|---|---|---|
| Search terms | P-7 search analysis | Toggle mock only |
| Images | P-7 image classification | Toggle mock only |
| Screenshots | P-7 + FS-004 monitoring | Toggle mock; no capture agent |
| Extracted OCR text | Implied by image→report | **MISSING** |
| Chat / media share blobs | Adjacent features exist | Not wired to safety AI |

---

## 2. What must never leave the device (OPEN)

Rule 26 requires **identity abstraction before events leave**.  
Charter: stages 3–5 cloud with abstraction; stages 1–2 local.

**Unresolved for FS-007:**

| Question | Status |
|---|---|
| May raw screenshots leave device? | **UNKNOWN** — **Q-AI-12** |
| May raw images leave for cloud classify? | **UNKNOWN** — **Q-AI-10/12** |
| Signal-only (category + confidence) sync? | **UNKNOWN** |
| Must local-only mode refuse all egress? | Prototype `offline` implies local — **not frozen** |

Do **not** invent minimization numbers or retention days.

---

## 3. Schema hints (evidence only)

| Schema note | Path |
|---|---|
| `ai_event.payload` = excerpt not archive (S-AIC-006 comment) | `schema.sql` |
| `child_alias` not real name on AI tables | Identity abstraction spirit |
| `audit_log` append-only | Immutable audit |

Flutter does not implement these tables in Drift for offline safety.

---

## 4. Encryption / deletion

| Topic | Status |
|---|---|
| Encrypted store for raw captures | **MISSING** |
| Encrypted classification cache | **MISSING** |
| Parent deletion of AI memory | Advisor forget documented — **not** safety snapshot wipe |
| Permanent wipe vs advisor forget | Register amendment separates them |
| Child deletion of monitoring evidence | **UNKNOWN** / likely forbidden — **Q-AI** |

---

## 5. Parent access boundaries

| Access | Evidence |
|---|---|
| See mock smart alerts | FAT-065/066 UI |
| See raw child content from classify | **MISSING** pipeline |
| Approve Advisor suggestions | Mock inbox |
| Access audit of AI decisions | **MISSING** append for approve |

**Q-AI-05** — What parents see (scores only vs thumbnails vs full raw).

---

## 6. Child transparency

| Requirement | Source | Flutter |
|---|---|---|
| Permanent transparency card | P-7 | **PARTIAL** — CHD-010 / effective monitoring omit search/image/screenshot tools |
| Tutor “parents can see thread” | A-3 | **PARTIAL** copy on CHD-017 |
| Charter: general notice, not full detail | AI Core Charter | **DOCUMENTED** — may conflict with P-7 “permanent card” detail level |

**Q-AI-06** — Resolve transparency depth for offline AI safety tools.

---

## 7. Provenance / audit requirements (discovery)

Classification results should carry (when implemented later):

- provenance (local heuristic / local model / cloud),
- model + safety-policy versions,
- confidence,
- input reference (not necessarily raw bytes),
- actor for human review decisions,

and append to audit — **MISSING** today.

---

## 8. Legal / compliance

This pack **records no** GDPR/PDPL/COPPA legal conclusions. Owner/legal review is out of Discovery scope. Engineering must not claim compliance from mock toggles.
