# 07 — FS-007 Lifecycles (L3)

**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## 1. Classification lifecycle

```
input eligible → (tool active? signed model?) 
  → run local classify/OCR/heuristic
  → emit SafetySignal {category, certainty, severity, provenance, modelVersion, policyVersion, previewRef?}
  → persist signal metadata locally
  → notify authorized adults
  → if certainty in {analysis, confirmed} → create ticket (+ attach previewRef if available)
  → enqueue sync outbox for parent devices
```

**Failure:** emit capability honesty / error audit; **do not** emit fake hit.

---

## 2. Notification lifecycle

Created on **completed** classification → delivered per platform notify prefs (not SOS critical channel) → tap opens ticket or metadata detail → marked read.  
Observer excluded (AI-OD-04).

---

## 3. Ticket lifecycle

```
gate pass → open
  → in_review (optional)
  → resolved | dismissed_fp | suggestion_pending
preview purge on resolved / dismissed_fp
audit append on each transition
```

Partner may resolve/FP (AI-OD-04). Suggestion_pending hands off to FS-002/003/005 human approve — ticket does not auto-mutate those stores.

---

## 4. Provenance / confidence presentation

Always show when available:

- provenance: `local_ml` | `local_heuristic` | `local_ocr+ml`  
- modelVersion · policyVersion  
- certainty label · severity label  

Never present hardcoded sample % as live confidence. Numeric internals may exist for T-AI calibration but **product certainty classes** are authoritative for gate/UX.

---

## 5. Model-version visibility

Parent Overview + Model screen + Ticket detail + Device ack show version.  
Child card may show “on-device analysis” without raw version hash; parent sees versions.
