# 06 — FS-006 L3 Parent SOS Wireframes

**Authority:** Role matrix · incident console · setup  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

---

## W-P01 — Readiness

```
┌──────────────────────────────────────────┐
│ SOS Readiness                            │
│ Channels: available / degraded / unknown │
│ Contacts verified: n/m                   │
│ Location attach: OK / limited            │
│ (No false “fully protected”)             │
└──────────────────────────────────────────┘
```

---

## W-P02 — Incident console (ACTIVE)

```
┌──────────────────────────────────────────┐
│ Emergency · Child A            [SOS]     │
│ Incident: ACTIVE                         │
│ Delivery (separate):                     │
│  Primary push: attempting                │
│  SMS fallback: queued                    │
│  Call: unavailable                       │
│ Location: acquiring → [Open Location]    │
├──────────────────────────────────────────┤
│ [Acknowledge] [Escalate] [Resolve]       │
│ [Break-glass…]  (Primary/Full only)      │
│ Observer: contact only — no ack/esc/res  │
├──────────────────────────────────────────┤
│ Recipients · Evidence · Audit            │
└──────────────────────────────────────────┘
```

**Forbidden:** “Delivered” without proof · national dial · A/V record · permanent policy editors.

---

## W-P03 — ACKNOWLEDGED / ESCALATING / RESOLVED

Same shell; lifecycle badge changes; RESOLVED shows retained history CTA (not delete).

---

## W-P04 — Setup (Primary/Full)

```
┌──────────────────────────────────────────┐
│ Emergency setup                          │
│ Rung-1: immutable parents                │
│ Backups (max 5) priority 1…5             │
│ Verify: unverified|pending|verified|…    │
│ Panic Quiet Mode [on/off]                │
│ Escalation enable/delays (Final semantics)│
│ Partner/Observer: read-only if opened    │
└──────────────────────────────────────────┘
```

---

## W-P05 — Delivery matrix detail

```
┌──────────────────────────────────────────┐
│ Delivery attempts                        │
│ Channel · recipient · state · time       │
│ Never equals “incident created”          │
└──────────────────────────────────────────┘
```

---

## W-P06 — Multi-device / offline

```
┌──────────────────────────────────────────┐
│ Devices                                  │
│ Child phone: ACTIVE · queued             │
│ Parent B: pending sync                   │
│ Offline honesty / retry                  │
└──────────────────────────────────────────┘
```

---

## W-P07 — Audit

Append-only list: fire · ack · escalate · resolve · cancel · break-glass — no edit/delete.
