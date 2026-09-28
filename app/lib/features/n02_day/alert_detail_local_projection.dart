import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n06_notifications/family_alert_catalog.dart';

/// Notifications core — project SOS + tamper into FAT-020 from local producers.
///
/// Title/body are kind keys resolved by [AlertDetailScreen] via ARB (Rule 12).
/// Wire-later kinds (stranger/battery/games/arrive) stay on the inner mock.
final class ProjectingAlertDetailRepository implements AlertDetailRepository {
  ProjectingAlertDetailRepository({
    AlertDetailRepository? inner,
    SosAlertRepository? sos,
    AntiTamperAlertBus? tamperBus,
  }) : _inner = inner ?? InMemoryAlertDetailRepository(),
       _sos = sos,
       _tamperBus = tamperBus;

  final AlertDetailRepository _inner;
  final SosAlertRepository? _sos;
  final AntiTamperAlertBus? _tamperBus;

  /// Acknowledged projected ids (tamper) for this session.
  final Set<String> _acked = {};

  @override
  Future<AlertDetail?> load({String? alertId, String? alertKind}) async {
    final id = alertId?.trim();
    final rawKind = alertKind?.trim().toLowerCase();
    final kind = AlertDetailKind.tryParse(alertKind) ?? _kindFromId(id);

    if (id == 'sos-active' ||
        kind == AlertDetailKind.sos ||
        rawKind == FamilyAlertKinds.sos) {
      final projected = await _projectSos(id: id ?? 'sos-active');
      if (projected != null) return projected;
    }

    if ((id != null && id.startsWith('tamper-')) ||
        kind == AlertDetailKind.tamper ||
        rawKind == FamilyAlertKinds.tamper) {
      final projected = _projectTamper(id: id);
      if (projected != null) return projected;
    }

    return _inner.load(alertId: alertId, alertKind: alertKind);
  }

  @override
  Future<AlertDetail> markPrimaryDone(String alertId) async {
    if (alertId == 'sos-active' || alertId.startsWith('tamper-')) {
      _acked.add(alertId);
      final loaded = await load(alertId: alertId);
      if (loaded == null) {
        throw StateError('projected alert not found: $alertId');
      }
      return loaded.copyWith(primaryDone: true);
    }
    return _inner.markPrimaryDone(alertId);
  }

  AlertDetailKind? _kindFromId(String? id) {
    if (id == null || id.isEmpty) return null;
    if (id == 'sos-active') return AlertDetailKind.sos;
    if (id.startsWith('tamper-')) return AlertDetailKind.tamper;
    return null;
  }

  Future<AlertDetail?> _projectSos({required String id}) async {
    final sosRepo = _sos ?? stage1SosAlertRepository;
    try {
      final active = await sosRepo.loadActive();
      if (active == null || !active.isActive) {
        // Allow opening the hub row even if SOS just cleared.
        if (id != 'sos-active') return null;
      }
    } catch (_) {
      if (id != 'sos-active') return null;
    }

    return AlertDetail(
      id: id,
      kind: AlertDetailKind.sos,
      childId: '',
      urgency: AlertUrgency.critical,
      // Localized in AlertDetailScreen via kind.
      title: '',
      body: '',
      advice: '',
      primaryDone: _acked.contains(id),
    );
  }

  AlertDetail? _projectTamper({String? id}) {
    final bus = _tamperBus ?? stage1AntiTamperAlertBus;
    final delivered = bus.delivered;
    if (delivered.isEmpty && (id == null || id.isEmpty)) return null;

    var resolvedId = id ?? '';
    var childId = '';
    if (resolvedId.isEmpty) {
      final latest = delivered.last;
      childId = latest.childId.value;
      resolvedId =
          'tamper-${latest.childId.value}-${latest.at.millisecondsSinceEpoch}';
    } else if (resolvedId.startsWith('tamper-')) {
      final parts = resolvedId.split('-');
      if (parts.length >= 2) childId = parts[1];
    }

    return AlertDetail(
      id: resolvedId,
      kind: AlertDetailKind.tamper,
      childId: childId,
      urgency: AlertUrgency.critical,
      title: '',
      body: '',
      advice: '',
      primaryDone: _acked.contains(resolvedId),
    );
  }
}

/// Soft-bind FAT-020 to local SOS/tamper producers (main / composition root).
void tryBindStage1AlertDetailProjection() {
  rebindStage1AlertDetailRepository(ProjectingAlertDetailRepository());
}
