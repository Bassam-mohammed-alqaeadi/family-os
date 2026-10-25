import 'package:family_os/foundation_gate/family_capability_api_client.dart';
import 'package:family_os/foundation_gate/family_command_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Why the ledger shows what it shows — the same honest states the other server panels use.
///
/// There is no `localFallback` here and there never will be: the whole promise of the capability
/// ledger is that a family sees what the handset actually reported, so a build that cannot ask says
/// that instead of drawing green ticks.
enum DeviceLedgerStatus {
  /// The server answered, and what is on screen is its answer.
  ready,

  /// This build has no server session — no configured origin, no selected family, no token.
  /// Nothing was asked, because there was nobody to ask.
  notConfigured,

  /// The device record this screen is showing is not a server child record, so there is no ledger
  /// to read. Said out loud rather than answered with an empty list that looks like "nothing".
  notLinked,

  /// The server answered that this account may not see this child's devices.
  accessDenied,

  /// The server is configured but did not answer. The last read stays on screen, marked as the
  /// last read.
  unreachable,

  /// The server refused a write, with a reason this screen can state.
  refused,

  /// The server answered, but the answer could not be read. Reported as a defect, never smoothed
  /// into an empty ledger.
  unreadable,
}

/// Which refusal a guardian is being told about. The words live in ARB; this is only which one.
enum DeviceLedgerRefusal {
  none,

  /// The device will not take orders — it is cut off, or its trust was withdrawn.
  deviceNotEligible,

  /// The server refused and gave this build nothing to say.
  unexplained,
}

/// One answer from the spine: a value, or the reason there is none.
class DeviceLedgerAnswer<T> {
  const DeviceLedgerAnswer.ready(this.value)
    : status = DeviceLedgerStatus.ready,
      refusal = DeviceLedgerRefusal.none;

  const DeviceLedgerAnswer.unavailable(
    this.status, [
    this.refusal = DeviceLedgerRefusal.none,
  ]) : value = null;

  final DeviceLedgerStatus status;
  final T? value;
  final DeviceLedgerRefusal refusal;

  bool get isReady => status == DeviceLedgerStatus.ready && value != null;
}

/// One capability line: the server's own record, with nothing added to it.
class DeviceLedgerCapabilityRow {
  const DeviceLedgerCapabilityRow({required this.key, required this.record});

  final FoundationGateCapabilityKey key;
  final FoundationGateCapabilityRecord record;

  bool get confirmed =>
      record.state == FoundationGateCapabilityState.confirmed;
}

/// What one screen holds: the capabilities a device reported, and the orders for it.
///
/// `ordersStatus` is kept separate from `status` on purpose. The capabilities and the orders are
/// two reads, and a screen that loses only the second must say so while still showing the first —
/// not blank the whole panel, and not claim "no orders" when nobody answered.
class DeviceLedgerReading {
  const DeviceLedgerReading({
    required this.capabilities,
    required this.orders,
    this.ordersStatus = DeviceLedgerStatus.ready,
  });

  final List<DeviceLedgerCapabilityRow> capabilities;
  final List<FoundationGateCommand> orders;
  final DeviceLedgerStatus ordersStatus;

  int get workingCount => capabilities.where((row) => row.confirmed).length;

  int get waitingCount => capabilities.length - workingCount;

  /// The capability that gates enforcement, when the phone has confirmed it. `refresh_policy`
  /// needs no capability; `lock_now` and `release_lock` need this one, and the server refuses
  /// without it.
  bool get instantLockConfirmed => capabilities.any(
    (row) => row.key == FoundationGateCapabilityKey.instantLock && row.confirmed,
  );

  DateTime? get lastReportAt {
    DateTime? newest;
    for (final row in capabilities) {
      final at = row.record.reportedAt;
      if (newest == null || at.isAfter(newest)) newest = at;
    }
    return newest;
  }
}

/// The order a guardian reads the ledger in.
///
/// Deliberately not alphabetical and not the server's map order: a parent opens this screen to
/// find out whether the protection they set is actually holding, so what enforces comes first and
/// what merely observes comes after.
const List<FoundationGateCapabilityKey> deviceCapabilityLedgerOrder = [
  FoundationGateCapabilityKey.instantLock,
  FoundationGateCapabilityKey.appBlockOverlay,
  FoundationGateCapabilityKey.accessibilityEnforcement,
  FoundationGateCapabilityKey.usageMetering,
  FoundationGateCapabilityKey.appInventory,
  FoundationGateCapabilityKey.webFilterVpn,
  FoundationGateCapabilityKey.backgroundLocation,
  FoundationGateCapabilityKey.tamperSignals,
  FoundationGateCapabilityKey.pushDelivery,
  FoundationGateCapabilityKey.batteryReporting,
  FoundationGateCapabilityKey.bootPersistence,
];

