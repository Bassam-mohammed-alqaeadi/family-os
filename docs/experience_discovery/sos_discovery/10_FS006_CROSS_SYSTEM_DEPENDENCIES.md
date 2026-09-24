# 10 — FS-006 Cross-System Dependencies

**Authority:** SOS Final · FS-001…FS-005 L2 · ST Final · Kernel  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Invariant checks

| System | Required | Repo / contract evidence | Result |
|---|---|---|---|
| **Screen Time** | SOS outside minutes/grants; not blocked by expiry | Exempt surfaces; OD-14 | **Contract PASS** · Stage-1 **PARTIAL** |
| **FS-005 Modes** | Modes cannot gate SOS | MODE-OD-14 · L3 always SOS | **PASS** |
| **FS-003** | Cannot deny SOS package; break-glass ≠ permanent rewrite | APP-OD-09 protected; APP boundaries | **PASS** contract; break-glass plane unlock **MISSING** |
| **FS-002** | Emergency not blocked by filter; no URL mutation from SOS | WF protected reachability patterns | **PASS** contract; no SOS→URL writer found (**good**) |
| **FS-004** | Reachability survives camera/capture; **no** SOS audio | SC-OD SOS Final; OD-11 | **PASS** — no audio reintroduced |
| **FS-001** | SOS may attach location; FS-001 owns facts/history | Location handoff docs | **PASS** ownership; live attach **PARTIAL/MOCK** |
| **Policy Kernel** | Interprets emergency facts; does not invent SOS domain | Boundary docs | **PASS** intent; typed facts **MISSING** |
| **Audit** | Lifecycle + break-glass auditable | Frozen RD-03 | Durable SOS audit **MISSING** |
| **Chat / Quran** | Remain reachable | Register + Modes/ST | **PASS** contract |

---

## 2. Break-glass vs other systems

Temporary allowlisted bypass only — must **not** silently mutate FS-002 lists, FS-003 Permanent Block, FS-004 permanent policy, ST wallets, FS-005 Mode definitions, roles, billing.

Stage-1 store does not mutate those stores (**good**) and does not yet apply temporary overrides to them (**gap**).

---

## 3. Modes temporary override

FS-005 L2: Modes never gate SOS. Emergency may temporarily override Mode **restrictions for response** only per break-glass allowlist — not Mode authorship. Stage-1: **not wired**.

---

## 4. Naming

FS-006 = this discovery system label for SOS within the FS sequence. Frozen pack remains `sos_final/` — **do not duplicate conflicting law**.
