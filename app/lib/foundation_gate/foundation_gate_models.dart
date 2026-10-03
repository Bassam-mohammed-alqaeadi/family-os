enum FoundationGatePhase {
  unconfigured,
  signedOut,
  signingIn,
  loadingFamilies,
  familiesAvailable,
  loadingRoster,
  childrenAvailable,
  noChildren,
  noActiveFamily,
  signInFailed,
  sessionInvalid,
  accessDenied,
  rosterAccessDenied,
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

class FoundationGateChild {
  const FoundationGateChild({
    required this.id,
    required this.displayName,
    required this.ageYears,
  });

  final String id;
  final String displayName;
  final int ageYears;
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
