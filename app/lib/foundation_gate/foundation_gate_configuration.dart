final _foundationGateUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isFoundationGateUuid(String value) => _foundationGateUuid.hasMatch(value);

class FoundationGateConfiguration {
  FoundationGateConfiguration._(this.stagingApiOrigin);

  factory FoundationGateConfiguration.fromStagingApiOrigin(Uri origin) {
    if (!_isPermittedOrigin(origin) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError.value(
        origin,
        'origin',
        'A canonical HTTPS origin is required. Cleartext HTTP is accepted '
            'only for loopback or private development hosts.',
      );
    }
    return FoundationGateConfiguration._(origin.replace(path: ''));
  }

  /// Cleartext HTTP is permitted only for loopback and private-network
  /// development hosts, where a real Android device reaches a developer
  /// machine. Every public origin must be HTTPS. This boundary is decided
  /// before any networking happens.
  static bool _isPermittedOrigin(Uri origin) {
    if (origin.scheme == 'https') return true;
    if (origin.scheme != 'http') return false;
    return _isLoopbackOrPrivateHost(origin.host);
  }

  static bool _isLoopbackOrPrivateHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' || normalized.endsWith('.localhost')) {
      return true;
    }
    if (normalized.endsWith('.local')) return true; // mDNS development hosts
    if (normalized == '::1') return true; // IPv6 loopback
    final match = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    ).firstMatch(normalized);
    if (match == null) return false;
    final octets = <int>[];
    for (var i = 1; i <= 4; i++) {
      final value = int.tryParse(match.group(i) ?? '');
      if (value == null || value > 255) return false;
      octets.add(value);
    }
    if (octets[0] == 127) return true; // IPv4 loopback
    if (octets[0] == 10) return true; // private class A
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
      return true; // private class B
    }
    if (octets[0] == 192 && octets[1] == 168) return true; // private class C
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
}
