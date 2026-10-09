# 03 — FS-004 Role Access Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-OD-11 · SC-SF-01…03  
**Vocabulary:** Primary Parent · Co-Parent Observer · Partner · Full · Child  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Hard rules

| Rule | Law |
|---|---|
| Configure FS-004 policy | **Primary + Co-Parent Full** only |
| Partner / Observer configure | **Forbidden** |
| Decide explicit exceptions / monitoring-related requests (where such tickets exist) | **Primary + Partner + Full** |
| Observer | **View-only** — status, honesty, policy summary |
| Child | **No configure**; mandatory transparency when monitoring active; permitted status only |
| RBAC only | Never device-possession AuthZ |
| Export evidence packs | Primary-leaning (SC-SF-03) |

---

## 2. Capability matrix

| Capability | Primary | Full | Partner | Observer | Child |
|---|:-:|:-:|:-:|:-:|:-:|
| View effective policy / honesty | ✅ | ✅ | ✅ | ✅ | transparency + status only |
| Edit family baseline / child override | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Configure camera restriction intent | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Configure capture prevention intent | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Configure screenshot monitoring + scope | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Configure sensitive-surface protection | ✅ | ✅ | ⛔ | ⛔ | ⛔ |
| Approve/deny FS-004 exception tickets* | ✅ | ✅ | ✅ | ⛔ | ⛔ |
| Request exception (if product offers) | — | — | — | — | ✅ where allowed |
| See monitoring transparency | — | — | — | — | ✅ when active |
| Edit Modes schedule | → Modes | → Modes | → Modes | → Modes | ⛔ |
| Edit FS-003 package Camera app | → FS-003 | → FS-003 | → FS-003 | → FS-003 | ⛔ |
| SOS | Always per SOS Final | Always | Always | Always | Trigger / own |

\* Ticket types (if any) are for **explicit** FS-004 exceptions / monitoring-related requests — not ST grants, not WF unlocks, not mic.

---

## 3. Child authority

| Allowed | Forbidden |
|---|---|
| Persistent monitoring transparency when configured active | Admin / lists / policy edit |
| See deny/status for blocked camera/capture where shown | Silent surveillance without disclosure |
| Reach SOS / Required Chat / Quran | SOS audio (does not exist) |
| Use explicit Family OS camera exceptions when policy allows | Bypass OS camera restrict silently |

---

## 4. Audited role actions

Policy save · monitoring on/off · scope change · prevention toggles · exception decide · plane state transitions · observed capture events (when monitoring actually observes).
