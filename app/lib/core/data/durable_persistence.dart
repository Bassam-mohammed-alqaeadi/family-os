import 'package:shared_preferences/shared_preferences.dart';

import '../../features/n01_linking/onboarding_progress_repository.dart';
import '../../features/n03_screen_time/child_screen_time_screen.dart';
import '../../features/n04_web_filter/web_filter_screen.dart';
import '../policy/anti_tamper_repository.dart';
import '../policy/desired_monitoring_prefs_repository.dart';
import '../policy/device_lock_service.dart';
import '../policy/notification_prefs_repository.dart';
import '../policy/privacy_collection_repository.dart';
import '../policy/schedule_window_repository.dart';
import '../policy/screen_time_policy_repository.dart';
import '../policy/smart_mode_prefs_repository.dart';
import '../policy/sos_ladder_repository.dart';
import '../policy/time_request_repository.dart';
import '../policy/time_request_service.dart';
import '../policy/web_filter_policy_repository.dart';
import '../policy/web_unlock_request_repository.dart';
import '../policy/web_unlock_service.dart';

/// Rule 25 — the durable backend behind every Stage-1 prefs-store seam.
///
/// Stage-1 shipped these seams as process-lifetime memory maps, labelled
/// "SharedPreferences adapter-ready". This class *is* that adapter: one
/// implementation satisfying every store interface, writing through to
/// platform storage so father/child settings survive an app restart.
///
/// Every store interface shares the same two-method contract
/// (`Future<String?> read(String)` / `Future<void> write(String, String)`),
/// which is why a single class can serve them all. The two list-shaped
/// stores (`AdvisorMemoryStore`, `ChatMockStore`) are intentionally not
/// covered here — they carry the AI memory / chat layer, which lands with
/// the backend phase.
final class DurablePrefsStore
    implements
        AntiTamperPrefsStore,
        DesiredMonitoringPrefsStore,
        DeviceLockPrefsStore,
        NotificationPrefsStore,
        OnboardingProgressStore,
        PrivacyCollectionPrefsStore,
        SchedulePrefsStore,
        ScreenTimePolicyPrefsStore,
        SmartModePrefsStore,
        SosLadderStore,
        TimeRequestPrefsStore,
        WebFilterPrefsStore,
        WebUnlockPrefsStore {
  DurablePrefsStore(this._prefs);

  final SharedPreferences _prefs;

  /// Namespace keeps Family OS keys separable from any other prefs user.
  static const String namespace = 'family_os.';

  @override
  Future<String?> read(String key) async => _prefs.getString('$namespace$key');

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString('$namespace$key', value);
  }
}

/// Opens the platform store and installs it over the Stage-1 seams.
///
/// Call once from `main`, after `WidgetsFlutterBinding.ensureInitialized()`
/// and before `runApp`. Tests never call this, so they keep the in-memory
/// defaults and stay hermetic — the 896-case suite is unaffected.
///
/// Composition note: this file is the composition root for persistence, so
/// it imports the three feature-level store seams (`setup wizard`,
/// `screen time`, `web filter`) alongside the core policy ones. Those three
/// globals are candidates to move under `core/` in a later cleanup card.
Future<void> installDurablePersistence() async {
  final prefs = await SharedPreferences.getInstance();
  final store = DurablePrefsStore(prefs);
  stage1AntiTamperPrefsStore = store;
  stage1DesiredMonitoringPrefsStore = store;
  stage1DeviceLockPrefsStore = store;
  stage1NotificationPrefsStore = store;
  stage1OnboardingProgressStore = store;
  stage1PrivacyCollectionPrefsStore = store;
  stage1SchedulePrefsStore = store;
  stage1PolicyPrefsStore = store;
  stage1SmartModePrefsStore = store;
  stage1SosLadderStore = store;
  stage1TimeRequestPrefsStore = store;
  stage1WebFilterPrefsStore = store;
  stage1WebUnlockPrefsStore = store;
}
