final _foundationGateUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isFoundationGateUuid(String value) => _foundationGateUuid.hasMatch(value);

class FoundationGateConfiguration {
  FoundationGateConfiguration._(this.stagingApiOrigin);

  factory FoundationGateConfiguration.fromStagingApiOrigin(Uri origin) {
    if (
        origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError.value(origin, 'origin', 'A canonical HTTPS staging origin is required.');
    }
    return FoundationGateConfiguration._(origin.replace(path: ''));
  }

  final Uri stagingApiOrigin;

  Uri get familyDiscoveryUri => stagingApiOrigin.replace(path: '/v1/me/families');

  Uri childrenRosterUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(familyId, 'familyId', 'A server-returned UUID family identifier is required.');
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/children');
  }

  Uri familyDevicesUri(String familyId) {
    if (!isFoundationGateUuid(familyId)) {
      throw ArgumentError.value(familyId, 'familyId', 'A server-returned UUID family identifier is required.');
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/devices');
  }

  Uri familyChildDevicesUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError('Server-returned UUID family and child identifiers are required.');
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/children/$childId/devices');
  }

  Uri deviceTelemetryUri(String deviceId) {
    if (!isFoundationGateUuid(deviceId)) {
      throw ArgumentError.value(deviceId, 'deviceId', 'A server-returned UUID device identifier is required.');
    }
    return stagingApiOrigin.replace(path: '/v1/devices/$deviceId/telemetry');
  }

  Uri familyChildDevicePairingsUri(String familyId, String childId) {
    if (!isFoundationGateUuid(familyId) || !isFoundationGateUuid(childId)) {
      throw ArgumentError('Server-returned UUID family and child identifiers are required.');
    }
    return stagingApiOrigin.replace(path: '/v1/families/$familyId/children/$childId/device-pairings');
  }

  Uri get devicePairingClaimUri => stagingApiOrigin.replace(path: '/v1/device-pairings/claim');
}
