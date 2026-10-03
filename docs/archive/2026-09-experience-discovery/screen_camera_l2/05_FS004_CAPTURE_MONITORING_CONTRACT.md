# 05 — FS-004 Capture Monitoring Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · SC-OD-01 · SC-OD-03 · SC-OD-09 · SC-OD-10 · SC-SF-15  
**Non-authority:** FAT-065 in-memory toggle · missing Flutter app picker  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Ownership (SC-OD-09)

| Concern | Owner |
|---|---|
| Screenshot / capture **monitoring policy & domain semantics** | **FS-004** |
| Configuration source of truth | **FS-004 only** — **no duplicate** Smart Alerts policy |
| Smart Alerts / FAT-065 | Optional **presentation / entry / notification** surface only |
| Capture **prevention** | Separate prevent pillar (contracts 02/04/06) — may coexist |

---

## 2. Product rules

| Rule | Law |
|---|---|
| Monitoring must be **explicitly configured** | No silent default surveillance |
| **Child transparency mandatory** when active | SC-OD-10 — persistent/clear; no admin |
| Scope | Configured targets (e.g. app list) — storage **T-SC-05**; not full open-app stream by default (SC-SF-15) |
| Platform support | Only claim observation where plane can provide it (SC-OD-03/04) |
| Cross mutation | Must not write FS-003 / WF / ST policies |

---

## 3. Lifecycle (conceptual)

```
Configure monitoring (Primary/Full)
  → policyVersion++
  → deliver / ack on child devices
  → Child transparency ON while active
  → On observed capture (if agent capable): Domain fact → Kernel → notify/audit
  → Deactivate / scope change → transparency updates · audit
```

Agent implementation = **T-SC-04** (not selected).

---

## 4. Relationship to prevention

| Prevention active | Monitoring active | Meaning |
|---|---|---|
| Yes | No | Restrict capture where enforceable; no observation pipeline required |
| No | Yes | Observe configured captures; child informed |
| Yes | Yes | Both; honesty per capability independently |
| No | No | Baseline off |

Do not imply prevention from monitoring toggle alone.

---

## 5. Child transparency requirements

| Must | Must not |
|---|---|
| Clear statement that configured screenshot/capture monitoring is active | Silent monitoring |
| Update when monitoring turns off or scope changes | Child policy editor |
| Align with P-7 “protection without deception” spirit | Full forensic timeline as default child UI |

---

## 6. Events (minimum)

`sc_monitor.configured` · `sc_monitor.activated` · `sc_monitor.deactivated` · `sc_monitor.scope_changed` · `sc_capture.observed` (only when actually observed) · plane honesty transitions  

Detail: contract 08.

---

## 7. Non-adoptions

FAT-065 as second policy store · Prototype picker as final UX law · Full foreground surveillance default · Fake “observed” events without agent capability.
