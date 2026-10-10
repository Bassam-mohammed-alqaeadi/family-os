# خريطة تماسك منصة Family OS — Platform Coherence Map

## الخلاصة للمالك

1. قرأتُ الوثائق والكود على الفرع الرئيسي (`1bf6ca0`). المنصة فيها ١٤٦ مساراً للشاشات (منها اثنان لمعرض التصميم) و١٠٦ مسارات في الخادم. لم أشغّل التطبيق ولا الاختبارات.
2. **أخطر ما وجدته:** شاشة «إنشاء العائلة» في التطبيق لا ترسل شيئاً إلى الخادم. تقول «نجح» ولا تحفظ شيئاً. وعميل الخادم الحقيقي لهذه الخطوة موجود لكن لا تستدعيه أي شاشة.
3. **الثاني:** زر «قطع الجهاز» في ملف الطفل يقطعه في ذاكرة الهاتف فقط. الخادم يبقى يقبل موقع الطفل. لم أجد في التطبيق أي استدعاء لمسار القطع في الخادم.
4. **الثالث:** الوثائق تتناقض في تحديد الخطوة التالية. وثيقة تقول التعليم، وثلاث وثائق تقول «دخول العائلة»، وخطة السلامة المعتمدة غير موجودة داخل المستودع بعد.
5. **الرابع:** في التطبيق نظاما أدوار. الهاتف يستعمل «أب/أم/طفل» يختاره المستخدم محلياً، والخادم يستعمل «ولي رئيسي/ولي مشارك/طفل».
6. **الخامس:** بعض الشاشات تعرض بيانات الخادم وتحتها بيانات محلية. ومركز التنبيهات وشاشة «اليوم» ما زالا يقرآن بيانات محلية فقط. وفي الخادم ثلاث طرق مختلفة لإرسال التنبيهات.
7. **أقترح:** إضافة شريحة صغيرة «ش٠» قبل ش٢. تصلح إنشاء العائلة وقطع الجهاز، وتوحّد المؤشر الحيّ. بعدها تمضي خطة السلامة كما هي، مع تعديلات محددة في §5.

---

