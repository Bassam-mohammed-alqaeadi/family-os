# Emulator Runbook: Staging Verification & Smoke Test Matrix

> **Truth & Platform Classification**:
> - **Execution Target**: Android Emulators (`emulator-5554` for Parent / Guardian, `emulator-5556` for Child).
> - **Hardware Distinction**: These tests execute on **Android Virtual Devices (Emulators)**, NOT on physical production hardware. No entry in this document shall be classified as "real device" verification.
> - **Backend Target**: Render Staging API (`https://family-os-staging-api.onrender.com`) with PostgreSQL.
> - **Authority Guard**: Only the system owner (**Taha**) may mark result cells as passed. All status cells are initialized to `⬜ Pending Owner Verification`.

---

## 1. Test Environment Setup & Pre-requisites

1. **Host & Emulators**:
   - `emulator-5554` (Parent/Guardian instance): Android API 33/34, standard portrait mode.
   - `emulator-5556` (Child instance): Android API 33/34, mock location provider configured in developer options.
2. **Build Artifact**:
   - Build compiled from branch `arena/53f92bb1-family-os` targeting staging origin `https://family-os-staging-api.onrender.com`.
3. **Accounts**:
   - Dedicated staging test credentials prefixed with `TEST-` (e.g., `TEST-parent@staging.familyos.local`).

---

## 2. Baseline Continuity: ف١ Verification (Owner Reference)

*Note: Baseline items (F1.1–F1.9) were verified on 2026-10-20 on emulators. They are cataloged here for re-verification if shared core files are altered.*

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| B.1 | `emulator-5554` & `5556` | Install APK and launch application | Boots into Foundation Gate / Welcome screen without crash; connects to Render staging API | ⬜ | F1.1 baseline |
| B.2 | `emulator-5554` | Sign in with Parent test account | Authenticates against Firebase Auth + Render PostgreSQL (`usesRemoteIdentity == true`) | ⬜ | F1.2 baseline |
| B.3 | `emulator-5554` | Open or create family (`TEST-Family`) | Family details persist and retrieve truthfully from PostgreSQL | ⬜ | F1.3 baseline |
| B.4 | `emulator-5554` | Add child profile (`TEST-Child`) | Child record created; child card renders in roster | ⬜ | F1.4 baseline |
| B.5 | `emulator-5556` | Complete child pairing via server code | Child links successfully; persistent Android notification appears: "مشاركة الموقع نشطة" | ⬜ | F1.5 baseline |
| B.6 | `emulator-5554` | Inspect child profile screen | Real battery level and handset telemetry display without mock values | ⬜ | F1.6 baseline |
| B.7 | `emulator-5554` | Tap "Revoke Device" or delete child | `POST /v1/devices/{id}/revocation` succeeds; child background service stops; child app receives broadcast and transitions to exit toast | ⬜ | F1.7 baseline |
| B.8 | `emulator-5556` | Verify child lock / safety state | Emergency SOS button visible; restricted navigation prevented | ⬜ | F1.8 baseline |
| B.9 | Both | Audit data on both screens | Zero synthetic/mock fallback names ("ابن ١", "ابن ٢"); 100% data read from PostgreSQL | ⬜ | F1.9 baseline |

---

## 3. Stage S1 Smoke Checks: Notification Delivery & Preferences

*Prerequisite: FCM credentials configured on Render staging (`FAMILY_PUSH_FCM_PROJECT_ID`).*

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| S1.1 | `emulator-5554` | Clean install & sign in as Guardian | App prompts for runtime notification permission; push token registered to `/v1/push-registrations` without duplicate rows | ⬜ | Delivery outbox |
| S1.2 | `emulator-5554` | Configure quiet hours (e.g., 22:00 - 07:00) in Notification Preferences | Preferences saved to PostgreSQL (`family_notification_preferences`); non-critical notifications silenced | ⬜ | Prefs table 122 |
| S1.3 | External / API | Trigger simulated SOS event for paired child via device API | Parent receives high-priority notification with loud sound, bypassing quiet hours; notification payload contains neutral text without raw coordinates | ⬜ | Safety override law |
| S1.4 | `emulator-5554` | Tap the SOS push notification | App opens directly to emergency incident details screen for the affected child | ⬜ | Router dispatch |
| S1.5 | `emulator-5554` | Switch app locale between Arabic and English | Notification channels and future push deliveries reflect the active locale strings | ⬜ | i18n proof |

---

