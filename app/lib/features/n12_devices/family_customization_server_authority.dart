import 'package:family_os/core/i18n/numeral_format.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Why the screen is showing what it is showing.
///
/// There is no `localFallback` and there never will be. A family's week, its rest days, the words
/// its children use and the digits it counts in are one row on the spine; a build that cannot ask
/// says so instead of drawing a plausible-looking profile that nobody agreed to.
enum FamilyCustomizationStatus {
  /// The spine answered, and what is on screen is its answer.
  ready,

  /// This build has no server session: no configured origin, no selected family, no token.
  /// Nothing was asked, because there was nobody to ask.
  notConfigured,

  /// The spine answered that this account may not see or change this family's profile.
  accessDenied,

  /// The server is configured but did not answer. The last read stays on screen, marked as the
  /// last read.
  unreachable,

  /// The server refused a write, with a reason this screen can state.
  refused,

  /// The server answered, but the answer could not be read. Reported as a defect, never smoothed
  /// into an empty profile.
  unreadable,
}

/// Which refusal a guardian is being told about. The words live in ARB; this only says which one.
enum FamilyCustomizationRefusal {
  none,

  /// Somebody else changed the profile after this screen read it. The right next move is to read
  /// again, not to insist.
  staleVersion,

  /// Only the family's primary guardian changes what every system reads.
  notPrimaryGuardian,

  /// A week with no rest day at all — refused by the server and by its database, in that order.
  noRestDay,

  /// A word too long, blank, or a key that is not one of the four.
  wordRefused,

  /// The server refused and gave this build nothing it can name.
  unexplained,
}

/// One answer from the spine: a profile, or the reason there is none.
class FamilyCustomizationAnswer {
  const FamilyCustomizationAnswer.ready(this.profile)
    : status = FamilyCustomizationStatus.ready,
      refusal = FamilyCustomizationRefusal.none;

  const FamilyCustomizationAnswer.unavailable(
    this.status, [
    this.refusal = FamilyCustomizationRefusal.none,
  ]) : profile = null;

  final FamilyCustomizationStatus status;
  final FamilyCustomizationProfile? profile;
  final FamilyCustomizationRefusal refusal;

  bool get isReady =>
      status == FamilyCustomizationStatus.ready && profile != null;
}

/// The one server connection this screen holds.
///
/// It is also the only door through which a family's stored digit choice enters this build: every
/// successful read or write applies it to [AppNumerals], because the alternative — a screen applying
/// it, a start-up task applying it, a cached copy applying it — is three places that can disagree
/// about how one family's numbers look. A build with no answer applies nothing, and unbinding
/// forgets the answer with the session, so no handset keeps another family's digits.
///
/// It decides nothing. It carries the family's own row to the screen and the screen's change back,
/// and where there is no answer it returns a status the screen can render as a sentence — never a
/// default invented on the handset, which is how an app ends up telling a family their week starts
/// on Monday when they never said so.
final class FamilyCustomizationAuthority {
  FamilyCustomizationAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyCustomizationApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// What this family chose, or the reason nobody could be asked.
  Future<FamilyCustomizationAnswer> read() async {
    final gate = await _session();
    if (gate.status != null) {
      return FamilyCustomizationAnswer.unavailable(gate.status!);
    }
    try {
      final profile = await api.readProfile(
        familyId: gate.familyId!,
        idToken: gate.token!,
      );
      AppNumerals.applyFamilyChoice(_numeralSystemFor(profile.numerals));
      return FamilyCustomizationAnswer.ready(profile);
    } on FoundationGateApiException catch (error) {
      return FamilyCustomizationAnswer.unavailable(
        _statusFor(error.failure),
      );
    } on Object {
      // A socket that closed is not a malformed answer. The honest word for "nobody replied" is
      // unreachable; unreadable is reserved for a reply that arrived and could not be read.
      return const FamilyCustomizationAnswer.unavailable(
        FamilyCustomizationStatus.unreachable,
      );
    }
  }

  /// Change only what the screen touched, at the version it read.
  ///
  /// A stale version comes back as [FamilyCustomizationRefusal.staleVersion] and nothing else:
  /// the profile on the spine is untouched, and the screen is expected to read again rather than
  /// resend its own draft over whoever changed it first.
  Future<FamilyCustomizationAnswer> write({
    required int expectedVersion,
    FamilyCustomizationDay? weekStartDay,
    List<FamilyCustomizationDay>? restDays,
    FamilyNumeralSystem? numerals,
    Map<FamilyGuardianLabelKey, String?>? labels,
    required String idempotencyKey,
  }) async {
    final gate = await _session();
    if (gate.status != null) {
      return FamilyCustomizationAnswer.unavailable(gate.status!);
    }
    try {
      final profile = await api.updateProfile(
        familyId: gate.familyId!,
        idToken: gate.token!,
        idempotencyKey: idempotencyKey,
        expectedVersion: expectedVersion,
        weekStartDay: weekStartDay,
        restDays: restDays,
        numerals: numerals,
        labels: labels,
      );
      AppNumerals.applyFamilyChoice(_numeralSystemFor(profile.numerals));
      return FamilyCustomizationAnswer.ready(profile);
    } on FoundationGateApiException catch (error) {
      return FamilyCustomizationAnswer.unavailable(
        _statusForWrite(error.failure),
        _refusalFor(error),
      );
    } on Object {
      return const FamilyCustomizationAnswer.unavailable(
        FamilyCustomizationStatus.unreachable,
      );
    }
  }

