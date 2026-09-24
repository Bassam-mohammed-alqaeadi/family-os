# 07 — FS-006 L3 Break-Glass and Panic Quiet UX

**Authority:** RD-01 · RD-02 · SOS-RD-02A/B  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

---

## 1. Break-glass sheet (Primary / Full)

```
┌──────────────────────────────────────────┐
│ Temporary break-glass                    │
│ NOT permanent · NOT unlock-everything    │
│ Affects (allowlist):                     │
│  · Lock/shell response                   │
│  · ST / web / app barriers for response  │
│  · Emergency comms · SOS+location context│
│  · Parent SOS notification handling      │
│ Does NOT: clear Permanent Block · rewrite│
│  URL lists · Modes · wallets · billing   │
│ Reason: [________________________]       │
│ Expires: (Final duration semantics)      │
│ [Cancel] [Confirm temporary override]    │
└──────────────────────────────────────────┘
```

### Active banner

```
Break-glass ACTIVE · expires … · [View audit]
Auto-revokes — no permanent policy change
```

### Forbidden presentations

- “Unlock all apps forever”  
- Child-facing break-glass  
- Partner/Observer invoke  
- Device-owner AuthZ copy  

Lifecycle UX mirrors: START → REASON → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT.

---

## 2. Panic Quiet

| Surface | Behavior |
|---|---|
| Setup (Primary/Full) | Toggle + explanation: child critical-only during ACTIVE |
| Child ACTIVE | Hide entertainment/time chrome that would suppress SOS |
| Always keep | SOS status · contact · location honesty · cancel · Chat · Quran |

---

## 3. Stage-1

In-memory BG sheet = evidence; L3 requires durable audit + real temporary override honesty (T-SOS-13) without claiming mechanisms.
