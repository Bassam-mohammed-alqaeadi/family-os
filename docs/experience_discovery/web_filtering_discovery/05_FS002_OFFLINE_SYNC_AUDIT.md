# 05 — FS-002 Offline & Sync Audit

---

## 1. What exists

| Behavior | Evidence | Class |
|---|---|---|
| Load/save policy via prefs store | `PrefsWebFilterPolicyRepository` | In-app persistence seam |
| Survive “restart” when sharing map in tests | Unlock/policy prefs tests | Test simulation |
| Unlock decision notify same isolate | `WebUnlockDecisionBus` | In-process only |
| policyVersion on decisions | Snapshot carries version | Stale-preview refresh story (UI-009) |

---

## 2. What does not exist (evidence)

| Behavior | Finding |
|---|---|
| Child device offline filter agent | **Missing** |
| Outbox for filter policy mutations | **Missing** |
| Cross-device sync ack for web filter | **Not verified** (unlike documented intent in `06-cross-role-dependencies.md`) |
| Honest “pending device sync” banner for filter save | **Not verified** on FAT-036 |
| Replay of unlock decisions after offline | **Missing** as durable multi-device queue |
| Cloud authoritative policy after sync | **Missing** (no backend) |

---

## 3. Documented intent vs code

Project plan / gap specs describe:

> Child uses **last-synced** filter offline; parent edits queue until child ack.

**Code reality:** last-loaded **in-app** prefs for whoever runs the Flutter process. There is no separate child-device runtime applying WFP to network stacks offline.

---

## 4. Offline honesty risk

If UI implies the child device is protected while offline **without** an installed enforcement agent, that would be a **product honesty violation** relative to Family OS offline laws used in SOS/Location — **flagged as risk**, not redesigned here.

---

## 5. Classification summary

| Topic | Class |
|---|---|
| In-app prefs | **Partial** |
| Multi-device offline enforcement | **Missing** |
| Sync/outbox | **Missing** |
| Same-process unlock bus | **Implemented (limited)** |