## 4. Stage S2 Smoke Checks: Native Handset Resilience

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| S2.1 | `emulator-5556` | Open "What Is Collected" (`SCR-CHD-024`) | Protection status card renders "الحماية تعمل بالكامل" (green state) with active telemetry | ⬜ | ProtectionStateMachine |
| S2.2 | `emulator-5556` | Enable Airplane Mode on emulator for 15 minutes; trigger location ticks | Points are encrypted and spooled into `EncryptedFixQueueStore`; "نقاط مؤجلة" counter increments; zero crash | ⬜ | ResilientFixQueue |
| S2.3 | `emulator-5556` | Disable Airplane Mode (restore connectivity) | Spooled points flush to staging API in original chronological sequence; delayed counter returns to 0 | ⬜ | Outbox flush |
| S2.4 | `emulator-5556` | Adjust emulator clock +60 min, send point; adjust -60 min, send point | Backend records points with flag `stored_out_of_order`; timestamps preserved truthfully without rejection | ⬜ | ServerTimeOffset |
| S2.5 | `emulator-5556` | Simulate battery restriction via ADB (`dumpsys deviceidle force-idle`) | Protection card transitions to "الحماية تعمل جزئياً"; battery guidance button opens OEM exemption modal | ⬜ | BatteryOemMap |
| S2.6 | `emulator-5556` | Revoke location permission from Android OS Settings | Protection card immediately changes to "الحماية متوقفة"; guardian dashboard flags loss of tracking | ⬜ | Anti-deception rule |
| S2.7 | `emulator-5556` | Reboot emulator (`adb reboot`) | Foreground service automatically recovers on `BOOT_COMPLETED` without manual app launch | ⬜ | BootBackoff |

---

## 5. Stage S3 Smoke Checks: Server Minutes Economy

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| S3.1 | `emulator-5554` | Guardian views Child Wallet (`SCR-CHD-019`) | Balance displays truthful derived total from ledger rows; zero simulated mock balance | ⬜ | Wallet derivation |
| S3.2 | `emulator-5554` | Guardian grants 45 minutes of screen time | `POST /v1/children/{id}/minute-grants` succeeds; ledger appends new row; child balance updates in real-time | ⬜ | Migration 131 |
| S3.3 | `emulator-5554` | Log in as Co-Guardian; attempt to grant 45 minutes | Request is rejected with ceiling violation (co-guardian max is 30 minutes); 30-minute grant succeeds | ⬜ | Ceiling invariant |
| S3.4 | `emulator-5556` | Child completes Quran recitation / educational task | Islamic reward minutes credited to educational wallet; minutes cannot be spent to unlock generic entertainment apps | ⬜ | Invariant S-1 |
| S3.5 | `emulator-5556` | Child spends minutes on allowed app | Draw deductions follow strict order: daily allowance -> temporary expiring pool -> app wallet -> free wallet; balance never goes negative | ⬜ | FEFO/FIFO rule |
| S3.6 | `emulator-5554` | Primary guardian requests reversal of earlier grant | Reversal creates dedicated ledger row with audit reason; deducted amount cannot exceed unspent remainder | ⬜ | Reversal audit |

---

## 6. Stage S4 Smoke Checks: Live Map & Location Freshness

*Note: S4 checks require owner authorization before real GPS activation.*

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| S4.1 | `emulator-5554` | Open Child Live Map (`SCR-FAT-015`) | Real coordinates from child emulator render on interactive vector map; zero hardcoded Riyadh canvas fallback | ⬜ | No fake canvas |
| S4.2 | `emulator-5554` | Observe location freshness badge | Displays humanized relative time (e.g., "منذ دقيقتين"); updates truthfully as heartbeats arrive | ⬜ | Freshness indicator |
| S4.3 | `emulator-5554` | Tap "Refresh Location Now" (on-demand ping) | Command dispatched via spine / FCM; child handset awakes and posts fresh fix within 30s | ⬜ | On-demand fix |
| S4.4 | `emulator-5556` | Relocate mock location point via developer tool | Parent map pin transitions smoothly to new coordinate without page reload | ⬜ | Live stream |
| S4.5 | `emulator-5554` | Inspect retention info on map drawer | Displays truthful retention policy (`retentionDays: 90`) as configured on PostgreSQL backend | ⬜ | Retention truth |

---

## 7. Stage S5 Smoke Checks: Places, Geofence Alerts & Battery Thresholds

| # | Device | Action | Expected Result | Status | Notes |
|---|---|---|---|:---:|---|
| S5.1 | `emulator-5554` | Guardian creates Place geofence (e.g., "School", radius 200m) | Coordinates and radius persist to PostgreSQL table 102; geofence synchronizes to child runtime | ⬜ | Place creation |
| S5.2 | `emulator-5556` | Move mock location inside geofence boundary | `ENTER` geofence event triggers; parent receives notification: "TEST-Child وصل إلى المدرسه" | ⬜ | Geofence enter |
| S5.3 | `emulator-5556` | Move mock location outside geofence boundary | `EXIT` geofence event triggers; parent receives notification: "TEST-Child غادر المدرسه" | ⬜ | Geofence exit |
| S5.4 | `emulator-5556` | Simulate battery drop to 15% (`adb shell dumpsys battery set level 15`) | Child telemetry sends low-battery alert; parent receives prompt to contact child | ⬜ | Low battery rule |
| S5.5 | `emulator-5554` | Open audit log (`SCR-FAT-020`) | All geofence transitions and battery alerts appear in chronological order without missing timestamps | ⬜ | Audit continuity |

---

## 8. Owner Verification Log

| Date | Stage Tested | Build SHA / Run # | Emulators Tested | Verification Result | Owner Sign-Off |
|:---:|:---:|:---:|:---:|:---:|:---:|
| — | — | — | `emulator-5554`, `emulator-5556` | ⬜ Pending Run | — |
