# 07 — FS-002 Offline & Sync Contract (L2 Target) — FROZEN

**Status:** FROZEN structural · T-WF-04/05 numeric/algorithm open

---

## 1. Principles

| Law | Ref |
|---|---|
| No fake cloud success | WF-SF-04 |
| `enforced` only with acked policy version + verified plane | WF-SF-04 · WF-OD-04 |
| Durable outbox for policy & exception decisions | Offline-first |
| Identity envelope on sync items | family + child + device/enrollment |

---

## 2. Versioning

- Family baseline and each child override versioned.  
- Device tracks `ackedVersion` per applicable policy docs.  
- Parent UI: pending when saved > acked.

---

## 3. Effective policy on device

Resolve family default + child override (WF-OD-01), apply Mode tighten context, then evaluate.

---

## 4. Open technical

| ID | Open |
|---|---|
| T-WF-04 | Ack/stale TTL numbers |
| T-WF-05 | Batching / conflict algorithms |

---

## 5. Non-adoption

Same-process Stage-1 prefs bus ≠ multi-device sync product.
