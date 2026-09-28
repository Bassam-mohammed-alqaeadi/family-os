import 'package:family_os/features/n08_platform/smart_alerts_models.dart';

abstract class SmartAlertsRepository {
  Future<SmartAlertsSnapshot> load();
  Future<SmartAlertsSnapshot> setToolEnabled(String toolId, bool enabled);
}

final class InMemorySmartAlertsRepository implements SmartAlertsRepository {
  InMemorySmartAlertsRepository({SmartAlertsSnapshot? seed})
      : _snap = seed ?? smartAlertsEmptyFixture();

  SmartAlertsSnapshot _snap;
  Future<void> Function()? loadGate;

  @override
  Future<SmartAlertsSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return SmartAlertsSnapshot(
      alerts: List<SmartAlertItem>.from(_snap.alerts),
      tools: List<SmartWatchTool>.from(_snap.tools),
    );
  }

  @override
  Future<SmartAlertsSnapshot> setToolEnabled(
    String toolId,
    bool enabled,
  ) async {
    final tools = List<SmartWatchTool>.from(_snap.tools);
    final idx = tools.indexWhere((t) => t.id == toolId);
    if (idx != -1) {
      tools[idx] = tools[idx].copyWith(enabled: enabled);
      _snap = SmartAlertsSnapshot(alerts: _snap.alerts, tools: tools);
    }
    return load();
  }

  void seed(SmartAlertsSnapshot snap) => _snap = snap;
}

/// Shared Stage-1 — empty until Local FS-007 / Advisor events (CE-B5 / CE-G011).
SmartAlertsRepository stage1SmartAlertsRepository =
    InMemorySmartAlertsRepository(seed: smartAlertsEmptyFixture());

void rebindStage1SmartAlertsRepository(SmartAlertsRepository repository) {
  stage1SmartAlertsRepository = repository;
}

SmartAlertsSnapshot smartAlertsEmptyFixture() => const SmartAlertsSnapshot();

SmartAlertsSnapshot smartAlertsOneFixture() {
  return const SmartAlertsSnapshot(
    alerts: [
      SmartAlertItem(
        id: 'a1',
        kind: SmartAlertKind.withdrawal,
        titleKey: 'withdrawal',
        subtitleKey: 'withdrawalSub',
        tagKey: 'new',
      ),
    ],
    tools: [
      SmartWatchTool(
        id: 'searchScan',
        titleKey: 'searchScan',
        subtitleKey: 'searchScanSub',
        enabled: true,
      ),
    ],
  );
}

/// LOCAL_DEMO / tests only — not production stage1 default (CE-B5).
SmartAlertsSnapshot smartAlertsPrototypeFixture() {
  return const SmartAlertsSnapshot(
    alerts: [
      SmartAlertItem(
        id: 'a1',
        kind: SmartAlertKind.withdrawal,
        titleKey: 'withdrawal',
        subtitleKey: 'withdrawalSub',
        tagKey: 'new',
      ),
      SmartAlertItem(
        id: 'a2',
        kind: SmartAlertKind.arabiziPhrase,
        titleKey: 'arabizi',
        subtitleKey: 'arabiziSub',
        tagKey: 'yesterday',
      ),
    ],
    tools: [
      SmartWatchTool(
        id: 'searchScan',
        titleKey: 'searchScan',
        subtitleKey: 'searchScanSub',
        enabled: true,
      ),
      SmartWatchTool(
        id: 'imageScan',
        titleKey: 'imageScan',
        subtitleKey: 'imageScanSub',
        enabled: true,
      ),
      SmartWatchTool(
        id: 'screenshot',
        titleKey: 'screenshot',
        subtitleKey: 'screenshotSub',
        enabled: false,
      ),
      SmartWatchTool(
        id: 'offline',
        titleKey: 'offline',
        subtitleKey: 'offlineSub',
        enabled: true,
      ),
    ],
  );
}
