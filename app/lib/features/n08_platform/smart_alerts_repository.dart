import 'package:family_os/features/n08_platform/smart_alerts_models.dart';

abstract class SmartAlertsRepository {
  Future<SmartAlertsSnapshot> load();
  Future<SmartAlertsSnapshot> setToolEnabled(String toolId, bool enabled);
}

final class InMemorySmartAlertsRepository implements SmartAlertsRepository {
  InMemorySmartAlertsRepository({SmartAlertsSnapshot? seed})
    : _snap = seed ?? smartAlertsPrototypeFixture();

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

final InMemorySmartAlertsRepository stage1SmartAlertsRepository =
    InMemorySmartAlertsRepository();

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
