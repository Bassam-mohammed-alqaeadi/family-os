# 01 — FS-006 Scope and Mission (Discovery)

**System label:** FS-006 — SOS / Emergency Safety System  
**Date:** 2026-09-24  
**Mode:** Evidence audit only — **no** L2 · **no** L3 · **no** app code  
**Product authority (frozen):** [`../sos_final/`](../sos_final/) · OD-01…OD-21 · RD-01…RD-05 · Q-SOS-RD-02A/02B/03A **CLOSED**  
**Adjacent frozen:** Identity · Policy Kernel · Offline-first · Audit/Events/Notifications · Screen Time Final · FS-001…FS-005 L2/L3  
**Evidence only (non-authority):** Stage-1 Flutter · prototype · historical `sos/` + `sos_screen_engineering/` packs · registry  

**Entry:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

```
FS-006 DISCOVERY: COMPLETE
FS-006 L2 POLICY: NOT STARTED
FS-006 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## 1. Mission

Inventory **repository evidence** against **frozen SOS Final** for the emergency safety path:

activation · panic/quiet · break-glass · evidence · escalation · contacts · location attachment · SMS/call fallbacks · offline · multi-device · ack · cancel/false alarm · parent/co-parent response · notifications · audit · policy precedence · cross-system reachability · persistence · sync · native capabilities · mocks · tests · schema.

**SOS is a safety path, not ordinary parental-control policy.**

---

## 2. Authority rule (critical)

| Layer | Role |
|---|---|
| `sos_final/` | **Frozen product law** — do **not** reopen OD/RD as new Q-SOS |
| This `sos_discovery/` | Evidence classification + gap/contradiction register vs frozen law |
| Stage-1 code | CURRENT FACT / MOCK — not target proof of delivery |
| Register P-4 “audio/siren” wording | Superseded by SOS Final **OD-11 audio EXCLUDED** where they conflict |

New **Q-SOS-*** only if a **demonstrated platform impossibility** forces Owner thaw — otherwise **none**.

---

## 3. Critical invariants to verify (not redesign)

- Reachable under ST · FS-002 · FS-003 · FS-004 · FS-005 · lock · subscription  
- No silent permanent policy mutation from emergency / break-glass  
- Break-glass temporary · audited · auto-revoke (frozen lifecycle)  
- AI suggests only; no autonomous emergency policy execution  
- **No** reintroduction of SOS audio/video  

---

## 4. Explicit non-goals

| Non-goal |
|---|
| Reopening OD-01…21 / RD-01…05 |
| Selecting SMS/FCM/AlarmManager as product mechanism |
| Inventing durations/TTLs beyond frozen retention numbers |
| L2 / L3 / wireframes / Flutter changes |
| Claiming Stage-1 mock fire = real emergency delivery |

---

## 5. Document index

| # | File |
|---|---|
| 01 | this file |
| 02 | [02_FS006_CURRENT_REPO_EVIDENCE.md](02_FS006_CURRENT_REPO_EVIDENCE.md) |
| 03 | [03_FS006_CAPABILITY_INVENTORY.md](03_FS006_CAPABILITY_INVENTORY.md) |
| 04 | [04_FS006_SOS_POLICY_AND_AUTHZ_DISCOVERY.md](04_FS006_SOS_POLICY_AND_AUTHZ_DISCOVERY.md) |
| 05 | [05_FS006_EMERGENCY_LIFECYCLE_DISCOVERY.md](05_FS006_EMERGENCY_LIFECYCLE_DISCOVERY.md) |
| 06 | [06_FS006_BREAK_GLASS_AND_PANIC_DISCOVERY.md](06_FS006_BREAK_GLASS_AND_PANIC_DISCOVERY.md) |
| 07 | [07_FS006_OFFLINE_SYNC_AUDIT.md](07_FS006_OFFLINE_SYNC_AUDIT.md) |
| 08 | [08_FS006_EVENTS_AUDIT_NOTIFICATIONS.md](08_FS006_EVENTS_AUDIT_NOTIFICATIONS.md) |
| 09 | [09_FS006_EVIDENCE_AND_ESCALATION_DISCOVERY.md](09_FS006_EVIDENCE_AND_ESCALATION_DISCOVERY.md) |
| 10 | [10_FS006_CROSS_SYSTEM_DEPENDENCIES.md](10_FS006_CROSS_SYSTEM_DEPENDENCIES.md) |
| 11 | [11_FS006_GAP_AND_CONTRADICTION_REGISTER.md](11_FS006_GAP_AND_CONTRADICTION_REGISTER.md) |
| 12 | [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md) |
