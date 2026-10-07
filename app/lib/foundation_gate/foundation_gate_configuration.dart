final _foundationGateUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isFoundationGateUuid(String value) => _foundationGateUuid.hasMatch(value);

class FoundationGateConfiguration {
  FoundationGateConfiguration._(this.stagingApiOrigin);

  factory FoundationGateConfiguration.fromStagingApiOrigin(Uri origin) {
    if (!_isPermittedStagingOrigin(origin) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError.value(
        origin,
        'origin',
        'A canonical HTTPS staging origin is required. Cleartext HTTP is '
            'accepted only for loopback or private development hosts.',
      );
    }
    return FoundationGateConfiguration._(origin.replace(path: ''));
  }

  /// A public staging origin must be HTTPS: a bearer token and child data
  /// never cross cleartext. HTTP therefore survives only where a real device
  /// reaches a developer machine, and the decision is made before any
  /// networking happens.
  static bool _isPermittedStagingOrigin(Uri origin) {
    if (origin.scheme == 'https') {
      return true;
    }
    if (origin.scheme != 'http') {
      return false;
    }
    return _isLoopbackOrPrivateHost(origin.host);
  }

  /// Loopback, mDNS `.local` and RFC 1918 private ranges are the only hosts
  /// allowed to serve cleartext, because only they are under the developer's
  /// own control.
  static bool _isLoopbackOrPrivateHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' || normalized.endsWith('.localhost')) {
      return true;
    }
    if (normalized.endsWith('.local')) {
      return true;
    }
    if (normalized == '::1') {
      return true;
    }
    final match = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    ).firstMatch(normalized);
    if (match == null) {
      return false;
    }
    final octets = <int>[];
    for (var index = 1; index <= 4; index++) {
      final value = int.tryParse(match.group(index) ?? '');
      if (value == null || value > 255) {
        return false;
      }
      octets.add(value);
    }
    if (octets[0] == 127) {
      return true;
    }
    if (octets[0] == 10) {
      return true;
    }
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
      return true;
    }
    if (octets[0] == 192 && octets[1] == 168) {
      return true;
    }
    return false;
  }

  final Uri stagingApiOrigin;

  Uri get familyDiscoveryUri =>
      stagingApiOrigin.replace(path: '/v1/me/families');

  Uri childrenRosterUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/children');
  }

  Uri familyDevicesUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/devices');
  }

  Uri familyChildDevicesUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/devices',
    );
  }

  Uri deviceTelemetryUri(String deviceId) {
    if (!isFoundationGateUuid(deviceId)) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'A server-returned UUID device identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/telemetry');
  }

  Uri familyChildDevicePairingsUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/device-pairings',
    );
  }

  Uri get devicePairingClaimUri =>
      stagingApiOrigin.replace(path: '/v1/device-pairings/claim');

  /// The family membership roster: read with GET, invite with POST.
  Uri familyMembershipsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/memberships');
  }

  /// The zones this family defined. Read with GET, draw with POST.
  Uri familySafeZonesUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/safe-zones');
  }

  /// One zone: the alert flags move with PATCH, nothing else does.
  Uri familySafeZoneUri(String familyId, String zoneId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(zoneId)) {
      throw ArgumentError(
        'Server-returned UUID family and zone identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/safe-zones/$zoneId',
    );
  }

  /// The family's live picture. One read, one visibility rule for every member.
  Uri familyLocationUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/location');
  }

  /// The trail of one child, under the same one-rule-for-everyone promise as the live read.
  Uri familyChildLocationHistoryUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/location-history',
    );
  }

  /// The arrival and departure feed, newest first.
  Uri familyGeofenceEventsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'A server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/geofence-events',
    );
  }

  /// Where a child device reports its own position. The device id is in the path, so the
  /// device's credential can only ever report for itself.
  Uri deviceLocationFixesUri(String deviceId) {
    if (!isFoundationGateUuid(deviceId)) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'A server-returned UUID device identifier is required.',
      );
    }
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/location-fixes');
  }

  /// The family's emergency incidents. `status` is part of the URL rather than of a body
  /// because it selects rows: an open incident is the one that needs answering, and that
  /// is what the default view asks for.
  Uri familySosAlertsUri(String familyId, {String status = 'open'}) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError(
        'Server-returned UUID family identifier is required.',
      );
    }
    if (!const <String>{'open', 'resolved', 'all'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'open, resolved or all');
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts',
      queryParameters: status == 'open' ? null : <String, String>{'status': status},
    );
  }

  /// One incident, read by every member of the family - the child included.
  Uri familySosAlertUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId',
    );
  }

  /// A guardian opening an incident for a child whose handset is not the one in hand.
  Uri familyChildSosAlertsUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError(
        'Server-returned UUID family and child identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/children/$childId/sos-alerts',
    );
  }

  /// "I have seen this" - deliberately its own path, because it is not closing anything.
  Uri familySosAlertAcknowledgeUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/acknowledge',
    );
  }

  /// Climbing the family's own ladder.
  Uri familySosAlertEscalateUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/escalate',
    );
  }

  /// Closing the incident, with the reason stated.
  Uri familySosAlertResolveUri(String familyId, String alertId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(alertId)) {
      throw ArgumentError(
        'Server-returned UUID family and alert identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-alerts/$alertId/resolve',
    );
  }

  /// The ladder rung 2 and below: the people the family itself trusts.
  Uri familySosBackupContactsUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError(
        'Server-returned UUID family identifier is required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-backup-contacts',
    );
  }

  /// One rung: verify it, renumber it, switch it off or archive it.
  Uri familySosBackupContactUri(String familyId, String contactId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(contactId)) {
      throw ArgumentError(
        'Server-returned UUID family and contact identifiers are required.',
      );
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/sos-backup-contacts/$contactId',
    );
  }

  /// One command on one membership: `accept` or `revoke`.
  Uri membershipCommandUri(String familyId, String membershipId, String command) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(membershipId)) {
      throw ArgumentError(
        'Server-returned UUID family and membership identifiers are required.',
      );
    }
    if (!const <String>{'accept', 'revoke'}.contains(command)) {
      throw ArgumentError.value(command, 'command', 'accept or revoke');
    }
    return stagingApiOrigin.replace(
      path: '/v1/families/$familyId/memberships/$membershipId/$command',
    );
  }
}
