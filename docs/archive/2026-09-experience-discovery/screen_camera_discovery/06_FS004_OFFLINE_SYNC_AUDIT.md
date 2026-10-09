# 06 — FS-004 Offline / Sync Audit

**Mode:** Evidence only. Separate UI persistence from child-device enforcement.  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Questions

Does any FS-004-class policy:

1. Persist locally?  
2. Reach the child device?  
3. Get acknowledged?  
4. Survive offline?  
5. Replay after reconnect?  
6. Remain enforceable offline?

---

## 2. Answers (CURRENT)

| Question | Screenshot toggle (FAT-065) | Camera app block (FAT-034 mock) | OS camera/screenshot policy |
|---|---|---|---|
| Persist locally | **MOCK** in-memory / stage prefs pattern | App access prefs (FS-003) for slug — **not** OS | **MISSING** |
| Reach child | **No** verified delivery | **No** (FS-003: app rules off PolicySyncBus) | **MISSING** |
| Device ack | **No** | **No** for app rules | **MISSING** |
| Offline enforceable | **No** | **No** OS | **MISSING** |
| Outbox/replay | **No** FS-004 outbox | ST bus only (adjacent) | **MISSING** |

---

## 3. Related buses (adjacent, not FS-004)

| Mechanism | Scope |
|---|---|
| `PolicySyncBus` | ScreenTimePolicy + schedules only |
| Web Filter prefs | Per-child filter — not capture |
| TimeRequest offline queue | Minutes decisions |

---

## 4. Offline honesty

Any future FS-004 L2 must follow global offline-first:

- No fake cloud success  
- `enforced` only with ack + verified plane  
- Last-acked evaluate offline  

**Not implemented for FS-004 today.**

---

## 5. Multi-device

No FS-004 per-device capability report or divergent ack UI.  
**MISSING.**
