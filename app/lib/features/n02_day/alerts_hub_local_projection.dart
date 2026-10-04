import 'package:family_os/core/app_control/app_control_install.dart';
import 'package:family_os/core/app_control/app_control_runtime.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/location/geofence_event.dart';
import 'package:family_os/core/location/location_repository.dart';
import 'package:family_os/core/policy/anti_tamper_alert_bus.dart';
import 'package:family_os/core/policy/notification_prefs_repository.dart';
import 'package:family_os/core/policy/sos_alert_repository.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_runtime.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/children_list_local_repository.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/location_ux_bridge.dart';
import 'package:family_os/features/n02_day/outer_circle_repository.dart';
import 'package:family_os/features/n03_screen_time/child_time_request_repository.dart';
import 'package:family_os/features/n06_notifications/family_alert_catalog.dart';

/// VX-B5 / FVX-S-02 — read-only hub projection from local producers.
///
/// Sources: active SOS, anti-tamper bus, pending time requests, pending
/// app-install tickets, pending friend requests. Empty when nothing happened.
/// Child-request rows respect [NotificationPrefs.childRequestsEnabled] for the
/// active guardian ([resolvePrefsMemberId] / [prefsMemberId]).
final class ProjectingAlertsHubRepository implements AlertsHubRepository {
  ProjectingAlertsHubRepository({
    SosAlertRepository? sos,
    AntiTamperAlertBus? tamperBus,
    Future<List<TimeRequest>> Function()? listTimePending,
    OuterCircleRepository? outerCircle,
    ChildrenListRepository? children,
    FamilyId Function()? familyId,
    Future<List<AppInstallTicket>> Function(ChildId childId)? listAppPending,
    NotificationPrefsRepository? notificationPrefs,
    String prefsMemberId = 'father',
    String Function()? resolvePrefsMemberId,
    LocationDomainRepository? locationDomain,
    Future<List<GeofenceEvent>> Function()? listGeofenceEvents,
  }) : _sos = sos,
       _tamperBus = tamperBus,
       _listTimePending = listTimePending,
       _outerCircle = outerCircle,
       _children = children,
       _familyId = familyId,
       _listAppPending = listAppPending,
       _notificationPrefs = notificationPrefs,
       _prefsMemberId = prefsMemberId,
       _resolvePrefsMemberId = resolvePrefsMemberId,
       _locationDomain = locationDomain,
       _listGeofenceEvents = listGeofenceEvents;

  final SosAlertRepository? _sos;
  final AntiTamperAlertBus? _tamperBus;
  final Future<List<TimeRequest>> Function()? _listTimePending;
  final OuterCircleRepository? _outerCircle;
  final ChildrenListRepository? _children;
  final FamilyId Function()? _familyId;
  final Future<List<AppInstallTicket>> Function(ChildId childId)?
  _listAppPending;
  final NotificationPrefsRepository? _notificationPrefs;
  final String _prefsMemberId;
  final String Function()? _resolvePrefsMemberId;
  final LocationDomainRepository? _locationDomain;
  final Future<List<GeofenceEvent>> Function()? _listGeofenceEvents;

  String get _activePrefsMemberId =>
      _resolvePrefsMemberId?.call() ?? _prefsMemberId;

  Future<bool> _childRequestsEnabled() async {
    try {
      final repo = _notificationPrefs ?? PrefsMiscRuntime.notification;
      if (repo == null) return true;
      final prefs = await repo.load(_activePrefsMemberId);
      return prefs.childRequestsEnabled;
    } catch (_) {
      return true;
    }
  }

