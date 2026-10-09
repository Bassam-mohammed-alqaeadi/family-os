# 13 — FS-006 L3 Master Contract

# FS-006 SOS / EMERGENCY SAFETY — L3 UX COMPLETE

```
FS-006 DISCOVERY: COMPLETE
FS-006 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-006 L3: COMPLETE
IMPLEMENTATION: NOT AUTHORIZED
```

**Date:** 2026-09-24  
**Sole product law:** [`../sos_final/`](../sos_final/)  
**L2 wrapper:** [`../sos_l2/`](../sos_l2/)  
**Closure:** [12_FS006_L3_COVERAGE_AND_CLOSURE.md](12_FS006_L3_COVERAGE_AND_CLOSURE.md)

**App / sos_final modified:** **NO**  
**Q-SOS open:** **NONE**  
**T-SOS-01…14:** **OPEN / TBD**

---

## 1. Authority order

1. `sos_final/`  
2. `sos_l2/` wrapper  
3. **This `sos_l3/`** UX/behavioral spec  
4. Sibling L3 for deep-links  
5. Stage-1 code — evidence only  

---

## 2. Document index

| # | File |
|---|---|
| 01 | [01_FS006_L3_IA.md](01_FS006_L3_IA.md) |
| 02 | [02_FS006_L3_ROLE_MATRIX.md](02_FS006_L3_ROLE_MATRIX.md) |
| 03 | [03_FS006_L3_STATE_MATRIX.md](03_FS006_L3_STATE_MATRIX.md) |
| 04 | [04_FS006_L3_FLOW_CATALOG.md](04_FS006_L3_FLOW_CATALOG.md) |
| 05 | [05_FS006_L3_CHILD_SOS_WIREFRAMES.md](05_FS006_L3_CHILD_SOS_WIREFRAMES.md) |
| 06 | [06_FS006_L3_PARENT_SOS_WIREFRAMES.md](06_FS006_L3_PARENT_SOS_WIREFRAMES.md) |
| 07 | [07_FS006_L3_BREAK_GLASS_PANIC.md](07_FS006_L3_BREAK_GLASS_PANIC.md) |
| 08 | [08_FS006_L3_ESCALATION_DELIVERY.md](08_FS006_L3_ESCALATION_DELIVERY.md) |
| 09 | [09_FS006_L3_EVIDENCE_LOCATION.md](09_FS006_L3_EVIDENCE_LOCATION.md) |
| 10 | [10_FS006_L3_OFFLINE_HONESTY.md](10_FS006_L3_OFFLINE_HONESTY.md) |
| 11 | [11_FS006_L3_CROSS_SYSTEM_UX.md](11_FS006_L3_CROSS_SYSTEM_UX.md) |
| 12 | [12_FS006_L3_COVERAGE_AND_CLOSURE.md](12_FS006_L3_COVERAGE_AND_CLOSURE.md) |
| 13 | this file |

---

## 3. UX summary

| Area | Spec |
|---|---|
| Lifecycle | IDLE→HOLDING→FIRING→ACTIVE→ACKNOWLEDGED→ESCALATING→RESOLVED |
| Honesty | Incident ≠ delivery attempt ≠ delivered ≠ ACK |
| Child | Always-on entry · critical active · false-alarm confirm · Chat/Quran |
| Parent | Console · delivery matrix · setup · BG · evidence · audit |
| Break-glass | Temporary allowlist · reason · expiry · auto-revoke · audit |
| Panic Quiet | Critical-only child chrome |
| Exclusions | No audio/A/V · no national dial |
| Location | Attach honesty; FS-001 owns facts |
| Offline | Queue · retry · no fake cloud success |

---

## 4. Flows / wireframes

**F01–F16** · Child **W-C01…C06** · Parent **W-P01…P07**.

---

## 5. Implementation gate

Not authorized by L3 alone. Must not ship mock-as-delivered, Observer ack, audio, national dial, or permanent BG mutation.

---

## 6. Gate

```
FS-006 DISCOVERY: COMPLETE
FS-006 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-006 L3: COMPLETE
IMPLEMENTATION: NOT AUTHORIZED
```
