import 'dart:async';

/// Per-permission status on a linked child device (`device_permission`).
enum DevicePermissionStatus {
  /// OS granted — healthy signal.
  granted,

  /// Soft deny — repair CTA + settings deep-link.
  denied,

  /// OS / OEM permanent block (RESTRICTED_BY_OS) — not parent reject.
  permanentlyDenied,
}

/// Named permissions surfaced on SCR-FAT-026.
enum DevicePermissionKind {
  locationAlways,
  accessibility,
  batteryExemption,
  autoStart,
}

/// Aggregate card health (`device_health`).
enum DeviceHealthLevel {
  /// All critical permissions granted — green card.
  healthy,

  /// Missing / blocked permission — amber repair path.
  atRisk,

  /// Heartbeat stale — show last known health offline.
  offline,
}

/// One permission row on the detail screen.
class DevicePermissionRow {
  const DevicePermissionRow({
    required this.kind,
    required this.status,
  });

  final DevicePermissionKind kind;
  final DevicePermissionStatus status;

  DevicePermissionRow copyWith({DevicePermissionStatus? status}) {
    return DevicePermissionRow(
      kind: kind,
      status: status ?? this.status,
    );
  }
}

/// Snapshot for list card + detail (`device` + `device_health` + permissions).
class DeviceHealthSnapshot {
  const DeviceHealthSnapshot({
    required this.deviceId,
    required this.childId,
    required this.displayLabel,
    required this.modelLabel,
    required this.level,
    required this.permissions,
    this.lastHeartbeatAgoLabel,
    this.batteryPercent,
    this.offline = false,
    this.oemFamily,
  });

  final String deviceId;

  /// Parametric child key — never a planted person name (Rule 23 / G8).
  final String childId;

  /// Generic label (e.g. ابن ١) — injected, not hardcoded in widgets.
  final String displayLabel;

  final String modelLabel;
  final DeviceHealthLevel level;
  final List<DevicePermissionRow> permissions;
  final String? lastHeartbeatAgoLabel;
  final int? batteryPercent;

  /// When true, UI shows last health with offline honesty.
  final bool offline;

  /// OEM family for بوابة ٤ guide (e.g. Xiaomi) — brand OK; no person names.
  final String? oemFamily;

  bool get hasRepairableDeny => permissions.any(
        (p) =>
            p.status == DevicePermissionStatus.denied ||
            p.status == DevicePermissionStatus.permanentlyDenied,
      );

  DevicePermissionKind? get firstRepairableKind {
    for (final p in permissions) {
      if (p.status == DevicePermissionStatus.denied ||
          p.status == DevicePermissionStatus.permanentlyDenied) {
        return p.kind;
      }
    }
    return null;
  }

  DeviceHealthSnapshot copyWith({
    DeviceHealthLevel? level,
    List<DevicePermissionRow>? permissions,
    bool? offline,
    String? lastHeartbeatAgoLabel,
    int? batteryPercent,
    String? oemFamily,
  }) {
    return DeviceHealthSnapshot(
      deviceId: deviceId,
      childId: childId,
      displayLabel: displayLabel,
      modelLabel: modelLabel,
      level: level ?? this.level,
      permissions: permissions ?? this.permissions,
      lastHeartbeatAgoLabel:
          lastHeartbeatAgoLabel ?? this.lastHeartbeatAgoLabel,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      offline: offline ?? this.offline,
      oemFamily: oemFamily ?? this.oemFamily,
    );
  }
}

/// Injectable health + permission seam (mock-first Rule 25).
///
/// No permission_handler / platform channels — tests drive grant after
/// simulated OS settings round-trip.
abstract class DeviceHealthSeam {
  /// Live list for SCR-FAT-025 settings-hub device cards.
  Stream<List<DeviceHealthSnapshot>> watchDevices();

  /// Live detail for SCR-FAT-026.
  Stream<DeviceHealthSnapshot?> watchDevice(String deviceId);

  /// Simulate deep-link to OS settings for [kind] on [deviceId].
  Future<bool> openSettings({
    required String deviceId,
    required DevicePermissionKind kind,
  });

  /// Re-check after return from settings (same session — AC2).
  Future<void> recheck(String deviceId);
}

/// Stage-1 shared fake — list + detail share one stream bus.
final FakeDeviceHealthSeam stage1DeviceHealthSeam = FakeDeviceHealthSeam.demo();

/// Controllable fake for Stage-1 / widget tests.
class FakeDeviceHealthSeam implements DeviceHealthSeam {
  FakeDeviceHealthSeam({
    List<DeviceHealthSnapshot>? initial,
    this.grantOnOpenSettings = false,
  }) : _devices = List<DeviceHealthSnapshot>.from(
          initial ?? const <DeviceHealthSnapshot>[],
        );

