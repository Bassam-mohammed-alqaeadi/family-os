# 02 — FS-004 Current Repository Evidence

**Mode:** Evidence map only. Classifications: IMPLEMENTED · PARTIAL · MOCK/SIMULATION · DOCUMENTED ONLY · MISSING · UNKNOWN  
**Master:** [10_FS004_DISCOVERY_CLOSURE_REPORT.md](10_FS004_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Meta

| Item | Finding |
|---|---|
| Symbol / pack `FS-004` in repo | **MISSING** (before this folder) |
| `docs/family_os_blueprint/` | **MISSING** in workspace |
| Dedicated screen/camera control feature folder | **MISSING** |

---

## 2. Flutter / Dart evidence

### 2.1 Parental-adjacent (class B candidates)

| Artifact | Path | Classification |
|---|---|---|
| Mock child app row `id: 'camera'` (tools, free) | `app/lib/features/n03_screen_time/child_apps_mock.dart` | **MOCK/SIMULATION** |
| FAT-034 allow/block UI (can mark Camera blocked) | `app/lib/features/n03_screen_time/child_apps_screen.dart` | **MOCK/SIMULATION** — no OS enforce |
| Smart Alerts `screenshot` tool toggle | `app/lib/features/n08_platform/smart_alerts_repository.dart`, `smart_alerts_screen.dart` | **MOCK/SIMULATION** — memory toggle |
| `MonitoringFeature` enum (web/app/notification/location — **no camera/screenshot**) | `app/lib/core/policy/monitoring_feature.dart` | **PARTIAL** — omits P-7 capture tools |
| Child monitoring transparency card | `effective_monitoring_transparency` (n08) | **PARTIAL** — no screenshot/camera lines found in feature set |
| Anti-tamper permission-disable alert (generic) | `app/lib/features/n05_lock/tamper_alerts_*` | **MOCK/SIMULATION** — not camera-specific |
| Anti-tamper policy flags | `app/lib/core/policy/anti_tamper_policy.dart` | **MOCK/SIMULATION** — no camera/screen-capture flag |
| Device health permission kinds | `app/lib/features/n12_devices/device_health_seam.dart` | **MISSING** camera/mic/screen-capture rows |

### 2.2 Family OS own camera use (class A — boundary)

| Artifact | Path | Classification |
|---|---|---|
| `CameraPermissionSeam` / `FakeCameraPermissionSeam` | `app/lib/features/n01_linking/camera_permission_seam.dart` | **MOCK/SIMULATION** — explicit fake; no `permission_handler` |
| Child QR scan + deny repair | `app/lib/features/n01_linking/child_qr_scan_screen.dart` | **PARTIAL** UI · **MOCK** permission |
| Studio capture mock viewfinder | `app/lib/features/n14_studio/studio_camera_capture_screen.dart` | **MOCK/SIMULATION** |
| Active call camera on/off toasts | `app/lib/features/n02_day/active_call_*` | **MOCK/SIMULATION** |
| Widget tests for QR/Studio camera seams | `app/test/features/n01_linking/*`, `n14_studio/studio_camera_*` | **MOCK** coverage |
| GAP UI-003 CLOSED (QR camera repair) | `GAP_LOG.md` | **CLOSED** for (A) only |

### 2.3 Not found in Dart

`FLAG_SECURE` · `MediaProjection` · `setCameraDisabled` · `setScreenCaptureDisabled` · screenshot block services · screen-record detectors · FS-004 policy models.

---

## 3. Android / iOS native

| Artifact | Path | Classification |
|---|---|---|
| `MainActivity` bare `FlutterActivity` | `app/android/.../MainActivity.kt` | **MISSING** enforcement hooks |
| `AndroidManifest.xml` | launcher only; **no** `CAMERA` / `RECORD_AUDIO` / admin / MediaProjection | **MISSING** |
| iOS `Info.plist` camera usage (if any) | Runner plist | **MISSING** / not used for parental control |
| `pubspec.yaml` camera / permission plugins | `app/pubspec.yaml` | **MISSING** for real camera |

---

## 4. Schema / contracts

| Artifact | Finding | Classification |
|---|---|---|
| `family-os/_CONTRACTS/schema.sql` `perm_key` | LOCATION_*, ACCESSIBILITY, BATTERY, AUTOSTART, NOTIFICATIONS, USAGE_STATS, SCREEN_TIME_IOS — **no CAMERA / RECORD_AUDIO / SCREEN_CAPTURE** | **MISSING** for FS-004 |
| App/screen-capture policy tables | **Not found** | **MISSING** |

---

## 5. Registry / prototype / Policy Register

| Artifact | Path | Classification |
|---|---|---|
| **P-7** smart monitoring incl. screenshots + app picker + child transparency | `handoff/04_POLICY_REGISTER_EN.md` | **DOCUMENTED ONLY** |
| Prototype `smartWatch.screenshot`, `screenshotApps`, `openScreenshotAppsSheet` | `prototype/family_os_app.html` / `family-os/family_os_app.html` | **DOCUMENTED ONLY** |
| Phase-4 FAT-065 screenshot + app picker note | `family-os/38_PHASE4_EXECUTION_PLAN.md` | **DOCUMENTED ONLY** |
| Screens.csv FAT-065 / FAT-034 | `family-os/_REGISTRY/screens.csv` | **DOCUMENTED ONLY** |
| S-SEC-032…036 smart monitoring services | `family-os/_REGISTRY/services.csv` | **DOCUMENTED ONLY** |
| Domain 1 ambient recording + “prevent screenshot” on **playback** | `family-os/06_DOMAIN_1_AUDIO.md` | **DOCUMENTED ONLY** |
| Platform gates DPM / Accessibility | `family-os/18_PLATFORM_GATES.md` | **DOCUMENTED ONLY** |
| P-4 SOS “audio broadcast” | `handoff/04_POLICY_REGISTER_EN.md` | **DOCUMENTED ONLY** — **conflicts** SOS-final |

---

## 6. Prior experience discovery

| Note | Path | Classification |
|---|---|---|
| “camera permission: Fake* seams” | `docs/experience_discovery/01_EXECUTIVE_PLATFORM_OVERVIEW.md` | **DOCUMENTED ONLY** (A) |
| FS-003 platform audit: no DO/package hide | `application_control_discovery/04_*` | Adjacent evidence |
| No prior `screen_camera_discovery` | — | This pack is first |

---

## 7. Sync / outbox / policy bus

| Item | Finding |
|---|---|
| App Control rules on PolicySyncBus | No (FS-003 discovery) |
| Screenshot toggle sync to child | **MISSING** — in-memory Smart Alerts only |
| Camera block as OS policy sync | **MISSING** |

---

## 8. Tests

| Scope | Classification |
|---|---|
| QR/Studio FakeCameraPermissionSeam widget tests | **MOCK** (A) |
| Smart Alerts screenshot toggle tests | **PARTIAL/MOCK** if present — no enforcement proof |
| OS camera disable / screenshot block integration | **MISSING** |
