# 08 — FS-007 Offline, Sync, and Honesty (L3)

**Authority:** G-1 · AI-OD-01 · AI-OD-10 · AI-SF-15 · AI-SF-33  
**Master:** [13_FS007_L3_MASTER_CONTRACT.md](13_FS007_L3_MASTER_CONTRACT.md)

---

## Offline (zero connectivity)

| Remains | Queued | Unavailable |
|---|---|---|
| Local classify if `active` | Notify/ticket sync to parent devices | Cloud classify (out of v1) |
| Local signal+preview store | Outbox | Fake “synced to parents” |
| Child transparency from local config | Model download if not cached | |

Last-good **signed** model may run if present (T-AI-12). Missing model → not active.

---

## Sync / outbox

Sync **signals, notifications, tickets, ack, model-version reports** — not full raw by default.  
Outbox durable; conflict policy = T-AI-22.  
Never drop safety ticket silently without honesty.

---

## Local vs cloud result states

v1: **local only**. UI provenance never shows `cloud` as classify source in v1.

---

## Failure / recovery

| Failure | Recovery UX |
|---|---|
| Integrity fail | Refuse; Primary/Full notified; child unavailable |
| Apply interrupted | Keep last-good signed; honesty |
| OCR fail | Certainty may fall to preliminary/unknown; notify-only if completed with low certainty |
| Storage full | Degraded; no fake success |

---

## Real-capability honesty checklist (normative)

- [ ] Real local classification path or unsupported  
- [ ] Real OCR when claimed or unsupported  
- [ ] Real model assets + signature verify  
- [ ] Real versioning on signals  
- [ ] Real local persistence of signals/tickets  
- [ ] Real device execution (or honesty)  
- [ ] No fixture alerts as production detections  
- [ ] No hardcoded confidence-as-truth  
- [ ] No fake classifier success  
- [ ] No fake cloud success  
