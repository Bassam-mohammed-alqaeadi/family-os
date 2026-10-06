/// Client mirror of the server's `device-lifecycle.v1` contract for one linked
/// device.
///
/// The client parses, validates and renders this. It never derives it.
///
/// That is not a style preference. Whether a child's device is protected is a
/// server decision, and a client that recomputed the answer could disagree with
/// the server about a child's safety - which is the one disagreement a family
/// safety product cannot have. The server owns the capability, the health state,
/// the reason and the attention flag; this file only makes sure the values it
/// receives are ones it understands, and refuses the whole device if any of them
/// is not.
///
/// Nothing here is user-facing prose. Reason codes are machine values, and
/// [DeviceLifecycleCopy] turns them into Arabic or English beside the widget that
/// shows them.
library;

/// The condition of one device. Exactly one applies.
enum FoundationGateDeviceHealthState {
  revoked('revoked'),
  awaitingPairing('awaiting_pairing'),
  neverReported('never_reported'),
  active('active'),
  stale('stale'),
  offline('offline');

  const FoundationGateDeviceHealthState(this.wireName);

  /// The exact string the server sends. Kept explicit so a rename on either side
  /// fails the parse instead of silently changing what a guardian is told.
  final String wireName;

  static FoundationGateDeviceHealthState? fromWire(String? value) {
    for (final state in values) {
      if (state.wireName == value) {
        return state;
      }
    }
    return null;
  }
}

/// The condition of one capability a device either has or does not have.
enum FoundationGateDeviceCapabilityState {
  available('available'),
  stale('stale'),
  unavailable('unavailable');

  const FoundationGateDeviceCapabilityState(this.wireName);

  final String wireName;

  static FoundationGateDeviceCapabilityState? fromWire(String? value) {
    for (final state in values) {
      if (state.wireName == value) {
        return state;
      }
    }
    return null;
  }
}

/// The credential lifecycle of a device. `unclaimed` means a guardian registered
/// it but no handset has claimed the pairing yet.
enum FoundationGateDeviceCredentialState {
  unclaimed('unclaimed'),
  active('active'),
  revoked('revoked');

  const FoundationGateDeviceCredentialState(this.wireName);

  final String wireName;

  static FoundationGateDeviceCredentialState? fromWire(String? value) {
    for (final state in values) {
      if (state.wireName == value) {
        return state;
      }
    }
    return null;
  }
}

/// One capability, with the server's reason for its state and the moment that
/// state began.
class FoundationGateDeviceCapability {
  const FoundationGateDeviceCapability({
    required this.id,
    required this.state,
    required this.reasonCode,
    required this.since,
  });

  final String id;
  final FoundationGateDeviceCapabilityState state;
  final String reasonCode;
  final DateTime? since;
}

/// The server's verdict on a device, including whether it should reach the
/// guardian at all.
class FoundationGateDeviceHealth {
  const FoundationGateDeviceHealth({
    required this.state,
    required this.reasonCode,
    required this.since,
    required this.needsAttention,
  });

  final FoundationGateDeviceHealthState state;
  final String reasonCode;
  final DateTime? since;

  /// The server's decision, rendered as given rather than recomputed here, so the
  /// rule about which devices are allowed to speak lives in exactly one place.
  final bool needsAttention;
}

/// A device as the guardian is allowed to see it.
class FoundationGateGuardianDevice {
  const FoundationGateGuardianDevice({
    required this.id,
    required this.childId,
    required this.deviceLabel,
    required this.credentialState,
    required this.batteryLevel,
    required this.batteryStatus,
    required this.locationLabel,
    required this.lastSeenAt,
    required this.linkedAt,
    required this.capabilities,
    required this.health,
  });

  final String id;
  final String childId;
  final String deviceLabel;
  final FoundationGateDeviceCredentialState credentialState;
  final int? batteryLevel;
  final String? batteryStatus;
  final String? locationLabel;
  final DateTime? lastSeenAt;
  final DateTime? linkedAt;
  final List<FoundationGateDeviceCapability> capabilities;
  final FoundationGateDeviceHealth health;
}