/// The spine's one server connection for this screen.
///
/// It holds the two clients, the bearer token and the selected family, and it decides nothing:
/// the handset reports what it can do, the server stores that and every order, and this class
/// carries both to a screen — or reports, as a value a screen can render, that it could not.
///
/// **Why this screen offers `refresh_policy` and not the lock.** `lock_now` and `release_lock` are
/// the same decision the screen-time panel already makes, and a platform with two buttons for one
/// power holds two truths about whether a phone is stopped. The server gates those commands on the
/// `instant_lock` capability being `confirmed`; this screen states that gate, shows the receipts of
/// any order that was made, and leaves the decision where it lives. Moving the panel's own lock
/// onto this bus is recorded as the next slice, not quietly half-done here.
final class DeviceLedgerAuthority {
  DeviceLedgerAuthority({
    required this.capabilities,
    required this.commands,
    required this.idToken,
    required this.familyId,
    this.ttlSeconds = 120,
  });

  final FamilyCapabilityApiClient capabilities;
  final FamilyCommandApiClient commands;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// How long an order stays open for the device to take. The server accepts 5..3600 seconds.
  final int ttlSeconds;

  /// The ledger for one child: capabilities for [deviceId] (or the first device the child has),
  /// and the family's orders for that child.
  Future<DeviceLedgerAnswer<DeviceLedgerReading>> read({
    required String childId,
    String? deviceId,
  }) async {
    final gate = await _session(childId, deviceId: deviceId);
    if (gate.status != null) {
      return DeviceLedgerAnswer.unavailable(gate.status!);
    }
    final FoundationGateChildCapabilitiesView view;
    try {
      view = await capabilities.readForChild(
        familyId: gate.familyId!,
        childId: childId,
        idToken: gate.token!,
      );
    } on FoundationGateApiException catch (error) {
      return DeviceLedgerAnswer.unavailable(_statusFor(error.failure));
    } on Object {
      // Something threw that is not an answer at all — a socket that closed, a DNS failure. The
      // honest word for that is unreachable: nobody replied. A reply that arrived and could not be
      // read is a different thing, and the client reports it as `invalidResponse`.
      return const DeviceLedgerAnswer.unavailable(DeviceLedgerStatus.unreachable);
    }
    final List<FoundationGateCommand> orders;
    try {
      orders = await commands.listForFamily(
        familyId: gate.familyId!,
        idToken: gate.token!,
        childId: childId,
        deviceId: deviceId,
        limit: 50,
      );
    } on FoundationGateApiException catch (error) {
      return DeviceLedgerAnswer.ready(
        DeviceLedgerReading(
          capabilities: _rowsFor(view, deviceId),
          orders: const <FoundationGateCommand>[],
          ordersStatus: _statusFor(error.failure),
        ),
      );
    } on Object {
      // The same rule as the read above: no answer is unreachable, not unreadable.
      return const DeviceLedgerAnswer.unavailable(DeviceLedgerStatus.unreachable);
    }
    return DeviceLedgerAnswer.ready(
      DeviceLedgerReading(
        capabilities: _rowsFor(view, deviceId),
        orders: orders,
      ),
    );
  }

  /// Ask the device to take the stored policy again: one order, and the server's own state comes
  /// back as the answer — never a local "done".
  Future<DeviceLedgerAnswer<FoundationGateCommand>> requestPolicyRefresh({
    required String childId,
    required String deviceId,
    required String idempotencyKey,
  }) async {
    final gate = await _session(childId, deviceId: deviceId);
    if (gate.status != null) {
      return DeviceLedgerAnswer.unavailable(gate.status!);
    }
    try {
      final created = await commands.createCommand(
        familyId: gate.familyId!,
        childId: childId,
        deviceId: deviceId,
        commandType: FoundationGateCommandType.refreshPolicy,
        idempotencyKey: idempotencyKey,
        idToken: gate.token!,
        ttlSeconds: ttlSeconds,
      );
      return DeviceLedgerAnswer.ready(created);
    } on FoundationGateApiException catch (error) {
      return DeviceLedgerAnswer.unavailable(
        _statusForWrite(error.failure),
        _refusalForWrite(error.failure),
      );
    } on Object {
      return const DeviceLedgerAnswer.unavailable(DeviceLedgerStatus.unreachable);
    }
  }

