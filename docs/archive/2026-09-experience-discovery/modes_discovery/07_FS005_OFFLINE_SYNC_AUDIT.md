# 07 — FS-005 Offline / Sync Audit

**Mode:** Evidence of offline-first and sync seams for Modes.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Register offline law

G-1: Offline-first with last synced family state + “last synced” indicator. Modes must participate eventually; Stage-1 is lean.

---

## 2. Current Modes sync surfaces

| Surface | Behavior | Durable? |
|---|---|---|
| `PrefsSmartModePrefsRepository` + `stage1SmartModePrefsStore` | Process-lifetime memory KV; JSON round-trip ready | **No** (Drift deferred by comment) |
| `SmartModeActivationBus.publish` | If child marked offline → `_queued`; online → deliver queued | In-process only |
| `hydrate` | Seed without counting as father toggle | In-process |
| CHD-004 offline | Keeps last local activation (SET-019) | Session |

---

## 3. What Modes do **not** use

| Seam | Used by | Modes? |
|---|---|---|
| `PolicySyncBus` (`schedule` / `policy`) | Screen Time schedules + caps | **No** mode activation events |
| FCM / push | Not proven platform-wide | **No** |
| Drift / outbox tables | Deferred / other domains | **No** FamilyMode |
| Device ack / policyVersion | Web/anti-tamper patterns elsewhere | **MISSING** for Modes |

---

## 4. Multi-device

| Scenario | Evidence |
|---|---|
| Father phone A activates → child phone | Same-process bus only in Stage-1 |
| Father phone A → father phone B | **MISSING** |
| Two children different modes | Prefs keyed by `childId` — model allows; family-wide apply **MISSING** |

---

## 5. Conflict / reconnect

Activation bus: on `markChildOnline`, deliver queued publish if any; else keep last local. **No** CRDT / version vector / ack TTL.

**T-MODE-04 / T-MODE-05** open.

---

## 6. Classification

| Capability | Class |
|---|---|
| Local last-known activation (session) | **PARTIAL** |
| Durable offline Modes store | **MISSING** |
| Outbox replay across process death | **MISSING** |
| Ack / stale honesty | **MISSING** |
| Sync with PolicySyncBus | **MISSING** (intentional gap or future merge — **T-MODE-04**) |
