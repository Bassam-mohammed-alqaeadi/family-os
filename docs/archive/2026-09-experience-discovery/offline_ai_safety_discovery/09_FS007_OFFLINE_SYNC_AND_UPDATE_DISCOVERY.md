# 09 — FS-007 Offline Sync and Update Discovery

**Mode:** Offline-first audit for AI safety — **no** TTL / protocol invention.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Platform offline-first law (G-1)

Register **G-1:** work with last synced family state; show last synced; honest offline wording.

Applies to FS-007 when (if) classifications and model/policy versions become real state.

---

## 2. What remains available with zero connectivity (today)

| Artifact | Available offline? |
|---|---|
| Mock Smart Alerts UI | Yes (local memory) |
| Mock Advisor suggestions | Yes (baked strings) |
| Cached AI stage flags | Yes (memory cache) |
| Real local classifier | **No** |
| Cloud classify | **No** |
| Model download | **No** |
| Sync of safety hits | **No** outbox |

---

## 3. Queue / sync inventory

| Channel | FS-007 use | Status |
|---|---|---|
| Rule 26 EventBus → sync queue | Documented for FamilyEvents | **DOCUMENTED ONLY** for AI hooks; no safety classify events |
| `PolicySyncBus` | ST schedule/policy kinds | **No** AI safety kind |
| Smart Mode activation bus | Modes | Adjacent only |
| Durable outbox for classifications | — | **MISSING** |
| Durable outbox for model ack | — | **MISSING** |

---

## 4. Multi-device behavior

| Topic | Status |
|---|---|
| Parent configures tools → child device receives | **MISSING** (in-memory same process only) |
| Child device ack of safety policy version | **MISSING** |
| Per-device model version skew | **MISSING** |
| Mother device sees alerts from child classify | Fixture only |

---

## 5. Model/policy staleness representation

| State | Present? |
|---|---|
| Last synced model version UI | **MISSING** |
| Stale model banner | **MISSING** |
| Failed update + keep last good | **MISSING** |
| Unacknowledged policy | **MISSING** |

Sibling honesty patterns (FS-002/003/004) are the template — FS-007 has **no** equivalent yet.

---

## 6. Cloud results vs local results

| Topic | Status |
|---|---|
| Dual-provenance merge rules | **MISSING** / **UNKNOWN** |
| Prefer higher confidence? | Must not invent — **T-AI-14** / **Q-AI** |
| Cloud override of local | **UNKNOWN** — risk of silent policy if misused |

---

## 7. Update recovery

| Failure | Recovery evidence |
|---|---|
| Partial model download | **MISSING** |
| Signature fail | **MISSING** |
| Disk full mid-update | **MISSING** |
| App kill mid-activate | **MISSING** |

**T-AI-09** — rollback/versioning feasibility.  
**T-AI-12** — offline cache of last good model.

---

## 8. Battery / storage constraints

No FS-007 budgets found. Discovery records need for L2/L3 honesty about:

- large model storage,
- background CPU,
- thermal throttling,

without selecting numbers now (**T-AI-07**, **T-AI-08**).