  /// The bound authority, or none.
  ///
  /// A screen must be able to say "this build has no server" and mean it, which is why the binding
  /// is a plain nullable global with no fake default behind it — the same shape the screen-time,
  /// location, filter and task authorities use.
  static DeviceLedgerAuthority? _bound;

  static void bind(DeviceLedgerAuthority? authority) => _bound = authority;

  static DeviceLedgerAuthority? get bound => _bound;

  Future<_LedgerGate> _session(String childId, {String? deviceId}) async {
    if (!isFoundationGateUuid(childId)) {
      return const _LedgerGate(DeviceLedgerStatus.notLinked);
    }
    // A device id that is not a server id cannot be asked for anything, and it must not
    // be sent to be rejected: the clients throw on it, and that throw would arrive on the
    // screen as a fact about the family. `notLinked` is the sentence a parent or a
    // developer can act on - this record is not a server device.
    if (deviceId != null && !isFoundationGateUuid(deviceId)) {
      return const _LedgerGate(DeviceLedgerStatus.notLinked);
    }
    final family = familyId();
    if (family == null || !isFoundationGateUuid(family)) {
      return const _LedgerGate(DeviceLedgerStatus.notConfigured);
    }
    final token = await idToken();
    if (token.trim().isEmpty) {
      return const _LedgerGate(DeviceLedgerStatus.notConfigured);
    }
    return _LedgerGate.ready(familyId: family, token: token);
  }

  static List<DeviceLedgerCapabilityRow> _rowsFor(
    FoundationGateChildCapabilitiesView view,
    String? deviceId,
  ) {
    FoundationGateDeviceCapabilities? device;
    for (final candidate in view.devices) {
      if (deviceId == null || candidate.deviceId == deviceId) {
        device = candidate;
        break;
      }
    }
    if (device == null) return const <DeviceLedgerCapabilityRow>[];
    final rows = <DeviceLedgerCapabilityRow>[
      for (final entry in device.capabilities.entries)
        DeviceLedgerCapabilityRow(key: entry.key, record: entry.value),
    ];
    rows.sort((a, b) {
      final byOrder = deviceCapabilityLedgerOrder
          .indexOf(a.key)
          .compareTo(deviceCapabilityLedgerOrder.indexOf(b.key));
      if (byOrder != 0) return byOrder;
      return a.record.reportedAt.compareTo(b.record.reportedAt);
    });
    return List<DeviceLedgerCapabilityRow>.unmodifiable(rows);
  }

  /// What a refused write means on screen.
  ///
  /// A 404 is not the same sentence as it is on a read: nobody was looking for a record,
  /// a guardian asked a device to act and was told it will not take orders. And a refusal
  /// carries a reason only when the server actually gave one this build can name - silence
  /// is reported as silence, never as a broken answer.
  static DeviceLedgerStatus _statusForWrite(FoundationGateApiFailure failure) =>
      switch (failure) {
        FoundationGateApiFailure.notFound => DeviceLedgerStatus.refused,
        _ => _statusFor(failure),
      };

  static DeviceLedgerRefusal _refusalForWrite(FoundationGateApiFailure failure) =>
      switch (failure) {
        FoundationGateApiFailure.notFound =>
          DeviceLedgerRefusal.deviceNotEligible,
        FoundationGateApiFailure.conflict ||
        FoundationGateApiFailure.invalidInput =>
          DeviceLedgerRefusal.unexplained,
        _ => DeviceLedgerRefusal.none,
      };

  static DeviceLedgerStatus _statusFor(FoundationGateApiFailure failure) =>
      switch (failure) {
        FoundationGateApiFailure.unauthenticated => DeviceLedgerStatus
            .notConfigured,
        FoundationGateApiFailure.accessDenied => DeviceLedgerStatus.accessDenied,
        FoundationGateApiFailure.networkUnavailable => DeviceLedgerStatus
            .unreachable,
        FoundationGateApiFailure.serviceUnavailable => DeviceLedgerStatus
            .unreachable,
        FoundationGateApiFailure.notFound => DeviceLedgerStatus.notLinked,
        FoundationGateApiFailure.conflict => DeviceLedgerStatus.refused,
        FoundationGateApiFailure.invalidInput => DeviceLedgerStatus.refused,
        FoundationGateApiFailure.invalidResponse => DeviceLedgerStatus
            .unreadable,
      };
}

/// Either a family and a token to ask with, or the reason there is nothing to ask with.
class _LedgerGate {
  const _LedgerGate(this.status)
    : familyId = null,
      token = null;

  const _LedgerGate.ready({required this.familyId, required this.token})
    : status = null;

  final DeviceLedgerStatus? status;
  final String? familyId;
  final String? token;
}
