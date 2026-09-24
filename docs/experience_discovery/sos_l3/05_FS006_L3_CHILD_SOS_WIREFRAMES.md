# 05 — FS-006 L3 Child SOS Wireframes

**Authority:** RD-01 · OD-06 · OD-14 · OD-16 · delivery honesty  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

Stage-1 CHD-005/006 = evidence hosts only.

---

## W-C01 — SOS entry (IDLE)

```
┌──────────────────────────────────────────┐
│ [Always available]                       │
│                                          │
│         ( ● HOLD FOR SOS )               │
│      Release early = cancel hold         │
│                                          │
│ [Family Chat] [Quran]                    │
└──────────────────────────────────────────┘
```

Visible under Mode / ST expiry / lock / filter / camera restrict / offline.

---

## W-C02 — HOLDING

```
┌──────────────────────────────────────────┐
│ Holding… ████████░░  keep holding        │
│ Release to cancel                        │
└──────────────────────────────────────────┘
```

---

## W-C03 — FIRING

```
┌──────────────────────────────────────────┐
│ Creating emergency on this device…       │
│ Location: acquiring / unavailable OK     │
│ (Do NOT say “Parents notified”)          │
└──────────────────────────────────────────┘
```

---

## W-C04 — ACTIVE (Panic Quiet critical-only)

```
┌──────────────────────────────────────────┐
│ Emergency ACTIVE                         │
│ Delivery: queued / attempting / …        │
│ Location: ready | stale | unavailable    │
│ [Contact parents]                        │
│ [False alarm — cancel…]                  │
│ [Family Chat] [Quran]                    │
└──────────────────────────────────────────┘
```

**No:** break-glass · escalate config · entertainment hub.

---

## W-C05 — False-alarm confirm

```
┌──────────────────────────────────────────┐
│ Cancel emergency?                        │
│ This tells parents it was a false alarm  │
│ [Keep active] [Confirm false alarm]      │
└──────────────────────────────────────────┘
```

---

## W-C06 — Offline

```
┌──────────────────────────────────────────┐
│ Emergency saved on this device           │
│ Delivery: offline queued                 │
│ Will retry when connected                │
│ [SOS still active]                       │
└──────────────────────────────────────────┘
```
