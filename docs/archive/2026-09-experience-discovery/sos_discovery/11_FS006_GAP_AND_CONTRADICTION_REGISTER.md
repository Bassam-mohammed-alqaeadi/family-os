# 11 — FS-006 Gap and Contradiction Register

**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## A. Contradictions

| ID | Left | Right | Disposition |
|---|---|---|---|
| **SOS-C-01** | Register P-4 “audio broadcast / siren” language | SOS Final **OD-11 audio EXCLUDED** | **Frozen SOS Final wins** — do not reopen; Stage-1 has no audio (correct) |
| **SOS-C-02** | UI/copy implies piercing live delivery | Mock fire / simulate notifications | Label as **MOCK** — honesty debt |
| **SOS-C-03** | Historical `sos/01` said ACK status missing | Current `SosAlertStatus.acknowledged` exists | **Resolved in code** since prior truth — record drift |
| **SOS-C-04** | Schema sos_status 3 values | App has escalating too | Model richer than SQL — **T-SOS** schema align |
| **SOS-C-05** | FAT-028 “any navigator can edit” (old truth) | OD configure = Primary+Full | **AuthZ gap** — implementation debt |

No contradiction requires new Owner Q — thaw only for proven platform impossibility (none demonstrated here).

---

## B. Gaps (implementation vs frozen)

| ID | Gap | Severity |
|---|---|---|
| **SOS-GAP-01** | No real SMS/call/push critical delivery | Critical |
| **SOS-GAP-02** | No durable persist/outbox/multi-device | Critical |
| **SOS-GAP-03** | No evidence pack / retention jobs | High |
| **SOS-GAP-04** | Break-glass does not drive temporary plane unlock | High |
| **SOS-GAP-05** | No escalation timer worker | High |
| **SOS-GAP-06** | No live FS-001 location bind to incident | High |
| **SOS-GAP-07** | No durable append-only SOS audit pipeline | High |
| **SOS-GAP-08** | Native Android SOS agent absent | High |
| **SOS-GAP-09** | Panic Quiet critical-only shell incomplete | Medium |
| **SOS-GAP-10** | Contact verification transport unproven | Medium |
| **SOS-GAP-11** | Offline airplane fire unproven | Medium |
| **SOS-GAP-12** | Typed FamilyEvents missing | Medium |

---

## C. Owner questions (Q-SOS)

**None opened.**

All product decisions remain frozen in `sos_final/`. Do not recreate OD/RD as Q-SOS-01….

---

## D. Technical questions (T-SOS) — OPEN

| ID | Topic |
|---|---|
| **T-SOS-01** | SMS fallback feasibility / provider / dual-SIM honesty |
| **T-SOS-02** | Emergency delivery channels (FCM/APNs critical, in-app) after verification |
| **T-SOS-03** | Background execution / process death / OEM battery limits |
| **T-SOS-04** | Native notification / DND pierce behavior per OS |
| **T-SOS-05** | Location attachment pipeline to FS-001 facts (no ownership move) |
| **T-SOS-06** | Retry / replay / outbox algorithms |
| **T-SOS-07** | Offline persistence store (Drift vs other) — shape TBD |
| **T-SOS-08** | Acknowledgement delivery to multi-device |
| **T-SOS-09** | Evidence packaging + 90-day operational purge job |
| **T-SOS-10** | Backend emergency state / API wiring |
| **T-SOS-11** | Platform unsupported / degraded matrix per OEM |
| **T-SOS-12** | Schema alignment (escalating status, break-glass tables) |
| **T-SOS-13** | Break-glass temporary override hooks into Kernel/planes without permanent mutation |
| **T-SOS-14** | Escalation timer / verification transport ports |

**Do not select mechanisms in Discovery.**
