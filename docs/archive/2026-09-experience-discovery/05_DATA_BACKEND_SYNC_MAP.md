# 05 — Data, Backend, Sync Map (Family OS)

**Date:** 2026-09-23  

---

## 1. Design-time database contract (FACT — status D/E)

**File:** `family-os/_CONTRACTS/schema.sql`  
**Engine declared:** PostgreSQL 15+  

### Tables (20)

| Area | Tables |
|---|---|
| Identity / family | `account`, `family`, `member`, `child`, `invite`, `pairing_token` |
| Devices | `device`, `device_permission`, `device_health`, `mode_unlock_attempt` |
| Safety / location | `location_ping`, `geofence`, `geofence_event`, `sos_alert` |
| Comms | `conversation`, `message`, `call_log` |
| AI / audit | `ai_event`, `ai_suggestion`, `audit_log` |

### Notable enums

`member_role` OWNER/PARENT/GUARDIAN; `perm_level` OBSERVER/PARTNER/FULL; `device_mode` PARENT/CHILD_LOCKED/CHILD_PREVIEW; permission keys include LOCATION_*, ACCESSIBILITY, USAGE_STATS, SCREEN_TIME_IOS, etc.

**Runtime usage of this schema in the Flutter app:** **NOT FOUND** (no Postgres driver, no migrations runner in app).

Duplicate design copy also exists at `prototype/_CONTRACTS/schema.sql` (supporting).

---

## 2. App-side persistence (FACT)

| Mechanism | Present? | Evidence |
|---|---|---|
| SharedPreferences package | **No** | `pubspec.yaml` |
| sqflite / drift / hive / isar | **No** | deps + grep |
| Memory `Map<String,String>` prefs stores | **Yes** | e.g. `MemoryScreenTimePolicyPrefsStore` |
| InMemory repositories | **Yes** | Dominant pattern |
| Stage-1 singleton audit | **Yes** | `stage1AuditLogRepository` |
| Secure storage / Keystore | **No** | NOT FOUND |

**Conclusion:** Process memory only. Kill app → state lost (unless a future adapter is added).

---

## 3. Backend / API (FACT)

| Item | Status |
|---|---|
| HTTP client (`http`, `dio`) | H NOT FOUND |
| Firebase Auth / Firestore / FCM | H NOT FOUND |
| GraphQL / gRPC | H NOT FOUND |
| `API_CONTRACT.md` feature rows | Essentially empty table |
| `backend/` or `server/` folders | H NOT FOUND |

---

## 4. Sync / offline (FACT — mock)

| Construct | Path | Behavior | Status |
|---|---|---|---|
| PolicySyncBus | `core/policy/policy_sync_bus.dart` | Same-session parent→child schedule/policy mirror; pending/delivered/offlineQueued statuses | F/A in-process |
| DesiredMonitoringSyncBus | `desired_monitoring_sync_bus.dart` | Monitoring prefs bus | F |
| PrivacyCollectionSyncBus | `privacy_collection_sync_bus.dart` | Collection scope mirror | F |
| SmartModeActivationBus | `smart_mode_activation_bus.dart` | Mode → child UI | F/A in-process |
| WebUnlockDecisionBus / TimeRequestDecisionBus / DeviceLockNotifyBus | various | Decision notify buses | F/A in-process |
| Network outbox / CRDT / conflict store | — | H NOT FOUND | H |

**Offline:** UI can show offline banners and queue *labels* in mock sync status; there is **no** durable outbox to a server.

---

## 5. AuthN / AuthZ (FACT)

| Concern | Reality | Status |
|---|---|---|
| Email/password account | Create/login screens mock navigate | F |
| Session tokens / refresh | NOT FOUND | H |
| Role authorization | `AppRole` + RoleGuard path redirects + MotherLevel for some actions | A (local) |
| Owner-only billing/privacy | RoleGuard sets | A (local) |

Schema intends `account.password_hash` — **not implemented** in app runtime.

---

## 6. Notifications pipeline (FACT)

- Prefs model + `NotificationDelivery.shouldDeliver` rules (critical/SOS always).  
- Simulation helpers (e.g. simulate SOS / analysis notify) in tests/screens.  
- **No** OS notification channel / FCM integration found.

---

## 7. Location / geofence data (FACT)

- Schema tables exist (D/E).  
- App: InMemory location/history/safe-zone repositories + map **UI**.  
- **No** geolocator / Google Maps / Mapbox dependency in pubspec → **H** for real GPS.

---

## 8. Audit / events (FACT)

- Product `AuditLogRepository`: **append + load only** (R10).  
- In-memory list; seeded empty by default (Rule 23).  
- Schema `audit_log` / `ai_event` not wired to DB.

---

## 9. Service → data relationships (summary)

| Service | App data | Backend table (contract only) |
|---|---|---|
| Screen time policy | Memory prefs JSON | (future — not in wave-1 schema excerpt as dedicated table; policy may expand later) UNKNOWN mapping |
| SOS ladder / alerts | Memory | `sos_alert` |
| Chat | `chat_mock_store` / InMemory conversation | `conversation`, `message` |
| Calls | InMemory call repos | `call_log` |
| Devices | Fake seam | `device`, `device_permission`, `device_health` |
| AI suggestions | MockAdvisor / AiSuggestionRepository | `ai_suggestion` |
| Audit | InMemoryAuditLogRepository | `audit_log` |

---

## FACT / INFERENCE / UNKNOWN

- **FACT:** No runtime DB or network persistence in current app deps.  
- **FACT:** Sync buses are in-process ChangeNotifier/stream style.  
- **INFERENCE:** schema.sql is the intended server model for a later stage.  
- **UNKNOWN:** Whether education / screen-time wallet tables exist in later contract docs beyond wave-1 schema.sql.
