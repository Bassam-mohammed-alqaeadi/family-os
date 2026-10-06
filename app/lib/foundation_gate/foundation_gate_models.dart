import 'dart:math';

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

const Set<String> kFoundationGateChildThemeColors = {
  'purple',
  'sky',
  'amber',
  'coral',
  'mint',
  'teal',
};

class FoundationGateChild {
  const FoundationGateChild({
    required this.id,
    required this.displayName,
    required this.ageYears,
    required this.avatarEmoji,
    required this.themeColor,
  });

  final String id;
  final String displayName;
  final int ageYears;
  final String avatarEmoji;
  final String themeColor;
}

enum FoundationGateChildCreateResult {
  created,
  createdRosterRefreshUnavailable,
  invalidInput,
  conflict,
  accessDenied,
  sessionInvalid,
  serviceUnavailable,
  networkUnavailable,
}

enum FoundationGateApiFailure {
  unauthenticated,
  accessDenied,
  invalidInput,
  conflict,
  serviceUnavailable,
  networkUnavailable,
  invalidResponse,

  /// HTTP 429 on a guess-able endpoint (pairing claim): the peer is locked
  /// for a window after repeated failures. Distinct from a generic outage.
  tooManyAttempts,
}

class FoundationGateApiException implements Exception {
  const FoundationGateApiException(this.failure);

  final FoundationGateApiFailure failure;
}

/// Presentation-safe identity provider outcomes.
///
/// Wrong e-mail and wrong password are deliberately collapsed into
/// [invalidCredentials] so the UI can never be used to enumerate accounts.
/// No provider message, code string or stack is retained.
enum FoundationGateIdentityFailure {
  /// Generic failure (default); nothing more specific can be said safely.
  unknown,

  /// Sign-in rejected: unknown account or wrong password (never distinguished).
  invalidCredentials,

  /// Sign-up rejected because the e-mail already has an account.
  emailAlreadyInUse,

  /// Sign-up rejected because the password does not meet provider policy.
  weakPassword,

  /// The e-mail address is syntactically invalid.
  invalidEmail,

  /// The identity provider could not be reached.
  networkUnavailable,

  /// Too many attempts; the provider is throttling this device/account.
  tooManyAttempts,

  /// The account exists but has been disabled by an administrator.
  accountDisabled,

  /// No current provider session (signed out or token refresh failed).
  noSession,
}

class FoundationGateIdentityException implements Exception {
  const FoundationGateIdentityException([
    this.failure = FoundationGateIdentityFailure.unknown,
  ]);

  final FoundationGateIdentityFailure failure;

  @override
  String toString() => 'FoundationGateIdentityException($failure)';
}

/// Produces a local, opaque UUID-shaped idempotency key for one user attempt.
///
/// It is not a family identifier, authentication credential or durable client
/// state. The create sheet keeps one key while the user retries the same
/// request so an ambiguous network outcome cannot duplicate a child profile.
String newFoundationGateIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
