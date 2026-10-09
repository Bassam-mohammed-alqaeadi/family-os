# 04 — Q-AI-02 Advisory vs Blocking (FROZEN)

**System:** FS-007 — Offline AI Safety  
**Question:** Q-AI-02  
**Status:** **CLOSED** — 2026-09-24  
**Maps to:** **AI-OD-02 = B**  
**Register:** [01_FS007_L2_OWNER_DECISIONS.md](01_FS007_L2_OWNER_DECISIONS.md)  
**Next:** [05_FS007_Q_AI_03_AUTO_TICKETS_ALERTS.md](05_FS007_Q_AI_03_AUTO_TICKETS_ALERTS.md)

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: IN PROGRESS — Q-AI-06 OPEN
FS-007 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## Owner freeze

**Choice: B — Advisory + automatic parent notification and/or review ticket**

### Binding law (AI-OD-02)

An FS-007 safety classification **may automatically**:

- create a **parent-facing safety notification**;
- create a **review ticket** where the later ticket policy permits;

but it **may NOT**, by classification alone:

- deny content;
- block/unblock packages;
- rewrite FS-002 URL/keyword lists;
- mutate FS-003 App Control policy;
- activate/deactivate or rewrite FS-005 Modes;
- permanently change family policy;
- trigger or escalate SOS.

The classification remains a **typed safety signal/fact**, not a policy decision.

### Explicitly deferred (not invented here)

| Deferred | Owner |
|---|---|
| Confidence thresholds | **Q-AI-03** (and must not be invented by agents) |
| Whether every hit auto-tickets vs gated | **Q-AI-03** |
| Notify vs ticket split rules | **Q-AI-03** |
| Escalation catalog detail | **Q-AI-09** |

### Preserved structural law

**AI-SF-04 · AI-SF-05 · AI-SF-06** (updated for notify/ticket contracts) · sibling ownership **AI-SF-07…11** · **AI-SF-22**.

### Options not chosen

| Option | Status |
|---|---|
| A — Pure advisory (review-only) | **Rejected** |
| C — Bounded automatic effects | **Rejected** |
| D — Other | **Rejected** |

---

## Pre-freeze options archive (non-authority except chosen B)

### A — Pure advisory *(rejected)*

Review-only; no auto notify/ticket/deny.

### B — Advisory + auto notify/ticket *(CHOSEN)*

Notify/ticket allowed; no auto-enforce. See AI-OD-02 above.

### C — Bounded automatic effects *(rejected)*

Named Kernel auto-effects beyond notify/ticket.

### D — Other *(rejected)*

---

```
Q-AI-02 STATUS: CLOSED — AI-OD-02 = B
```
