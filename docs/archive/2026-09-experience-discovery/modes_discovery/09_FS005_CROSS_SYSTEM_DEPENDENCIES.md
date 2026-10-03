# 09 — FS-005 Cross-System Dependencies

**Mode:** Map Modes ↔ other frozen systems. Do not move ownership silently.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Dependency diagram (discovery)

```
                    ┌─────────────────────┐
                    │   Policy Kernel     │
                    │   TimeEngine merge  │
                    └──────────▲──────────┘
                               │ mode facts / flags
          ┌────────────────────┼────────────────────┐
          │                    │                    │
   ┌──────┴──────┐      ┌──────┴──────┐      ┌──────┴──────┐
   │ FS-005 Modes│      │ Screen Time │      │ Instant Lock│
   │ (target?)   │      │ S1 windows  │      │ / FS-003    │
   └──────┬──────┘      └─────────────┘      └─────────────┘
          │
    ┌─────┼─────┬──────────┬──────────┐
    │     │     │          │          │
 FS-002 FS-003 FS-004   FS-001     SOS
 tighten  tighten tighten consume  never
 only*    only*   only*   location gated
```

\* Sibling L2 stance — **FS-005 L2 not started**.

---

## 2. Explicit checks (brief)

### FS-003 Application Control

| Rule | Evidence |
|---|---|
| Modes may provide contextual app restrictions | TimeEngine `deniedMode`; allow-list store **MISSING** |
| Modes must not duplicate package policy | `AppAccessRuleSet` separate; Modes prefs lack package rules — **good absence**, incomplete overlay |
| Modes must not create second AC scheduler | No AC package scheduler found |
| Risk | If Modes grow package Allow/Block editors → violation |

### FS-002 Web Filtering

| Rule | Evidence |
|---|---|
| Modes may tighten filter | WF-OD-13 documented; **no code** |
| Modes must not rewrite URL lists | No mode→list writer found — **good absence** |

### FS-004 Screen & Camera

| Rule | Evidence |
|---|---|
| Modes may tighten | L2; **no camera facet** on modes |
| Modes must not permanently remove | No removal path found |

### Screen Time

| Rule | Evidence |
|---|---|
| Do not duplicate minutes/grants/wallets/Unlimited | Modes prefs do not store wallets — **good** |
| Risk | **S1 ScheduleWindow** already produces `modeActive` under ST ownership |

### FS-001 Location

| Rule | Evidence |
|---|---|
| Interact without moving geofence ownership | S-SEC-059 claimed; **no wire**; geofence ownership stays Location |

### SOS

| Rule | Evidence |
|---|---|
| Reachable regardless of Mode | ST final + Register P-4; child surfaces keep SOS |

### Policy Kernel

| Rule | Evidence |
|---|---|
| Modes = contextual facts/overlays; Kernel merges | Flags today; typed mode-context fact **MISSING** (**T-MODE-08**) |

---

## 3. Consumers of mode state today

| Consumer | How |
|---|---|
| CHD-004 | Activation bus UI |
| TimeEngine (when fed) | `modeActive` / allow / exception |
| ScheduleWindowQuery | **Produces** mode-like context from ST windows |
| FS-002/003/004 L3 chips | Documented deep-links — not Flutter |

---

## 4. Naming collisions (not FS-005)

| Symbol | Meaning |
|---|---|
| `device_mode` | Parent/child device linking |
| Child Mode Lock | PIN / lock UX |
| Trial mode / device mode onboarding | Onboarding |
| Family UI mode | Design chrome |

Do not confuse with lifestyle Smart Modes.
