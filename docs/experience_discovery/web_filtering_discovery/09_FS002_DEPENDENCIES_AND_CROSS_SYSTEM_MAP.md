# 09 — FS-002 Dependencies & Cross-System Map

**Rule:** Flag ownership ambiguity — do not resolve product ownership here.

---

## 1. Dependency map

```
                    ┌─────────────────────┐
                    │  Identity / ChildId │
                    └─────────▲───────────┘
                              │ keys policy
┌──────────────┐     ┌────────┴────────┐     ┌──────────────────┐
│ FAT-036 UI   │────▶│ WebFilterPolicy │◀────│ WebUnlockService │
│ WebBlockPage │     │ + Evaluator     │     │ allowList mutate │
└──────────────┘     └────────┬────────┘     └────────▲─────────┘
                              │                         │
                              │ (no OS bridge)          │ AuthZ
                              ▼                         │
                     ┌────────────────┐         ┌───────┴────────┐
                     │  MISSING: VPN/ │         │ MotherLevel /  │
                     │  DNS/DO agent  │         │ WebUnlockActor │
                     └────────────────┘         └────────────────┘

Adjacent (not proven coupled):
  Screen Time / TimeEngine …… independent gate (docs)
  Smart Modes ………………… ambiguity if modes should override filter
  Anti-tamper / VPN toggle … separate; not evaluator input
  Notifications …………… bus ≠ FCM
  AuditLogRepository …… vs AuditAppend ambiguity
  Platform monitoring UI … capability claims
  Location FS-001 ………… independent (Location L2)
  SOS ……………………… must not be blocked by filter (not coded either way)
  FAT-078 Router ………… mock DNS; ownership vs on-device filter unclear
```

---

## 2. Named system boundaries

| System | Relationship to CURRENT web filter | Ambiguity? |
|---|---|---|
| **Policy Kernel / TimeEngine** | Docs: orthogonal gate; no Minutes spend on filter deny | Low — docs clear; code separate |
| **Family Identity / AuthZ** | ChildId keys; role gates uneven (edit vs unlock) | **Yes** — Mother Full edit |
| **FS-001 Location** | Independent | No |
| **FS-003 App/System Control** | Adjacent parental control; not same evaluator | **Yes** — future “which plane blocks YouTube app vs URL” |
| **FS-005 Modes** | Smart modes may restrict apps; filter interaction **not coded** | **Yes** |
| **FS-007 Offline AI** | No coupling found | — |
| **Notifications** | Unlock bus only | **Yes** — who owns parent alert channels |
| **SOS** | Must remain available (constitution); filter must not gate SOS — **no code asserting this** | Soft ambiguity |
| **Audit / Event infrastructure** | Unlock uses `AuditAppend` | **Yes** — vs R-10 audit log |
| **Device Health / monitoring** | Shows webFilter desired/capability | Honesty vs reality |
| **Anti-tamper** | VPN-related product elsewhere | **Yes** — bypass resistance ownership |
| **Home router FAT-078** | Same feature folder; mock DNS | **Yes** — on-device vs home network ownership |

---

## 3. Event / sync buses

| Bus | Web-filter use |
|---|---|
| `WebUnlockDecisionBus` | Child toast same process |
| `PolicySyncBus` (screen time) | **Not verified** for WFP push |
| Family EventBus / AI hooks | **Not verified** for browse events |

---

## 4. External dependencies (absent)

Firebase, map/DNS vendors, VPN SDK, Device Admin SDK — **not** in web-filter path.

---

## 5. Discovery implication

FS-002 cannot be “done” as a safety product without an explicit future decision on **enforcement plane ownership** (device agent vs router vs both) and **AuthZ alignment** (Mother Full configure). Those are **future Owner/design** items — not resolved in this package.