  /// Default demo: one at-risk device (battery denied) + one healthy.
  factory FakeDeviceHealthSeam.demo() {
    return FakeDeviceHealthSeam(
      initial: [
        DeviceHealthSnapshot(
          deviceId: 'dev_a',
          childId: 'child_a',
          displayLabel: 'ابن ١',
          modelLabel: 'Redmi Note 13',
          level: DeviceHealthLevel.atRisk,
          lastHeartbeatAgoLabel: '٩ د',
          batteryPercent: 32,
          oemFamily: 'Xiaomi',
          permissions: const [
            DevicePermissionRow(
              kind: DevicePermissionKind.locationAlways,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.accessibility,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.batteryExemption,
              status: DevicePermissionStatus.denied,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.autoStart,
              status: DevicePermissionStatus.permanentlyDenied,
            ),
          ],
        ),
        DeviceHealthSnapshot(
          deviceId: 'dev_b',
          childId: 'child_b',
          displayLabel: 'ابن ٢',
          modelLabel: 'Android device',
          level: DeviceHealthLevel.healthy,
          lastHeartbeatAgoLabel: '٢ د',
          batteryPercent: 84,
          permissions: const [
            DevicePermissionRow(
              kind: DevicePermissionKind.locationAlways,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.accessibility,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.batteryExemption,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.autoStart,
              status: DevicePermissionStatus.granted,
            ),
          ],
        ),
      ],
    );
  }

  /// Single-device fixture for AC deny→repair→grant.
  factory FakeDeviceHealthSeam.atRiskBattery({
    bool grantOnOpenSettings = false,
  }) {
    return FakeDeviceHealthSeam(
      grantOnOpenSettings: grantOnOpenSettings,
      initial: [
        DeviceHealthSnapshot(
          deviceId: 'dev_ac',
          childId: 'child_ac',
          displayLabel: 'ابن ١',
          modelLabel: 'Test device',
          level: DeviceHealthLevel.atRisk,
          lastHeartbeatAgoLabel: '٥ د',
          batteryPercent: 40,
          oemFamily: 'Xiaomi',
          permissions: const [
            DevicePermissionRow(
              kind: DevicePermissionKind.locationAlways,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.accessibility,
              status: DevicePermissionStatus.granted,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.batteryExemption,
              status: DevicePermissionStatus.denied,
            ),
            DevicePermissionRow(
              kind: DevicePermissionKind.autoStart,
              status: DevicePermissionStatus.granted,
            ),
          ],
        ),
      ],
    );
  }

  List<DeviceHealthSnapshot> _devices;
  final _controller =
      StreamController<List<DeviceHealthSnapshot>>.broadcast();

  /// When true, [openSettings] flips that permission to granted + re-levels.
  bool grantOnOpenSettings;

  int openSettingsCount = 0;
  int recheckCount = 0;

  List<DeviceHealthSnapshot> get devices =>
      List<DeviceHealthSnapshot>.unmodifiable(_devices);

  void dispose() {
    _controller.close();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<DeviceHealthSnapshot>.from(_devices));
    }
  }

  DeviceHealthLevel _computeLevel(DeviceHealthSnapshot snap) {
    if (snap.offline) return DeviceHealthLevel.offline;
    final hasIssue = snap.permissions.any(
      (p) => p.status != DevicePermissionStatus.granted,
    );
    return hasIssue ? DeviceHealthLevel.atRisk : DeviceHealthLevel.healthy;
  }

  void replaceAll(List<DeviceHealthSnapshot> next) {
    _devices = List<DeviceHealthSnapshot>.from(next);
    _emit();
  }

  /// Test helper — mark device offline while keeping last permissions.
  void setOffline(String deviceId, {required bool offline}) {
    final i = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (i < 0) return;
    final updated = _devices[i].copyWith(offline: offline);
    _devices[i] = updated.copyWith(level: _computeLevel(updated));
    _emit();
  }

  @override
  Stream<List<DeviceHealthSnapshot>> watchDevices() async* {
    yield List<DeviceHealthSnapshot>.from(_devices);
    yield* _controller.stream;
  }

  @override
  Stream<DeviceHealthSnapshot?> watchDevice(String deviceId) {
    return watchDevices().map((list) {
      for (final d in list) {
        if (d.deviceId == deviceId) return d;
      }
      return null;
    });
  }

  @override
  Future<bool> openSettings({
    required String deviceId,
    required DevicePermissionKind kind,
  }) async {
    openSettingsCount++;
    if (grantOnOpenSettings) {
      final i = _devices.indexWhere((d) => d.deviceId == deviceId);
      if (i >= 0) {
        final snap = _devices[i];
        final nextPerms = snap.permissions.map((p) {
          if (p.kind == kind) {
            return p.copyWith(status: DevicePermissionStatus.granted);
          }
          return p;
        }).toList();
        final updated = snap.copyWith(permissions: nextPerms);
        _devices[i] = updated.copyWith(level: _computeLevel(updated));
        _emit();
      }
    }
    return true;
  }

  @override
  Future<void> recheck(String deviceId) async {
    recheckCount++;
    // Re-emit current snapshot — simulates return-from-settings re-check
    // without app reinstall (AC2).
    _emit();
  }
}
