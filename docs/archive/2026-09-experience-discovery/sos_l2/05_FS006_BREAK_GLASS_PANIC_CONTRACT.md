# 05 — FS-006 Break-Glass and Panic Contract (L2 Wrapper) — FROZEN

**Status:** **FROZEN** — imports RD-01 · RD-02 · OD-12 · OD-13 · Q-SOS-RD-02A/02B  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Break-glass lifecycle (exact)

```
START → REASON → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT
```

| Aspect | Law |
|---|---|
| Who | **Primary Parent + Co-Parent Full** only |
| Not | Partner · Observer · Child |
| AuthZ | RBAC only — never device ownership |
| Requires | Reason / context |
| Duration | Temporary; auto-expiry + auto-revoke (exact minutes = not reinvented beyond Final) |
| Audit | Append-only break-glass events |

---

## 2. Allowlist (temporary bypass — frozen RD-02B)

May temporarily assist emergency **response** for:

- Lock / restricted shell  
- Screen-time response blockers  
- Web/app barriers for emergency response communications  
- Emergency communication surface  
- Active SOS + location context  
- Parent SOS notification handling  

---

## 3. Forbidden (never)

- Permanent policy / role / billing changes  
- Disable SOS or audit  
- Delete incidents / evidence  
- Privacy / audit bypass  
- Permanent exceptions  
- Unlock-everything  
- Rewrite FS-002 URL lists  
- Clear FS-003 Permanent Block  
- Permanently weaken FS-004  
- Mutate FS-005 Mode definitions  
- Mutate ST wallets/minutes authorship  
- Child SOS create path  

Break-glass is **temporary override**, not permanent mutation. Kernel may interpret temporary override facts; domains keep permanent stores intact.

---

## 4. Panic Quiet (RD-01 / OD-12)

During active SOS, child UI is **emergency-critical only** (status, contact, location honesty, cancel path). Entertainment / time / lock chrome must not suppress SOS.

Config of Panic Quiet = Primary + Co-Parent Full only.

---

## 5. Stage-1

In-memory break-glass session = evidence only. Not proof of plane unlock or durable audit.
