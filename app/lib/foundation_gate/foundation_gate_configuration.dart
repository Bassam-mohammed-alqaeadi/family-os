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
}
