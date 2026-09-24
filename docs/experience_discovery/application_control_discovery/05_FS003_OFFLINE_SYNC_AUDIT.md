# 05 — FS-003 Offline / Sync Audit

**Mode:** Evidence only. Separate **local UI persistence** from **child-device enforcement**.  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Questions this audit answers

Does app-control policy actually:

1. Persist locally?  
2. Reach the child device?  
3. Get acknowledged?  
4. Survive offline?  
5. Replay after reconnection?  
6. Remain enforceable offline?

---

## 2. Answers (CURRENT STATE)

| Question | App access rules (FS-003) | Screen time (adjacent) |
|---|---|---|
| Persist locally | **Yes** — parent-process prefs / memory store `app_access_rules:{childId}` | **Yes** — policy + schedules |
| Reach child device | **No** — not published on `PolicySyncBus` | **Simulated** same-isolate mirror |
| Device acknowledgement | **No** | **Simulated** `PolicySyncStatus` / `ChildPolicyMirror.lastAppliedAt` |
| Survive offline (child enforceable) | **No** | **Simulated** queue when `markChildOffline` |
| Replay after reconnect | **No** for app rules | **Yes (simulated)** for ST bus queue |
| Enforceable offline | **No** (no OS agent; no child mirror of rules) | In-app mirror only — still **not** OS |

---

## 3. PolicySyncBus scope (evidence)

Source: `app/lib/core/policy/policy_sync_bus.dart`

| Kind | Payload |
|---|---|
| `PolicySyncKind.policy` | `ScreenTimePolicy` |
| `PolicySyncKind.schedule` | `List<ScheduleWindow>` |

Status values: `pending | delivered | offlineQueued`.  
Comment in code: simulates push ack **without** Firebase/FCM.

**App access rules are NOT published on this bus.**

---

## 4. Outbox / replay inventory

| Mechanism | Scope |
|---|---|
| `PolicySyncBus._queue` | Screen-time policy + schedules when child “offline” |
| `TimeRequestService` offline decision queue | Parent approve/reject of **minutes** requests |
| App rule mutations (`setStatus` / `setUnlimited`) | Local prefs only — **no outbox** |

---

## 5. Versioning / acknowledgement

| Domain | Version field | Ack mirror |
|---|---|---|
| Web Filter | `WebFilterPolicy.policyVersion` | Snapshot carries version |
| Anti-tamper | `AntiTamperPolicy.policyVersion` | Prefs |
| Screen time | `updatedAt` on sync events | `ChildPolicyMirror` |
| App access rules | **None** | **None** |

---

## 6. Honesty gap

FAT-034 UX / tips may imply changes “reflect on the child device.”  
Evidence shows: **parent-local persistence only** + **no OS enforcement**.

Classification: **C** (claim vs delivery) for “reflects on child” language relative to CURRENT STATE.

---

## 7. Offline enforcement reality (one line)

**App-control offline reality = local parent UI state at best; not child-device, not OS, not acknowledged, not replayed.**

---

## 8. L2 decisions deferred

- Whether app rules join `PolicySyncBus` or a dedicated channel  
- Ack / version semantics  
- Offline deny defaults  

**Not decided in discovery.**