/// Parse one device from a server response.
///
/// Returns null when anything is unknown or malformed. A device this client
/// cannot fully understand is not shown as a device whose condition is known:
/// dropping it is the only honest option, because a partially parsed device would
/// be rendered with a made-up capability state.
FoundationGateGuardianDevice? parseFoundationGateGuardianDevice(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final id = value['id'];
  final childId = value['childId'];
  final deviceLabel = value['deviceLabel'];
  if (id is! String || id.isEmpty) {
    return null;
  }
  if (childId is! String || childId.isEmpty) {
    return null;
  }
  if (deviceLabel is! String || deviceLabel.trim().isEmpty) {
    return null;
  }

  final credentialState = FoundationGateDeviceCredentialState.fromWire(
    value['credentialState'] as String?,
  );
  if (credentialState == null) {
    return null;
  }

  final rawCapabilities = value['capabilities'];
  if (rawCapabilities is! List) {
    return null;
  }
  final capabilities = <FoundationGateDeviceCapability>[];
  for (final raw in rawCapabilities) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final capabilityId = raw['id'];
    final state = FoundationGateDeviceCapabilityState.fromWire(
      raw['state'] as String?,
    );
    final reasonCode = raw['reasonCode'];
    if (capabilityId is! String || capabilityId.isEmpty) {
      return null;
    }
    if (state == null || reasonCode is! String || reasonCode.isEmpty) {
      return null;
    }
    capabilities.add(
      FoundationGateDeviceCapability(
        id: capabilityId,
        state: state,
        reasonCode: reasonCode,
        since: _parseTimestamp(raw['since']),
      ),
    );
  }
  if (capabilities.isEmpty) {
    return null;
  }

  final rawHealth = value['health'];
  if (rawHealth is! Map<String, dynamic>) {
    return null;
  }
  final healthState = FoundationGateDeviceHealthState.fromWire(
    rawHealth['state'] as String?,
  );
  final reasonCode = rawHealth['reasonCode'];
  final needsAttention = rawHealth['needsAttention'];
  if (healthState == null || reasonCode is! String || reasonCode.isEmpty) {
    return null;
  }
  // The flag is required rather than defaulted. A missing flag would let a device
  // that needs help slip into the silent set, and silence is what a healthy device
  // is for.
  if (needsAttention is! bool) {
    return null;
  }

  final batteryLevel = value['batteryLevel'];
  if (batteryLevel != null && batteryLevel is! int) {
    return null;
  }

  return FoundationGateGuardianDevice(
    id: id,
    childId: childId,
    deviceLabel: deviceLabel.trim(),
    credentialState: credentialState,
    batteryLevel: batteryLevel as int?,
    batteryStatus: value['batteryStatus'] as String?,
    locationLabel: value['locationLabel'] as String?,
    lastSeenAt: _parseTimestamp(value['lastSeenAt']),
    linkedAt: _parseTimestamp(value['linkedAt']),
    capabilities: List.unmodifiable(capabilities),
    health: FoundationGateDeviceHealth(
      state: healthState,
      reasonCode: reasonCode,
      since: _parseTimestamp(rawHealth['since']),
      needsAttention: needsAttention,
    ),
  );
}

DateTime? _parseTimestamp(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

/// Group parsed devices by the child they belong to.
///
/// Devices whose payload this client could not fully understand are absent from
/// the result rather than present with guessed values.
Map<String, List<FoundationGateGuardianDevice>> groupFoundationGateDevicesByChild(
  Iterable<Object?> rawDevices,
) {
  final grouped = <String, List<FoundationGateGuardianDevice>>{};
  for (final raw in rawDevices) {
    final device = parseFoundationGateGuardianDevice(raw);
    if (device == null) {
      continue;
    }
    grouped.putIfAbsent(device.childId, () => <FoundationGateGuardianDevice>[]).add(device);
  }
  return grouped;
}

/// The device that should reach the guardian for a child, or null when nothing
/// needs their hand.
///
/// When more than one device is asking for attention, the most serious is chosen
/// by [priorityOf] so the roster can show a single line instead of a list.
FoundationGateGuardianDevice? attentionDeviceForChild(
  Iterable<FoundationGateGuardianDevice> devices,
) {
  FoundationGateGuardianDevice? worst;
  for (final device in devices) {
    if (!device.health.needsAttention) {
      continue;
    }
    if (worst == null || priorityOf(device) > priorityOf(worst)) {
      worst = device;
    }
  }
  return worst;
}

/// How loudly a device should speak. Higher wins.
///
/// A revoked device outranks everything: it is the one state a guardian must act
/// on, because it means the device is not reporting and never will again until it
/// is paired afresh. `never_reported` outranks `offline` because a device that
/// never started is a setup problem, while a device that stopped is a fault.
int priorityOf(FoundationGateGuardianDevice device) {
  return switch (device.health.state) {
    FoundationGateDeviceHealthState.revoked => 5,
    FoundationGateDeviceHealthState.neverReported => 4,
    FoundationGateDeviceHealthState.offline => 3,
    FoundationGateDeviceHealthState.stale => 2,
    FoundationGateDeviceHealthState.awaitingPairing => 1,
    FoundationGateDeviceHealthState.active => 0,
  };
}
