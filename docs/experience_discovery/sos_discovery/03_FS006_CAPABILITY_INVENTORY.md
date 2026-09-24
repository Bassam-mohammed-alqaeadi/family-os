# 03 — FS-006 Capability Inventory

**Mode:** Evidence-only. Frozen SOS Final defines target law; this table classifies **repo reality**.  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

Classification: **IMPLEMENTED** · **PARTIAL** · **MOCK/SIMULATION** · **DOCUMENTED ONLY** · **MISSING** · **UNKNOWN**

---

## Matrix

| # | Capability | Class | Evidence |
|---|---|---|---|
| 1 | Named FS-006 discovery pack (pre-this) | **MISSING** | First pack under FS-006 label |
| 2 | Frozen SOS Final product contract | **DOCUMENTED ONLY** (authority pack) | `sos_final/` — not code |
| 3 | Child SOS entry (hold gesture) | **PARTIAL** | CHD-005 3s hold UI real; fire mock |
| 4 | Parent SOS incident console | **PARTIAL** | FAT-018 UI + mock repo |
| 5 | Panic / emergency trigger semantics | **PARTIAL** | Hold → fireAndSeed |
| 6 | Long-press / gesture | **IMPLEMENTED** (UI) | Timer hold |
| 7 | Break-glass Override | **PARTIAL** / **MOCK** | Domain + sheet; in-memory; no plane unlock |
| 8 | Panic Quiet Mode | **PARTIAL** | Settings/UI flags; child critical-only intent in eng docs |
| 9 | SOS Evidence Packs | **DOCUMENTED ONLY** / **MISSING** impl | OD-10 / RD-03; no export pack |
| 10 | Escalation ladder config | **PARTIAL** | Ladder model + FAT-028; memory store |
| 11 | Auto escalation timer | **MISSING** / **MOCK** | Manual escalate counter/status; no proven timer worker |
| 12 | Emergency contacts (trusted) | **PARTIAL** | Ladder backups + verification enum |
| 13 | Contact verification lifecycle | **PARTIAL** | Domain states; transport abstract / unproven |
| 14 | Location attachment | **PARTIAL** / **MOCK** | Labels + SosLocationClass; not live GPS bind |
| 15 | FS-001 location handoff | **DOCUMENTED ONLY** | Location L3 handoff; Stage-1 decorative map |
| 16 | SMS fallback | **MOCK** channel enum / **MISSING** send | channel string `sms`; no SMS API |
| 17 | Call fallback / auto-call | **MOCK** | Auto-call note / snackbar; no `tel:` |
| 18 | National emergency dial | **MISSING** (correct per OD-08) | Forbidden; tests assert no national |
| 19 | Push / critical notification | **MOCK** | simulateSosAlert |
| 20 | Network-offline fire | **UNKNOWN** / **DOCUMENTED** | OD-17; not device-proven |
| 21 | Device-offline persistence | **MISSING** durable | In-memory repos |
| 22 | Multi-device emergency state | **MISSING** | Process-local |
| 23 | Emergency acknowledgements | **PARTIAL** | `acknowledge` in repo; ACK≠RESOLVE coded |
| 24 | Cancel / false alarm | **PARTIAL** | Child cancel confirm components; audit depth thin |
| 25 | Parent response (ack/resolve/escalate) | **PARTIAL** | Role-gated UI + in-memory |
| 26 | Co-Parent response matrix | **IMPLEMENTED** (checks) / **PARTIAL** UI | `SosRoleActions` |
| 27 | Notifications honesty | **PARTIAL** | Delivery class enums in UI |
| 28 | Audit trail (append-only SOS) | **PARTIAL** / **MISSING** | Break-glass local audit list; no durable AuditAppend SOS pipeline |
| 29 | Evidence generation/export | **MISSING** | — |
| 30 | Policy bypass during emergency | **DOCUMENTED** + break-glass mock | Permanent mutation avoided in break-glass store |
| 31 | Reachable under ST expiry | **PARTIAL** | Exempt surfaces list |
| 32 | Reachable under Modes | **DOCUMENTED** (FS-005 L2/L3) | Modes never gate SOS |
| 33 | Reachable under FS-002/003/004 | **DOCUMENTED** sibling L2 | No SOS package deny |
| 34 | Chat / Quran reachability alongside SOS | **DOCUMENTED** / **PARTIAL** UI | Exempt triad elsewhere |
| 35 | Emergency state persistence (Drift/SQL) | **MISSING** | schema exists; not wired |
| 36 | Sync / outbox for SOS | **MISSING** | — |
| 37 | Backend emergency state | **DOCUMENTED ONLY** | API intent; no client |
| 38 | Native Android capabilities | **MISSING** | — |
| 39 | Platform unsupported honesty | **PARTIAL** | Location/delivery class UI |
| 40 | Readiness model UI | **PARTIAL** | `SosReadinessCard` |
| 41 | Incident ≠ delivery separation | **PARTIAL** | Separate enums on SosAlert |
| 42 | Audio/video evidence | **MISSING** (correct — forbidden) | OD-11 |
| 43 | Siren piercing DND (OS) | **DOCUMENTED ONLY** / **MOCK** copy | Not proven |
| 44 | Subscription ungated fire | **IMPLEMENTED** (seam) | Fire service no billing import; tests |
| 45 | Quiet hours mute SOS | **IMPLEMENTED** (forbidden) | Mute keys rejected; always deliver sim |
| 46 | AI autonomous SOS action | **MISSING** (correct) | No execute path found |
| 47 | Widget/unit tests SOS | **IMPLEMENTED** | Multiple test files |
| 48 | Parent SOS create (non-child) | **UNKNOWN** / thin | Primary path is child hold |
| 49 | Break-glass auto-revoke worker | **PARTIAL** | Lazy expiry on `active` getter; no durable worker |
| 50 | Max 5 backups / priority | **PARTIAL** | Ladder domain RD-05 spirit |
| 51 | Schema sos_alert | **DOCUMENTED** | SQL present |
| 52 | FCM / APNs critical | **MISSING** | — |
| 53 | Evidence 90d retention job | **MISSING** | Frozen law only |
| 54 | Indefinite audit retention | **MISSING** impl | Frozen law only |
| 55 | Panic Quiet suppresses entertainment UI | **DOCUMENTED** / **PARTIAL** | Eng docs; Stage-1 incomplete proof |
| 56 | Multi-recipient delivery rows | **MOCK** | SosDeliveryRow |
| 57 | Connection class honesty | **PARTIAL** | Enum + UI |
| 58 | Live map FAT-018 | **MOCK/SIMULATION** | Pin fractions |
| 59 | RoleGuard router on SOS | **PARTIAL** | Lean behaviors; FAT-028 AuthZ historically soft |
| 60 | FamilyEvent typed SOS events | **MISSING** | — |

**Capability rows counted:** **60**

---

## Rollup

| Bucket | Approx |
|---|---|
| IMPLEMENTED | 6 |
| PARTIAL | 22 |
| MOCK/SIMULATION | 12 |
| DOCUMENTED ONLY | 10 |
| MISSING | 8 |
| UNKNOWN | 2 |

**Real emergency delivery (SMS/call/push/OS critical):** **0 proven.**
