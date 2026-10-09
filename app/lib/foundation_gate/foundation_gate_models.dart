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

/// The avatars the real client offers when a guardian creates a child profile.
///
/// Every value sits inside `U+1F000–U+1FAFF`, which is the range
/// `children_roster_api_client.dart` validates before it writes a request. The
/// transport stays deliberately more permissive than this list when *reading*
/// the roster, so a value the server already accepted can never make a whole
/// roster unreadable; this list governs only what the form offers.
///
/// The first entry is the default, so an untouched form sends exactly what it
/// sent before this list existed.
const List<String> kFoundationGateChildAvatarEmojis = <String>[
  '🧒',
  '🦁',
  '🐱',
  '🐼',
  '🦊',
  '🐰',
];

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
  /// The server answered 404 for a record the caller named. Distinct from an invalid
  /// response on purpose: a membership that no longer exists is a state a screen can
  /// explain and recover from, while a malformed body is a defect it must not paper over.
  notFound,
  serviceUnavailable,
  networkUnavailable,
  invalidResponse,
}

class FoundationGateApiException implements Exception {
  const FoundationGateApiException(
    this.failure, {
    this.details,
    this.statusCode,
    this.serverCode,
    this.serverMessage,
  });

  final FoundationGateApiFailure failure;

  /// The structured details the server attached to its error, when it sent any.
  ///
  /// A conflict is not always a failure a family caused: "a question is already waiting" is
  /// answered with the open question's identifier so a screen can show it instead of an
  /// error. Absent means the server sent none, never an empty map invented here.
  final Map<String, Object?>? details;

  /// HTTP status and the safe error envelope values, when a typed client parsed them.
  /// These are intentionally separate from [failure]: callers can show a stable localized
  /// message while retaining the backend's machine code for diagnostics and recovery.
  final int? statusCode;
  final String? serverCode;
  final String? serverMessage;
}

class FoundationGateIdentityException implements Exception {
  const FoundationGateIdentityException();
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
