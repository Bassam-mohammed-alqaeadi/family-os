enum FoundationGatePhase {
  unconfigured,
  signedOut,
  signingIn,
  loadingFamilies,
  familiesAvailable,
  noActiveFamily,
  signInFailed,
  sessionInvalid,
  accessDenied,
  serviceUnavailable,
  networkUnavailable,
}

class FoundationGateFamily {
  const FoundationGateFamily({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final String role;
}

enum FoundationGateApiFailure {
  unauthenticated,
  accessDenied,
  serviceUnavailable,
  networkUnavailable,
  invalidResponse,
}

class FoundationGateApiException implements Exception {
  const FoundationGateApiException(this.failure);

  final FoundationGateApiFailure failure;
}

class FoundationGateIdentityException implements Exception {
  const FoundationGateIdentityException();
}
