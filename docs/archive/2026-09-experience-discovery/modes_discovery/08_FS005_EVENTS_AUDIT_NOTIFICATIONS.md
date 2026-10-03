# 08 — FS-005 Events / Audit / Notifications

**Mode:** Evidence of event pipeline for Modes.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Expected (Register / sibling patterns)

| Event class | Expected role |
|---|---|
| Mode activated / deactivated | Audit + parent/child notification |
| Mode conflict (M-B) | Father notified |
| Grace started / ended | Child gentle finish; optional parent |
| Schedule approaching (historical Phase4 gap) | “5 minutes before” — **not implemented** in Stage-1 |
| Device ack stale | Honesty (pattern from other systems) |

---

## 2. What exists

| Mechanism | Modes use? |
|---|---|
| `SmartModeActivationBus` notifyListeners | Yes — UI stream, **not** audit log |
| Soft AppToast enter/exit on CHD-004 | Yes — UX feedback |
| `AuditAppend` (privacy / web unlock patterns) | **Not** called from FAT-085 |
| Family EventBus / typed FamilyEvents | **No** mode events found |
| Push / local notification for grace | **MISSING** |
| M-B father notification | **MISSING** |

---

## 3. Prototype notifications

Prototype toast on `setFamilyMode`; child grace banner. Not a durable event pipeline.

---

## 4. Classification

| Capability | Class |
|---|---|
| In-session activation stream | **PARTIAL** |
| Audit trail for mode mutations | **MISSING** |
| Conflict notification | **MISSING** |
| Pre-activation warning | **DOCUMENTED ONLY** / historically open |
| SOS notifications muted by mode | Must **never** — SOS law |

---

## 5. Open technical

**T-MODE-06** grace delivery channel  
**T-MODE-09** conflict notify pipeline  
**T-MODE-10** audit event type catalog
