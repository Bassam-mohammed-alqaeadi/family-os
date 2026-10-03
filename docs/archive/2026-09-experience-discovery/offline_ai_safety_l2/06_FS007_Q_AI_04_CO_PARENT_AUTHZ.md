# 06 — Q-AI-04 Co-Parent AuthZ (FROZEN)

**System:** FS-007 — Offline AI Safety  
**Question:** Q-AI-04  
**Status:** **CLOSED** — 2026-09-24  
**Maps to:** **AI-OD-04 = A**  
**Register:** [01_FS007_L2_OWNER_DECISIONS.md](01_FS007_L2_OWNER_DECISIONS.md)  
**Next:** [07_FS007_Q_AI_05_PARENT_RAW_CONTENT_VISIBILITY.md](07_FS007_Q_AI_05_PARENT_RAW_CONTENT_VISIBILITY.md)

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: IN PROGRESS — Q-AI-06 OPEN
FS-007 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## Owner freeze

**Choice: A — Co-Parent AuthZ bundle A**

### Binding matrix (AI-OD-04)

| Capability | Primary | Co-Parent Full | Co-Parent Partner | Co-Parent Observer | Child |
|---|---|---|---|---|---|
| Configure FS-007 safety tools | ✅ | ✅ | ❌ | ❌ | ❌ |
| Review safety tickets | ✅ | ✅ | ✅ | ❌ | ❌ |
| Receive safety notifications | ✅ | ✅ | ✅ | ❌ | ❌ |
| Make FS-007 configuration decisions | ✅ | ✅ | ❌ | ❌ | ❌ |

### Additional rules

- **RBAC only**; never infer authority from device possession.
- **Observer** remains view-limited and receives **no** FS-007 push notifications.
- **Partner** may review safety hits/tickets and receive notifications but **cannot** configure FS-007.
- **Child** has transparency rights only; no administration / configuration / review authority (transparency depth → **Q-AI-06**).
- **No new Primary-only action** invented in this decision.
- Sensitive destructive/privacy operations (family export / delete / wipe, etc.) remain governed by **already-frozen Primary-only global rules** where applicable — **not** reinterpreted as FS-007-specific authority.

### Preserved

AI-OD-01/02/03 = B · **AI-OD-03-GATE OPEN** · AI-SF-01…21 (+ registered SF-22…) · sibling ownership boundaries.

### Options not chosen

| Option | Status |
|---|---|
| B — Stricter Primary+Full review | **Rejected** |
| C — Primary-only configure | **Rejected** |
| D — Include Observer notifications | **Rejected** |
| E — Custom matrix | **Rejected** |

---

```
Q-AI-04 STATUS: CLOSED — AI-OD-04 = A
```
