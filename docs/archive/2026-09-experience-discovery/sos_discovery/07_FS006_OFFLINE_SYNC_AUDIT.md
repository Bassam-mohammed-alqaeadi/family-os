# 07 — FS-006 Offline / Sync Audit

**Authority:** OD-17 · SOS Final failure/offline contract  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Frozen offline law (summary)

Local-first incident · persist · queue · retry · SMS/call fallbacks · **no false “sent”** · location fail still activates (OD-16).

---

## 2. Stage-1 reality

| Requirement | Class |
|---|---|
| Local incident create | **PARTIAL** (memory) |
| Durable persist across process death | **MISSING** |
| Outbox / replay | **MISSING** |
| Retry with honesty | **MISSING** |
| False “sent” guard in UI | **PARTIAL** (delivery class enums exist) |
| Offline fire on airplane | **UNKNOWN** (not device-proven) |
| Multi-device sync of incident | **MISSING** |
| Ack delivery to child device | **MISSING** as sync |
| Drift / SQL sos_alert | Schema **DOCUMENTED**; wire **MISSING** |

---

## 3. Classification

SOS offline-first is **contract-complete, implementation-thin**. Mock fire always succeeds — risks false confidence if UI says “sent” without delivery class honesty (FAT-018 components mitigate partially).