  Future<List<GeofenceEvent>> _loadGeofenceEvents(FamilyId family) async {
    if (_listGeofenceEvents != null) return _listGeofenceEvents();
    try {
      await Stage1LocationRuntime.ensureOpen();
      final domain = _locationDomain ?? Stage1LocationRuntime.store;
      return domain.listGeofenceEvents(family, limit: 12);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<AlertsHubSnapshot> load() async {
    final critical = <HubAlert>[];
    final attention = <HubAlert>[];
    final reassurance = <HubAlert>[];
    final allowChildRequests = await _childRequestsEnabled();

    final sosRepo = _sos ?? stage1SosAlertRepository;
    try {
      final active = await sosRepo.loadActive();
      if (active != null && active.isActive) {
        critical.add(
          const HubAlert(
            id: 'sos-active',
            urgency: AlertUrgency.critical,
            titleKey: 'sos',
            subtitleKey: 'sos',
            emoji: '🚨',
            swatch: DayChildSwatch.purple,
            target: HubAlertTarget.alertDetail,
            alertKind: FamilyAlertKinds.sos,
          ),
        );
      }
    } catch (_) {}

    final bus = _tamperBus ?? stage1AntiTamperAlertBus;
    for (final a in bus.delivered.reversed.take(5)) {
      critical.add(
        HubAlert(
          id: 'tamper-${a.childId.value}-${a.at.millisecondsSinceEpoch}',
          urgency: AlertUrgency.critical,
          titleKey: 'tamper',
          subtitleKey: 'tamper',
          emoji: '🛡',
          swatch: DayChildSwatch.amber,
          target: HubAlertTarget.alertDetail,
          alertKind: FamilyAlertKinds.tamper,
        ),
      );
    }

    if (allowChildRequests) {
      try {
        final pending =
            await (_listTimePending ?? stage1TimeRequestService.listPending)();
        for (final r in pending) {
          attention.add(
            HubAlert(
              id: 'tr-${r.id}',
              urgency: AlertUrgency.attention,
              titleKey: 'time',
              subtitleKey: 'time',
              emoji: '⏳',
              swatch: DayChildSwatch.purple,
              target: HubAlertTarget.timeRequests,
              alertKind: FamilyAlertKinds.timeRequest,
            ),
          );
        }
      } catch (_) {}

      try {
        final circle = await (_outerCircle ?? stage1OuterCircleRepository)
            .load();
        for (final m in circle.pending) {
          attention.add(
            HubAlert(
              id: 'friend-${m.id}',
              urgency: AlertUrgency.attention,
              titleKey: 'friend',
              subtitleKey: 'friend',
              emoji: '🤝',
              swatch: DayChildSwatch.sky,
              target: HubAlertTarget.friendApproval,
              alertKind: FamilyAlertKinds.friendRequest,
            ),
          );
        }
      } catch (_) {}

      try {
        final family = _familyId?.call() ?? ChildrenListLocalSeed.famStage1;
        final kids = await (_children ?? stage1ChildrenListRepository)
            .listChildren(familyId: family);
        await Stage1AppControlRuntime.ensureOpen();
        final service = Stage1AppControlRuntime.service;
        for (final kid in kids) {
          final childId = ChildId(kid.id);
          final listApp = _listAppPending;
          final tickets = listApp != null
              ? await listApp(childId)
              : await service.listPendingInstalls(childId);
          for (final t in tickets) {
            if (t.status != AppInstallDecisionStatus.pendingDecision) continue;
            attention.add(
              HubAlert(
                id: 'app-${t.id}',
                urgency: AlertUrgency.attention,
                titleKey: 'app',
                subtitleKey: 'app',
                emoji: '📱',
                swatch: DayChildSwatch.amber,
                target: HubAlertTarget.appApproval,
                alertKind: FamilyAlertKinds.appApproval,
              ),
            );
          }
        }
      } catch (_) {}
    }

    // LOCATION-1 — Local geofence samples → mailbox (arrive / leaveZone live).
    try {
      final family = _familyId?.call() ?? ChildrenListLocalSeed.famStage1;
      final events = await _loadGeofenceEvents(family);
      for (final e in events.reversed.take(8)) {
        switch (e.kind) {
          case GeofenceEventKind.exit:
            critical.add(
              HubAlert(
                id: 'leave-${e.eventId}',
                urgency: AlertUrgency.critical,
                titleKey: 'leaveZone',
                subtitleKey: 'leaveZone',
                emoji: '🚪',
                swatch: DayChildSwatch.amber,
                target: HubAlertTarget.alertDetail,
                alertKind: FamilyAlertKinds.leaveZone,
              ),
            );
          case GeofenceEventKind.enter:
            reassurance.add(
              HubAlert(
                id: 'arrive-${e.eventId}',
                urgency: AlertUrgency.reassurance,
                titleKey: 'arrive',
                subtitleKey: 'arrive',
                emoji: '📍',
                swatch: DayChildSwatch.sky,
                target: HubAlertTarget.alertDetail,
                alertKind: FamilyAlertKinds.arriveSafe,
              ),
            );
          case GeofenceEventKind.noShow:
            attention.add(
              HubAlert(
                id: 'noshow-${e.eventId}',
                urgency: AlertUrgency.attention,
                titleKey: 'arrive',
                subtitleKey: 'arrive',
                emoji: '⏰',
                swatch: DayChildSwatch.amber,
                target: HubAlertTarget.alertDetail,
                alertKind: FamilyAlertKinds.arriveSafe,
              ),
            );
        }
      }
    } catch (_) {}

    return AlertsHubSnapshot(
      critical: List.unmodifiable(critical),
      attention: List.unmodifiable(attention),
      reassurance: List.unmodifiable(reassurance),
    );
  }
}

/// Soft-bind hub to local producers (main / composition root).
void tryBindStage1AlertsHubProjection() {
  rebindStage1AlertsHubRepository(ProjectingAlertsHubRepository());
}