  /// The bound authority, or none.
  ///
  /// A screen must be able to say "this build has no server" and mean it, which is why the binding
  /// is a plain nullable global with no fake default behind it — the shape the device ledger,
  /// screen-time, location and filter authorities use.
  static FamilyCustomizationAuthority? _bound;

  static void bind(FamilyCustomizationAuthority? authority) {
    _bound = authority;
    if (authority == null) AppNumerals.clearFamilyChoice();
  }

  static FamilyCustomizationAuthority? get bound => _bound;

  Future<_CustomizationGate> _session() async {
    final family = familyId();
    if (family == null || !isFoundationGateUuid(family)) {
      return const _CustomizationGate(FamilyCustomizationStatus.notConfigured);
    }
    final token = await idToken();
    if (token.trim().isEmpty) {
      return const _CustomizationGate(FamilyCustomizationStatus.notConfigured);
    }
    return _CustomizationGate.ready(familyId: family, token: token);
  }

  /// The client's value for the shared reader's value. Two enums for one word would be a third
  /// place a family's digits are decided, so this is a translation and nothing more.
  static AppNumeralSystem _numeralSystemFor(FamilyNumeralSystem value) =>
      switch (value) {
        FamilyNumeralSystem.western => AppNumeralSystem.western,
        FamilyNumeralSystem.eastern => AppNumeralSystem.eastern,
      };

  /// What a refused write means on screen.
  ///
  /// The same status code is a different sentence depending on which way the door was opened: a 403
  /// on a read is "you cannot see this", while a 403 on a write is "you may not change this" — a
  /// refusal a guardian can act on (ask the family's first guardian) rather than a loss of sight.
  /// The device ledger splits its two the same way, for the same reason.
  static FamilyCustomizationStatus _statusForWrite(
    FoundationGateApiFailure failure,
  ) => switch (failure) {
    FoundationGateApiFailure.accessDenied => FamilyCustomizationStatus
        .refused,
    _ => _statusFor(failure),
  };

  static FamilyCustomizationStatus _statusFor(
    FoundationGateApiFailure failure,
  ) => switch (failure) {
    FoundationGateApiFailure.unauthenticated =>
      FamilyCustomizationStatus.notConfigured,
    FoundationGateApiFailure.accessDenied =>
      FamilyCustomizationStatus.accessDenied,
    FoundationGateApiFailure.networkUnavailable ||
    FoundationGateApiFailure.serviceUnavailable =>
      FamilyCustomizationStatus.unreachable,
    FoundationGateApiFailure.notFound =>
      FamilyCustomizationStatus.notConfigured,
    FoundationGateApiFailure.conflict ||
    FoundationGateApiFailure.invalidInput =>
      FamilyCustomizationStatus.refused,
    FoundationGateApiFailure.invalidResponse =>
      FamilyCustomizationStatus.unreadable,
  };

  /// The reason, when the server named one.
  ///
  /// A refusal that arrives without a machine code is reported as [unexplained]: the screen then
  /// says the spine would not accept the change, which is true, rather than guessing at a reason
  /// the family could act on and would be wrong about.
  static FamilyCustomizationRefusal _refusalFor(
    FoundationGateApiException error,
  ) {
    if (error.failure != FoundationGateApiFailure.conflict &&
        error.failure != FoundationGateApiFailure.invalidInput &&
        error.failure != FoundationGateApiFailure.accessDenied) {
      return FamilyCustomizationRefusal.none;
    }
    return switch (error.serverCode) {
      'customization_stale_version' => FamilyCustomizationRefusal.staleVersion,
      'customization_primary_guardian_required' =>
        FamilyCustomizationRefusal.notPrimaryGuardian,
      'customization_rest_day_required' =>
        FamilyCustomizationRefusal.noRestDay,
      'invalid_request' => FamilyCustomizationRefusal.wordRefused,
      _ => FamilyCustomizationRefusal.unexplained,
    };
  }
}

/// Either a family and a token to ask with, or the reason there is nothing to ask with.
class _CustomizationGate {
  const _CustomizationGate(this.status) : familyId = null, token = null;

  const _CustomizationGate.ready({required this.familyId, required this.token})
    : status = null;

  final FamilyCustomizationStatus? status;
  final String? familyId;
  final String? token;
}