**Scope and limits.** Read-only review of `origin/main` at `1bf6ca00da5499cf2f9f7579a72b3762127820e7` (merge of #32, 2026-10-10), from a detached worktree.
- **Read:**
  - `AGENTS.md`, every non-archive doc under `docs/` (headers plus targeted reads; `docs/archive/**` was only listed).
  - `app/lib` (660 Dart files): router, shell, roles, every feature folder, the design system, l10n, and the Foundation-Gate clients.
  - Android Kotlin under `app/android`.
  - Backend: `backend/src/app.js` (106 routes), `openapi/foundation.v1.json`, migrations 001–113, and CI workflows.
- **Method:** scripted route, client and orphan scans, plus targeted reading.
- **Not done:** I ran no tests, did not build the app, did not touch Render or Firebase, and did not check anything on a device. "Reachable" means statically reachable through the router or shell, not exercised.
- **Links:** they point at `main` and can drift. The pinned commit above is the snapshot.

`B` = `https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/`

---

## 1) Platform structure

### 1.1 Repository shape
| Path | Role | Note |
|---|---|---|
| `app/` | One Flutter app for both guardian and child modes (one Android APK) | 660 Dart files under `lib/`. Native Kotlin: 4 files (`ChildTelemetryService`, `LocationFixProtocol`, `LocationSessionCoordinator`, `MainActivity`) |
| `app/lib/foundation_gate/` | Typed HTTP clients for every server domain, **plus** a second app entry point ([`foundation_gate/main.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/foundation_gate/main.dart#L9-L10)) with its own `ChildrenControlCentre` UI | Clients and UI are mixed in one folder |
| `backend/` | Node/Express. `src/app.js` holds all 106 routes. Domain modules: `safe-zones.js`, `location-telemetry.js`, `sos-emergency.js`, `screen-time.js`, `web-filter.js`, `tasks.js`, `calendar.js`, `family-chat*.js`, `push-registrations.js`, `fcm-sender.js`, `chat-realtime.js` | Migrations in `backend/db/migrations` (22 files, 001–008 and 100–113). The next number is 114 |
| `family-os/` and `prototype/` | Two frozen copies of the prototype and registry | `screens.csv` is identical in both. `services.csv` and `journeys.csv` differ only in BOM and line endings. Routing is generated from `prototype/_REGISTRY/screens.csv` ([`app/tool/gen_routes.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/tool/gen_routes.dart#L6)) |
| `docs/` | 732 files, most of them in `docs/archive/` | The authority map is in `docs/README.md` |

### 1.2 App shell and boot
- **Boot sequence:** [`app/lib/main.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/main.dart).
  - It first binds about 25 **local "Stage-1" runtimes**: SQLite `FsSessionKernel`, local KV identity, children roster, tasks, calendar, SOS prefs, audit log, alerts-hub projection, location UX, child apps, and Quran.
  - Then, **only if** `FAMILY_OS_API_ORIGIN` is set and Firebase initialises, it builds `MainAppFoundationRuntime` and binds the server authorities: membership, location, screen time, web filter, tasks, calendar, SOS and chat ([main.dart L150–L280](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/main.dart#L150-L280)).
  - Debug and profile builds also run `applyUxLocalSeed()` and the optional audit population. Both are refused in release builds.
- **Routing:** `go_router` with a generated router ([`app/lib/app/router.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/router.dart)).
  - **130 `/scr-*` routes.** One of them, `/scr-fat-077`, is shadowed by a legacy redirect to `/scr-fat-075` ([L296](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/router.dart#L296), [L912](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/router.dart#L912)).
  - **14 `/sys3-*` identity routes** ([`sys3_routes.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/sys3_routes.dart)).
  - **2 showcase routes** (`/gallery`, `/dev-screens`), quarantined in release.
  - **1 tombstone:** `/scr-fat-039` redirects to `/scr-fat-085`.
- **Shell:** [`shell_config.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/shell_config.dart), generated from the CSV.
  - **Parent tabs (5):** `today` (root FAT-010), `kids` (FAT-012), `family` (FAT-021), `studio` (FAT-040), `settings` (FAT-025).
  - **Child tabs (4):** `myday` (CHD-004), `learn` (CHD-012), `cfam` (CHD-007), `me` (CHD-010).
  - **Tabless screens:** onboarding, SOS and templates.
  - **"More tools" grid:** every tab root renders a [`ShellTabMoreTools`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/shell_tab_more_tools.dart) tile grid listing every screen in that tab (107 hub entries).
  - **Consequence:** every route is "reachable" through a registry grid even when no user journey leads there. This is how mock-backed screens stay one tap from production users.

### 1.3 Navigation tree (every reachable screen)
Data sources were traced per screen. **S** = reads or writes the server through a bound authority or client. **L** = local Stage-1 store, projection or seed only. **S+L** = both on the same screen.

**Onboarding / shared (tabless)**
- SHR-001 Welcome → SHR-002 Create account / SHR-003 Login (Firebase email/password) → SHR-007 Device mode.
- Guardian branch: FAT-001 Create family (**L — mock success, see C1**) → FAT-002 Setup wizard → FAT-003 Add child (**S**, needs a server family) → FAT-004 Native parent pairing (**S**) → FAT-005 Permissions explainer → FAT-006 Link success → FAT-007 Trial mode. Also FAT-008 Invite mother and FAT-009 Accept invite.
- Child branch: SHR-007 → CHD-001 Child welcome → CHD-002 Child pairing (**S**, native credential) → CHD-003 Transparency consent (**L**, it only sets the local role).
- Templates and errors: SHR-005 Network error, SHR-006 Empty state, SHR-008 Device user switch.
- Child-tabless screens: CHD-005 SOS button and CHD-006 SOS in progress (**S** with a guardian session, otherwise an honest "unwired").

**Parent › Today (FAT-010 DayBoard, L)**
- Alerts: FAT-019 Alerts hub (**L**) and FAT-020 Alert detail (**L**).
- Advisor/AI, all **L or mock**: FAT-011, 062, 063, 064, 073, 074, 076, 079, 080, 083, 086.

**Parent › Kids (FAT-012 Children list, S roster and device card)**
- Child and location:
  - FAT-013 Child profile (**S+L**; its device close and revoke actions are local, see C2).
  - FAT-014 Location map (**S** pins, zones and crossings on a fixed-origin canvas).
  - FAT-015 Location history (**S**).
  - FAT-016 Safe zones and FAT-017 Create zone (**S**).
- Screen time and apps:
  - FAT-032 Screen time (**S** server panel).
  - FAT-033 Request inbox (**L**).
  - FAT-034 Child apps and FAT-035 New-app approval (**L** seeds).
  - FAT-069 Usage report (**L**).
- Web filter and protection:
  - FAT-036 Web filter (**S+L**).
  - FAT-037 Instant lock (**S**).
  - FAT-038 Tamper alerts (**L**).
- Smart and monitoring: FAT-065/066 Smart alerts, FAT-067 Smart supervision, FAT-068 Platform monitoring, FAT-081 Peer compare and FAT-085 Smart modes (all **L**).
- Other: FAT-072 Quran progress (**L**), plus FAT-077 Road safety, which is in the hub list but redirected.

**Parent › Family (FAT-021 Conversations, S)**
- Chat: FAT-022 Conversation (**S**, realtime hints and media). The collaboration-policy editor is embedded in FAT-021 ([L248](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/conversations_list_screen.dart#L248-L251)).
- Calls: FAT-023 Active call and FAT-024 Call history (**L**, no server).
- Calendar: FAT-052 Calendar (**S+L**) and FAT-053 Add event (**L** form).
- Tasks: FAT-054 Tasks (**S+L**) and FAT-055 Create task (**L**, see C5).
- Circle: FAT-070 Outer circle, FAT-071 Friend approval and FAT-082 Chore distributor (**L**).

**Parent › Studio (FAT-040 …, all L)**
- FAT-040–051 and FAT-084 (learning, studio, assignments and results).

**Parent › Settings (FAT-025 Settings hub)**
- Devices: FAT-026 Device health detail (**L — `FakeDeviceHealthSeam`**, also used by the in-hub device list).
- Members: FAT-027 Family members (**S**), FAT-031 Mother permission level (**L**) and FAT-029 Brain control (**L**).
- SOS: FAT-028 Emergency setup (**S** ladder, **L** settings).
- Lock: FAT-030 Parent second key (**L**, hard-coded password path).
- Billing: FAT-056/057 (**L**, `MockEntitlementService`).
- Notifications and privacy: FAT-058 Notification prefs (**L**), FAT-059 Privacy data (**L**) and FAT-060 Audit log (**L**).
- Other: FAT-061 Language help, FAT-075 Coming soon, and FAT-078 Home-router filter (**L**).
- `/sys3-*` session, ownership, remove-adult and revoke screens: all on the **local** identity runtime ([`sys3_identity_screens.dart` L793–L806](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/sys3_identity/sys3_identity_screens.dart#L793-L806)).

**Child tabs**
- `myday`: CHD-004 Day board, CHD-020 Time request, CHD-021 Time expiry, CHD-022 Tasks and CHD-027 Athkar (**L**).
- `learn`: CHD-012–018, 025, 026, 028, 029, 032, 033 and 035 (**L**).
- `cfam`: CHD-007/008 Chats (**S** through the native device credential), CHD-009 Call, CHD-023 Media share, CHD-024 Arrival (check-in), CHD-030 Friends, CHD-036 Call play and CHD-037 Stickers (**L**).
- `me`: CHD-010 What is collected (**L**), CHD-011 Child-mode lock (**L**, hard-coded password), CHD-019 Wallet, CHD-031 Gifts and CHD-034 Family challenges (**L**).

**Orphan files** (nothing under `lib/` imports them; found by script):
| File | Lines | Status |
|---|---|---|
| [`n01_linking/link_qr_screen.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n01_linking/link_qr_screen.dart) | 629 | Old QR pairing (parent). Replaced by six-digit native pairing. Only tests import it |
| [`n01_linking/child_qr_scan_screen.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n01_linking/child_qr_scan_screen.dart) | 666 | Old QR scan (child). Same as above. `qr_flutter` and `mobile_scanner` are still dependencies ([pubspec L27–L29](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/pubspec.yaml#L27-L29)) |
| [`foundation_gate/family_creation_api_client.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/foundation_gate/family_creation_api_client.dart#L22) | 131 | **The only client for `POST /v1/families`.** Unused by the product (see C1) |
| `n03_screen_time/child_time_mirror_screen.dart` | 124 | Dead screen |
| `app/placeholder_screen.dart` | 60 | Test-only |
| `n06_notifications/alert_event.dart`, `core/policy/earning_channel.dart`, `core/policy/schedule_window_query.dart`, `features/education/source_library_repository.dart`, `n02_day/children_list_runtime_sources.dart`, `n02_day/family_chat_local_persistence.dart` | — | Dead model and service code. `family_chat_local_persistence` is not referenced even by tests |
| 12 `n02_day/*_mock.dart` | — | Test fixtures shipped in `lib/`, as already declared in MOCK_INVENTORY §3 |
| `foundation_gate/children_control_centre.dart` (1,026 lines) | — | Reachable only from the separate Foundation-Gate entry point. It duplicates the Kids-tab children list |

### 1.4 Role model
- **Client:** `enum AppRole { father, mother, child }` ([`core/domain/role.dart` L5](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/core/domain/role.dart#L5)).
  - Held in a local `RoleController` that defaults to `father` ([role_controller L8](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/role_controller.dart#L8), [main.dart L508](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/main.dart#L508)).
  - Set by screens: Device mode, Child welcome, Transparency consent and Accept-mother-invite.
  - Mirrored into the identity runtime as a "legacy role fallback" ([main.dart L525–L527](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/main.dart#L525-L527)).
  - `RoleGuard` (owner-only and father-only screens) runs on this local role ([role_guard.dart](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/app/role_guard.dart)). There are 387 references to `AppRole.father` or `AppRole.mother` outside the guard.
- **Server:** `primary_guardian | co_guardian | child`, enforced in SQL and route code. The membership roster exposes `isSelf`. `GET /v1/families/{id}/permission-snapshot` exists ([app.js L2858](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L2858)) but has **no Dart client**.
- **Docs:**
  - SPINE-001 binding 1 fixes one role model, `primary_guardian/co_guardian/child` ([SPINE-001 §4](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/harness/cards/SPINE-001-experience-bindings.md)).
  - PRV2-028 calls gendered and local UI "evidence only" ([04_DECISION_REGISTER L37](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/product_refinement_v2/04_DECISION_REGISTER.md#L37)).
  - The conflict is recorded as C4.

### 1.5 Design system actually used
- **Tokens:** `ThemeExtension`s `FamilyColors`, `FamilyShadows`, `FamilyRadii` and `FamilyGradients` in [`core/design/tokens.dart`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/core/design/tokens.dart). The font is IBM Plex Sans Arabic (400/600/700). Discipline is good: one raw `Color(0x…)` remains in features (`device_user_switch_screen.dart` L125), and there are no `Colors.red`-style literals.
- **Components** in `core/design/components/` (38 files), counted by number of feature files using each:

| Component | Feature files using it | Note |
|---|---|---|
| `PrimaryBtn` | 100 | |
| `AppEmptyState` | 101 | |
| `Tag` | 67 | |
| `AppErrorState` | 30 | |
| `RowTile` | 15 | |
| `AppCard` | 8 | |
| `CapabilityHonestyBadge` | 6 | |
| `AppToast.show` | 94 | |
| `AppLoadingState` | **0** | 105 feature files call `CircularProgressIndicator` directly |
| `SilentLocateSheet` | — | Exists and is wired to a **local** request (see §5, ش٢) |

- **Server panels:** each server-backed domain added its own panel (`ScreenTimeServerPanel`, `WebFilterServerPanel`, `TasksServerPanel`, `CalendarServerPanel`), each with its own state copy. There is no shared "server-state card" component.

### 1.6 RTL and l10n conventions
- **ARB:** `lib/core/i18n/app_ar.arb` is the template, with `app_en.arb`; 3,764 keys each. `AppLocalizations` is generated.
- **RTL:** layout uses directional insets and alignment (59 uses). I found no `EdgeInsets.only(left/right)` or `Alignment.centerLeft/Right` in features. RTL hygiene is good.
- **Competing copy channel:** `foundation_gate/foundation_gate_copy.dart` (70 `isArabic` ternaries), `device_lifecycle_copy.dart` (23) and `native_child_pairing_copy.dart` (33) bypass ARB. They are used by Login, Create account, Add child, Children list and Pairing.
- **Hard-coded Arabic role labels:** [`family_members_role_labels.dart` L33](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n12_devices/family_members_role_labels.dart#L33).

### 1.7 State management and data access
- **No state library.** The app uses top-level mutable singletons with `bind…/rebind…` functions: about 45 `tryBind`, `rebindStage1` and `bind*ServerAuthority` entry points. On top of that sit `InheritedNotifier` scopes (`AppScope`, `CurrentRole`, `CurrentIdentity`, `CurrentLocale`).
- **Two data worlds side by side:**
  - **Local:** `core/*` and `features/*` Stage-1 repositories, `FsSessionKernel` SQLite, and local KV.
  - **Server:** `foundation_gate/*_api_client.dart` → `features/*/…_server_authority.dart` → panels or repositories.
  - About 89 call sites use `isFoundationGateUuid(…)` to tell server ids from local ids (`child_a`, `k1`, …).
- **Native:** the Kotlin service calls three device-credential routes directly: `POST /v1/devices/{id}/telemetry`, `POST …/location-fixes` and the chat proxy `/v1/devices/{id}/chat…`.

---

## 2) Per-domain inventory: the 4-column honesty measure (as read from code)

**How to read the table:**
- ✅ = present. ◐ = partial (the gap is in the "where it breaks" column). ❌ = absent.
- "Client" means a Dart or Kotlin caller exists **and is reachable**. "Screen+journey" means a reachable product screen reads it. I did not judge test sufficiency.
- The "CURRENT says" column quotes [`CURRENT_EXECUTION_PLAN.md` L26–L35](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/CURRENT_EXECUTION_PLAN.md#L26-L35).

| Domain | Table | Contract | Client | Screen+journey | CURRENT says | Where it breaks (evidence) |
|---|---|---|---|---|---|---|
| **W1 Family & identity** | ✅ 001–003 | ✅ | ◐ | ◐ | 4/4 | `POST /v1/families` ([app.js L353](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L353)): the only client is orphaned. FAT-001 calls `mockCreateFamilySuccess` ([create_family_screen L46–L47](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n01_linking/create_family_screen.dart#L46-L47), [create_family_create L16–L19](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n01_linking/create_family_create.dart#L16-L19)). Guardian transfers ([L2766–L2819](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L2766)) have no client; `/sys3-ownership-transfer` is local. Memberships invite/accept/revoke are ✅ (FAT-027) |
| **W2 Child device** | ✅ 007/008/101 | ✅ | ◐ | ◐ | 4/4 | Pair, claim, telemetry and status are ✅. The **revocation route** ([app.js L443](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L443)) has **no Dart caller**. FAT-013 revoke/lost/decommission goes to the local identity runtime ([child_profile_screen L618–L634](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/child_profile_screen.dart#L618-L634), [child_device_management_repository L279–L283](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/core/identity/child_device_management_repository.dart#L279-L283)). Settings › Device health uses `FakeDeviceHealthSeam` ([device_health_detail L106](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n12_devices/device_health_detail_screen.dart#L106)) |
| **W3 Location & zones** | ✅ 102/103 | ✅ | ✅ (guardian 6 ops, native fixes) | ◐ | 4/4 | The map is a canvas around a fixed Riyadh origin ([location_server_authority L469–L473](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/location_server_authority.dart#L469-L473), [location_ux_bridge L480–L484](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/location_ux_bridge.dart#L480-L484)). Crossings feed only the map's day thread ([L92–L95](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/location_server_authority.dart#L92-L95)). The Alerts hub reads the **local** geofence domain ([alerts_hub_local_projection L83–L88](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/alerts_hub_local_projection.dart#L83-L88)). "Silent locate" is local ([location_map_screen L229–L242](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/location_map_screen.dart#L229-L242)). Retention is 30 days ([location-telemetry.js L43](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/location-telemetry.js#L43)) |
| **W4 SOS** | ✅ 104 | ✅ | ◐ | ◐ | 4/4 | Guardian side ✅. The device routes `POST /v1/devices/{id}/sos-alerts` and resolve ([app.js L791, L904](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L791)) have no client, Dart or Kotlin. The child button only works with a guardian bearer. Delivery rows cannot say "delivered" (CHECK in [104 L176](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/db/migrations/104_sos_emergency.sql#L176)) |
| **W5 Screen time** | ✅ 105 | ✅ | ◐ | ◐ | 4/4 | Device `GET/POST /v1/devices/{id}/screen-time` has no client (stated in [family_screen_time_api_client L338–L343](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/foundation_gate/family_screen_time_api_client.dart#L338-L343)). FAT-033 Request inbox, CHD-020 Time request, FAT-034/035 Apps and FAT-069 Usage are local. There is no device-credential time-request route |
| **W6 Web filter & tamper** | ✅ 106 | ✅ | ◐ | ◐ | 4/4 | Device `GET …/web-filter`, `temp-allow-requests` and `protection-reports` ([L1432–L1482](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L1432)) have no client. FAT-038 Tamper alerts is local. The classifier with `.example` domains is duplicated in Dart ([web_filter_engine L89–L93](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/core/web_filter/web_filter_engine.dart#L89-L93)) and in Node ([web-filter.js L229–L235](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/web-filter.js#L229-L235)) |
| **W7 Tasks & points** | ✅ 107 | ✅ | ◐ (guardian) | ◐ | 4/4 | The server panel sits above a still-live local board whose "New task" goes to local FAT-055 ([family_tasks_screen L286–L293, L381–L384](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n16_tasks/family_tasks_screen.dart#L381-L384), [create_task_repository L27](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n16_tasks/create_task_repository.dart#L27)). Device task routes have no client, and CHD-022 is local |
| **W8 Calendar** | ✅ 108 | ✅ | ◐ (guardian) | ◐ | 4/4 | Same stacking pattern ([family_calendar_screen L365](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n15_calendar/family_calendar_screen.dart#L365-L369)). FAT-053 Add event is local. Device events routes have no client |
| **W9 Family chat** | ✅ 109–113 | ✅ | ✅ (guardian HTTP, child via native proxy, realtime, media) | ✅ in code | Awaiting live check | Push registration lives inside the chat authority ([family_chat_server_authority L96](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n02_day/family_chat_server_authority.dart#L96)) and is guardian-only ([113 L21](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/db/migrations/113_family_push_registrations.sql#L21)) |
| W10 Learning | ❌ | ❌ | ❌ | L only | ⬜ | `n14_studio`, `n17_child_learn`, `features/education`, `core/education` |
| W11 Quran | ❌ | ❌ | ❌ | L only | ⬜ | `features/quran`, CHD-025/026, FAT-072 |
| W12 Minutes loop | ❌ | ❌ | ❌ | L only | ⬜ | `core/policy/wallet_ledger.dart`; `earning_channel.dart` is orphaned; CHD-019 Wallet |
| W13 Today | ❌ | ❌ | ❌ | L only | ⬜ | FAT-010 `DayBoardScreen` uses `day_child_mock` and a local projection |
| W14 Privacy & transparency | ◐ (audit, ai_events) | ◐ (`audit-events`, `permission-snapshot`, `ai-events`) | ❌ | L only | ⬜ | FAT-059/060 and CHD-010 are local. There is no consent table (Slice 2) |
| Check-in / battery alert | ◐ (battery in telemetry) | ◐ | ◐ | L (CHD-024) | not tracked | Slice 9 |
| Notifications / alerts centre | ◐ (outbox, SOS deliveries, push nudges) | ◐ | ◐ (chat only) | L (FAT-019/020/058, FAT-065) | not tracked | See C5 and §5 ش٤/ش١٥ |
| Billing | ❌ | ❌ | ❌ | L (`MockEntitlementService`) | — | MOCK_INVENTORY #4 |
| Advisor / AI | ◐ (`ai_events`, device facts only) | ◐ | ❌ | L/mock | — | `ai-events.js` registers only `device.*` ([L17–L30](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/ai-events.js#L17-L30)) |
| Calls, outer circle, friends, smart modes, studio | ❌ | ❌ | ❌ | L | — | No server domain |

**Bottom line:**
- On the code as read, **W1 and W2 do not satisfy their own published 4/4**: there is no reachable server family creation and no reachable server device revocation.
- **W3–W8** are 4/4 on guardian HTTP only. Every child-device credential route except location fixes, telemetry and chat has no caller.
- I did not run the CI tests that back the 4/4 claims. They prove server and client behaviour, not that a product screen calls them.

---

## 3) Conflicts and duplications

The **top five** are in bold. Each entry gives the evidence and a recommended single source of truth (SSOT).

### C1 — Family creation in product onboarding is a mock (doc-vs-code, safety-blocking)
- **Evidence:** the FAT-001 default is `mockCreateFamilySuccess`, which "succeeds immediately — no persistence".
  - The guardian path is Device mode → FAT-001 → FAT-002 ([device_mode_screen L30](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/shared_onboarding/device_mode_screen.dart#L30)).
  - FAT-003 then requires a remote family and fails with a toast without one ([add_child_screen L132–L140](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n01_linking/add_child_screen.dart#L132-L140)).
  - `FamilyCreationApiClient` is imported by nobody in `lib/`.
- **Contradicts:**
  - CURRENT "W1 4/4".
  - CURRENT "Next": "تسجيل ← عائلة ← إقران طفل" on a real phone.
  - AGENTS §5 "no mock persistence".
- **SSOT:** FAT-001 calls `POST /v1/families` through a runtime method on `MainAppFoundationRuntime`, which reuses `FamilyCreationApiClient`. On success it re-discovers families (`GET /v1/me/families`) and selects the new one. Delete `mockCreateFamilySuccess` from `lib/` and keep it in tests only.

### C2 — "Cut the device" in the app is local only (doc-vs-code, safety-critical)
- **Evidence:**
  - No Dart reference to `/revocation`.
  - FAT-013 actions and `/sys3-revoke-confirm` call `IdentityRuntime.revokeEnrollment` and siblings, which are local.
  - The server revocation route exists and is tested on PostgreSQL ([app.js L443](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L443)).
  - A parent who "cuts" a lost phone leaves the server credential live, so the child service keeps posting fixes.
- **Contradicts:** Master plan task 3 "يقطعه من الكشف — ٤/٤" ([00_MASTER_PLAN L193](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/00_MASTER_PLAN.md#L193)) and CURRENT W2 "قطع".
- **SSOT:**
  - Add `revoke()` to `FamilyDeviceApiClient`.
  - Route FAT-013's revoke/lost/decommission through it when a session is bound.
  - Retire `/sys3-revoke-confirm` for enrollments.
  - Give "lost" and "decommissioned" server reasons (the reason column exists in 101).

### C3 — The governance pointer is split across six documents (doc-vs-doc)
| Doc | Says |
|---|---|
| [`CURRENT_EXECUTION_PLAN.md` L12](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/CURRENT_EXECUTION_PLAN.md#L12) | Next = W9 live check → RESCUE cards → **Phase 4 education** |
| Owner decision 2026-10-10 (safety plan) | **All safety first; education after the two-phone test** |
| [`PROJECT_EXECUTION_PLAN.md` L24–L26](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/PROJECT_EXECUTION_PLAN.md#L24-L26), [`README.md` L15](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/README.md#L15), [`OPEN_DECISIONS.md` L7, L72](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/OPEN_DECISIONS.md#L72) | Active system = Family Entry & Children Control (Cover stage) |
| [`00_MASTER_PLAN.md` L4](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/00_MASTER_PLAN.md#L4) | It supersedes CURRENT "as the active-system pointer". [AGENTS.md L7–L14](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/AGENTS.md#L7-L14) and `docs/README.md` say CURRENT **is** the pointer |
| [`00_MASTER_PLAN.md` L81](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/00_MASTER_PLAN.md#L81) | Safety functions are not delivered before `delivered → applied → verified` on a **real device**. CURRENT nevertheless marks W3–W6 4/4 and moved to Phase 3 |
| [AGENTS.md L31](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/AGENTS.md#L31) | Four columns are binding. The approved safety plan adds a fifth ("on the phone") |
| [`EXECUTIVE_OPERATING_MODEL.md` L6](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/EXECUTIVE_OPERATING_MODEL.md#L6) | Systems reference = `GLOBAL_LAUNCH_MASTER_PLAN.md`, which `00_MASTER_PLAN` cancels |
| [`product_refinement_v2/README.md` L3–L7](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/product_refinement_v2/README.md#L3-L7), `product_refinement_v2/LOOP_STATE.md` | "FOUNDATION WAVE"; Native, FCM and realtime "unauthorized"; pointer dated 2026-10-01 |
| AGENTS.md L12 vs [`docs/README.md` L32](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/README.md#L32) | AGENTS gives `product_refinement_v2/16` and `/18` authority rank 4. `docs/README` says the folder has "no execution authority" |
| Safety plan | Cites `docs/safety_phase/01_SAFETY_PHASE_PLAN.md`, which does **not exist on main** and is not in the `docs/README` map |

- **SSOT:**
  - `AGENTS.md` holds law, including the 5-column measure once the owner signs it.
  - `00_MASTER_PLAN.md` holds scope and sequence. It needs a dated amendment: "Phase 2 reopened; 5th column; safety before education".
  - `CURRENT_EXECUTION_PLAN.md` is the only pointer.
  - `docs/safety_phase/01_SAFETY_PHASE_PLAN.md` is the slice plan and is registered in `docs/README.md` §1.
  - Rewrite `PROJECT_EXECUTION_PLAN.md`, root `README.md` "Start here" and `OPEN_DECISIONS.md` §1/§6 as pointers only. Add a "superseded" banner to the `product_refinement_v2` README and LOOP_STATE. Correct EXECUTIVE L6.

### C4 — Two role models (doc-vs-code, naming)
- **Client:** local `AppRole{father,mother,child}` that the user picks, with `RoleGuard`, `canAct` and the mother "observer" logic.
- **Server:** `primary_guardian/co_guardian/child` plus the `permission-snapshot` explainer, which has no client.
- AGENTS §5 forbids outcomes from "a local role picker". SPINE-001 binding 2 forbids client-side allow/deny. FAT-031 "Mother permission level" is local.
- **SSOT:** the server membership role for the selected family (from `/memberships` `isSelf`, then `permission-snapshot`).
  - Map it to a UI `GuardianKind {primary, co, child}`.
  - Labels may stay "أب/أم" as display only.
  - `RoleController` becomes a projection of server identity when a session exists. The local picker stays only for no-server builds.

### C5 — One capability, several truths on screen, and three delivery mechanisms (competing patterns)
- **Server vs local on screens:** four different patterns exist:
  - (a) Screen time replaces the local UI when router-built ([child_screen_time_screen L501–L528](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/features/n03_screen_time/child_screen_time_screen.dart#L501-L528)).
  - (b) Tasks, calendar and web filter **stack** the server panel above a live local board with local create forms. This violates doc 18 §5 "mix remote with seeded/local … without unmistakable boundary" ([18 L55](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md#L55)).
  - (c) Location swaps the repositories behind an unchanged screen.
  - (d) SOS swaps a global service.
- **Local surfaces next to server routes:** the Alerts hub (FAT-019/020), Today (FAT-010), Request inbox (FAT-033), Tamper alerts (FAT-038) and Device health (FAT-026) are local while the server routes exist.
- **Three delivery paths in the backend:**
  - Chat sends FCM nudges directly after commit with its own `family_push_nudges` table ([app.js L105–L116](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/app.js#L105-L116)).
  - Geofence writes `outbox_events` ([location-telemetry.js L597–L605](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/location-telemetry.js#L597-L605)).
  - SOS writes `family_sos_alert_deliveries` with no `delivered` state.
- SPINE-001 binding 3 ("new notification stream = breach") is already breached.
- **SSOT:**
  - **Pattern (a) everywhere.** The router-built screen renders the server authority. The local board exists only in test or preview hosts and is deleted when the server path is real.
  - **One dispatcher** that reads `outbox_events`. Chat and SOS delivery rows become projections of it.
  - **FAT-019** is the single alerts centre.
  - **FAT-010** is the single Today surface.

### Other conflicts and duplications
| # | Kind | Evidence | SSOT / action |
|---|---|---|---|
| C6 | Duplicate app entry and UI | `foundation_gate/main.dart` and `FoundationGateApp` with `ChildrenControlCentre` (1,026 lines) duplicate the Kids tab; Foundation Gate CI analyses and tests `lib/foundation_gate` and `test/foundation_gate` | Keep `foundation_gate/` for clients and models only. Move or retire the second app after porting its tests to `children_list_screen` |
| C7 | Dead pairing UI and dependencies | The QR screens are orphaned. `qr_flutter` and `mobile_scanner` remain. MOCK_INVENTORY #3 still describes the camera seam as used by "QR scan for linking" | Delete the QR screens and dependencies; update the inventory row |
| C8 | Duplicate web classifier | Dart `WebFilterEngine.classifyHost` and Node `classifyHost`, both with `.example` fixtures | Server list plus device enforcement (slice 14) is the SSOT. Move fixtures to tests (slice 1) |
| C9 | Duplicate local and server domains | `core/policy/sos_*` + `core/sos_final/*` + server SOS; `core/policy/screen_time_*` + `core/screen_time` + `core/app_control` + server; `core/policy/web_filter_*` + `core/web_filter` + server; `core/location` (local geofence) + server | Record the fate of each local twin per slice (master plan §4: reuse / extract / remove) |
| C10 | Two frozen prototype copies | `family-os/` and `prototype/` hold the same registry (byte differences only) | `prototype/` stays the generator input. Mark `family-os/` historical or move it to `docs/archive` |
| C11 | Competing l10n channel | `foundation_gate_copy.dart` and others use `isArabic ? … : …`; Arabic role labels are hard-coded | Move these strings to ARB |
| C12 | Loading pattern | `AppLoadingState` has no users; `CircularProgressIndicator` is used raw in 105 files | Use `AppLoadingState` for every new or edited screen |
| C13 | Folder naming | `n07_advisor` and `n07_privacy` share a prefix. `n02_day` (93 files) holds chat, location, alerts, calls and friends. `education`, `quran` and `sys3_identity` break the `nNN_` scheme. `core/compliance` and `core/platform` are empty | Do not rename now (churn). New code goes in domain-named subfolders (for example `n02_day/location/…` or `features/safety/…`), recorded in SPINE-001 |
| C14 | Shadowed route | FAT-077 route plus hub tile, with a legacy redirect to FAT-075 | Drop FAT-077 from the hub list (generator input) |
| C15 | Stale or competing plans | `app/FRONTEND_FIRST_PLAN.md`, `UI_UX_FIRST_PLAN.md` and `PRODUCTION_READINESS_AUDIT.md` ("local-first, backend later"; last touched 2026-09-24). `W9_REALTIME_MEDIA_RECEIPTS_PROPOSAL.md` still says "awaiting owner approval" although it is merged | Archive the three `app/*.md` files; mark W9 as implemented |
| C16 | Firebase and Google policy vs the safety plan | Doc 17 §4 excludes any service that needs a billing-account attachment ([17 L47](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/product_refinement_v2/17_RENDER_FIREBASE_SERVICE_BOUNDARY.md#L47)). The owner approved Google Maps, which requires a billing account. Doc 17 §5 requires an approval record | Add a dated amendment and approval record to doc 17 in ش٦ |
| C17 | Child deletion not admitted | [`OPEN_DECISIONS.md` L32](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/OPEN_DECISIONS.md#L32) lists "edit/delete profile admission" as open. No delete-child route exists. Safety ش٣ assumes child deletion | An owner admission is needed before ش٣ (see §5) |
| C18 | Design-token doc drift | `ink2` is `#8A8FA3` in the doc and `#6B7082` in code (an intentional WCAG change) ([06_DESIGN_TOKENS L25](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/reference/frozen-prototype-handoff/06_DESIGN_TOKENS.md#L25)) | `tokens.dart` is the SSOT; annotate the doc |
| C19 | SPINE-001 binding 5 not applied | Only `device.*` AiEvents exist; W3–W9 emit none | Each safety slice emits its `AiEvent` type or explicitly declares "none" |
| C20 | Duplicate LOOP_STATE | `docs/harness/LOOP_STATE.md` (live) and `docs/product_refinement_v2/LOOP_STATE.md` (stale) | Keep the harness one |

---

## 4) Coherence rules for every future slice

**Recommended home:** promote [`docs/harness/cards/SPINE-001-experience-bindings.md`](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/harness/cards/SPINE-001-experience-bindings.md) to the owner-signed "five bindings" contract, which it was written to be.
- Reference it from `TASK_CARD_TEMPLATE.md` §6, which already gates on "الروابط الخمسة".
- Add the concrete rules below as its §9.
- Doc 18 stays the UX law, and this list is its executable checklist.

**R1 — Identity and roles**
- Server ids only. No new code accepts a non-UUID child or family id on a server path.
- Role, and the ability to act, come from the server membership and permission snapshot. The client only explains.

**R2 — Contract**
- Every route goes through `app.js` → OpenAPI (drift gate) → a URI builder in `foundation_gate_configuration.dart` → a method on one `*_api_client.dart`.
- Device-credential routes are called from Kotlin (`/v1/devices/{id}/…`) and get JVM tests in `tools/android/run_native_protocol_tests.sh`.
- Idempotency key on every POST, PUT or PATCH. Errors use the `HttpError(status, code)` vocabulary. Clients map codes and never raw messages.

**R3 — Screens**
- **One router-built path.** A screen built by the router renders the server authority. Local repositories may exist only as injected test or preview seams (pattern (a) in C5).
- Never stack server and local truth on one screen.
- Reuse existing SCR ids before adding screens (see §5 for the mapping).

**R4 — States**
- Every server panel renders the same seven states: loading (`AppLoadingState`), empty (`AppEmptyState`), not configured or no session, denied, unreachable or retry (`AppErrorState`), stale (shows freshness), and ready.
- Copy lives in ARB (Arabic first, then English). Layout uses directional insets only.
- `CapabilityHonestyBadge` marks anything the phone has not confirmed.

**R5 — Data ownership**
- The server owns facts. The device owns only queued, unsent fixes.
- A time-based state ("no update since…") is computed at read time, not by timers (Render sleeps).
- Retention constants live in one backend module and are surfaced in the API (`retentionDays`).

**R6 — Notifications**
- Every alertable fact writes **one** `outbox_events` row in the same transaction.
- One dispatcher delivers it (FCM, then in-app) with a per-(event, registration) idempotency key.
- FAT-019 lists the same events. No new nudge table or per-domain delivery table.

**R7 — Consent and transparency (market-level, per the owner's 2026-10-10 decision)**
- One-time prominent disclosure before the permission request, reusing CHD-003.
- A persistent notification on the child phone.
- An "About supervision" page in the child's `me` tab, reusing CHD-010.
- No per-view notifications to the child, and no word "silent" or "صامت" in copy.
- Server consent record per (child, capability, text version).

**R8 — Gates per slice**
- Migration numbering is sequential from 114.
- A new PostgreSQL test file must be added to the explicit `node --test` list in [`backend_ci.yml` L85](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/.github/workflows/backend_ci.yml#L85). Otherwise it never runs on real PostgreSQL.
- Update `MOCK_INVENTORY.md` in the same PR whenever a seed is touched.
- Update CURRENT's table with the five columns.

**R9 — Evidence language**
- "On the phone" is ✅ only with an owner device check recorded in the card. CI green is never written as device verification.

---

## 5) Impacts on safety plan slices 2–17

**Proposed ش٠ (small; before ش٢; can run in parallel with ش١).** Three slices assume C1 and C2 are working: ش١'s phone check ("هل يقطع الإقران؟"), ش٣ (delete on revocation) and ش١٧ (cut and delete).
- Fix family creation (C1) and device revocation from FAT-013 (C2).
- Unify the pointer docs (C3). CURRENT "Next" must say safety, not education, now rather than at ش١٦. Otherwise any agent following CURRENT starts W10.
- Commit the safety plan into `docs/safety_phase/` and register it.
- Take the owner's signature for the 5th column in AGENTS.md, then update the master plan, CURRENT and the task-card template.

| Slice | Conflict with current structure | Adjustment |
|---|---|---|
| **ش٢ Consent** | Local `PrivacyCollectionPolicy`/`CollectionScope` and CHD-003, CHD-010, FAT-005 and FAT-059 already exist. The rename of `SilentLocateSheet` (ARB `silentLocate*`) only relabels a **local** request, and there is no server "locate now" route | Reuse CHD-003 as the one-time disclosure and CHD-010 as "About supervision"; do not add screens. Back `CollectionScope` with the server consent read. Rename the keys and copy, and **hide** the button until ش٤/ش٥ provide a real server→device request. Migration 114. The 403 `consent_required` must be added to the native `ACCESS_REFUSED` taxonomy without clearing pairing (consistent with LOC-001) |
| **ش٣ Retention/deletion** | Child deletion is not admitted ([OPEN_DECISIONS L32](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/docs/OPEN_DECISIONS.md#L32)) and no route exists. "Delete on revocation" needs C2 first. Retention pruning deliberately keeps fixes that evidence a crossing or SOS | Get an owner admission for child deletion, or limit ش٣ to revocation plus guardian request. Pruning already keeps any fix referenced by a crossing or an SOS ([location-telemetry.js L530–L548](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/backend/src/location-telemetry.js#L530-L548)). ش٣ must decide whether a guardian's "delete" or a revocation overrides that evidence rule. This is a product decision; keeping the evidence and redacting coordinates is one option. Change the constant in one place (`LOCATION_RETENTION_DAYS`) and surface `retentionDays` in the contract |
| **ش٤ Notifications** | Three delivery mechanisms (C5). The SOS deliveries CHECK forbids `delivered` and needs a migration. Push registrations are guardian-membership only, so device registration needs a new table or an extended one. Push registration is wired inside the chat authority | Build one outbox dispatcher; migrate chat nudges and SOS deliveries onto it. Move push registration to app start (the `MainAppFoundationRuntime` level). Use the Kotlin device-credential register route. Deep link the notification to the existing SCR ids (FAT-018 for SOS, FAT-014 for zones, FAT-019 for others) |
| **ش٥ Child-phone durability** | The native layer is 4 Kotlin files. `LocationSessionCoordinator` owns revocation semantics (LOC-001). No boot receiver is in the manifest | Extend the coordinator rather than adding a parallel queue. The manifest gains `RECEIVE_BOOT_COMPLETED` with prominent-disclosure text from ش٢ |
| **ش٦ Live map** | The map is a custom canvas with the fixed origin duplicated in **two** files. `/v1/realtime` is chat-scoped (thread membership checks). Doc 17 forbids billing-account services (C16) | Replace `_MapCanvas` inside FAT-014 and keep the `LocationMapKeys` tests. Delete both origin constants. Add location hints to the realtime gateway with **family-membership** checks, hints only, as in chat. Amend doc 17 with the Maps approval record |
| **ش٧ Places/alerts** | `PATCH safe-zones` deliberately allows alert flags only, because geometry is immutable by design ("a moving boundary is another boundary"). The Alerts hub reads the local geofence domain. NO_SHOW is client-only | The radius slider and address search apply **at creation**. "Edit place" means archive plus create (needs an archive route). FAT-019 reads server crossings. Keep NO_SHOW hidden until a read-time server rule exists |
| **ش٨ Child SOS** | The device SOS routes exist with no client. CHD-005/006 use the guardian bearer path. The prototype calls for a floating SOS button on child screens | Kotlin bridge → `POST /v1/devices/{id}/sos-alerts`. CHD-005/006 call the native bridge in child mode. The delivery state comes from the ش٤ dispatcher. Reuse the existing `sos_*` components (`sos_delivery_status`, `sos_cancel_confirmation`) |
| **ش٩ Check-in/battery** | CHD-024 Arrival and the local `family_ops` store already exist. Battery is in `devices` telemetry (007) | Reuse CHD-024 as the check-in UI. Add a new migration, numbered after 114. Compute the battery and "no update since" alerts at read time, plus an outbox row when a fix crosses the threshold |
| **ش١٠ History** | FAT-015 exists. The server window equals retention | Reuse FAT-015 with a map. Deletion uses the ش٣ route |
| **ش١١ Usage/apps** | The `child_apps_*` seeds (MOCK #19/#20), FAT-034, FAT-069 and CHD-020 are local | Kotlin posts to the existing `POST /v1/devices/{id}/screen-time`. The router-built FAT-034/069 read the server (pattern (a)). Delete the seeds in the same PR and decrement the inventory |
| **Blocking test → ش١٢** | **No device-credential time-request route** exists, only the family-scoped one. The CHD-011/FAT-030 lock uses the hard-coded password (slice 1 hides it). Instant lock exists on the server | Add `POST /v1/devices/{id}/time-requests`. CHD-021 Time expiry and `app_deny_page` become the native overlay's content source. Retire the local `device_lock_service` path |
| **ش١٣ Tamper** | FAT-038 and `core/policy/anti_tamper_*` are local. Server `protection-reports` and `GET /protection` exist | FAT-038 reads `GET /protection`. Kotlin posts protection reports. Delete the local anti-tamper bus after the server path works |
| **ش١٤ Web filter** | The classifier is duplicated (C8). FAT-078 is a home-router filter, which is out of scope | The server list and categories are the SSOT; the VPN consumes the server policy. Remove the Dart engine from the router-built path. Leave FAT-078 under "coming soon" |
| **ش١٥ Alerts centre** | Five alert-like surfaces: FAT-019, FAT-020, FAT-065/066 smart alerts, FAT-038 and FAT-033. Today (FAT-010) is local | One centre (FAT-019 and 020) over outbox events. Fold FAT-038 and FAT-033 into it as filters. Add a server-fed safety strip on FAT-010 (SPINE binding 3). FAT-065/066 stay AI-local until W13 |
| **ش١٦ Truth/pointer** | The pointer fix is needed **earlier** (C3) | Keep the final re-marking of the five columns here; move the pointer and doc unification to ش٠ |
| **ش١٧ Two-phone test** | Needs C1, C2 and the cut/delete path. The release build still seeds the local children list (plan correction 2026-10-10; [main.dart L91](https://github.com/Bassam-mohammed-alqaeadi/family-os/blob/main/app/lib/main.dart#L91)) | Add a release-mode guard test that the router-built Kids, Today and Alerts screens show no Stage-1 seed when a session exists |

**Unchanged:** the order ش١ → ش٢ → … → ش١٧ still fits the code. The plan does not conflict with the RTL, token or ARB conventions. Every slice can reuse existing SCR ids, so **no new tabs are needed**.

**Small factual corrections to the plan (§4 table):**
- Geofence events **are** read by the app, but only into the map's day thread. The alerts surface is what is missing.
- The device "cut" check in the post-ش١ phone check cannot be triggered from the app UI today (C2).
