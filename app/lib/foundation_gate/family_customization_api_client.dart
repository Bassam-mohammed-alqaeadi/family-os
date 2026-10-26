import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The seven days, named the way the family's own calendar names them.
///
/// The wire values are the server's (`sun` … `sat`) and the order below is the order the server
/// stores them in, so a list of rest days has exactly one correct spelling. A screen must never
/// build these from `DateTime.weekday`, whose numbering starts on Monday: that is the difference
/// between a family whose week begins on Saturday and a build that thinks it does.
enum FamilyCustomizationDay {
  sunday('sun'),
  monday('mon'),
  tuesday('tue'),
  wednesday('wed'),
  thursday('thu'),
  friday('fri'),
  saturday('sat');

  const FamilyCustomizationDay(this.wire);

  final String wire;

  static FamilyCustomizationDay? parse(Object? value) {
    for (final day in values) {
      if (day.wire == value) return day;
    }
    return null;
  }

  /// The position of this day in the family's own week, counted from the day it opens with.
  int indexFrom(FamilyCustomizationDay start) =>
      (index - start.index + values.length) % values.length;
}

/// How a family wants its numbers written.
///
/// This is not a decoration: every digit the app prints passes through
/// `core/i18n/numeral_format.dart`, and that reader consults the value stored here. Two words,
/// because a renderer has to be written for each one — a third value on the wire means nobody
/// agreed what it should draw, which is why an unknown word is refused rather than defaulted.
enum FamilyNumeralSystem {
  western('western'),
  eastern('eastern');

  const FamilyNumeralSystem(this.wire);

  final String wire;

  static FamilyNumeralSystem? parse(Object? value) {
    for (final system in values) {
      if (system.wire == value) return system;
    }
    return null;
  }
}

/// The four addressing words a family may choose.
///
/// The keys are closed on the server by a database constraint, and they are closed here by the
/// same list, so a word invented on either side reaches a screen as a refusal instead of as
/// silence. `child` is what a guardian's screen calls the child row; it is not a person's name.
enum FamilyGuardianLabelKey {
  father('father'),
  mother('mother'),
  guardian('guardian'),
  child('child');

  const FamilyGuardianLabelKey(this.wire);

  final String wire;

  static FamilyGuardianLabelKey? parse(Object? value) {
    for (final key in values) {
      if (key.wire == value) return key;
    }
    return null;
  }
}

/// What this family decided for itself, exactly as the spine answered it.
///
/// A family that has never opened the screen is not shown an empty week: the server answers with
/// the default view — the week the app has always drawn — and says so with [isFamilyChosen]
/// false. That distinction is kept because a guardian is entitled to know whether what they are
/// looking at is their own decision or the app's starting point.
class FamilyCustomizationProfile {
  const FamilyCustomizationProfile({
    required this.version,
    required this.weekStartDay,
    required this.restDays,
    required this.numerals,
    required this.labels,
    required this.updatedAt,
    required this.updatedByMembershipId,
    required this.isFamilyChosen,
  });

  /// Optimistic concurrency token. Zero means this family has never written a row.
  final int version;

  final FamilyCustomizationDay weekStartDay;

  /// Canonical `sun` … `sat` order, never duplicated — the server derives it from one stored flag
  /// per day, and this client refuses a list that arrives in any other shape.
  final List<FamilyCustomizationDay> restDays;

  final FamilyNumeralSystem numerals;

  final Map<FamilyGuardianLabelKey, String> labels;

  final DateTime? updatedAt;
  final String? updatedByMembershipId;

  /// True when a row of this family's own is being reported, false for the default view.
  final bool isFamilyChosen;

  bool isRest(FamilyCustomizationDay day) => restDays.contains(day);

  /// The days in the order this family's week runs in, for a grid that must not hardcode Monday.
  List<FamilyCustomizationDay> get weekOrder => List<FamilyCustomizationDay>.unmodifiable(
    List<FamilyCustomizationDay>.generate(
      FamilyCustomizationDay.values.length,
      (offset) =>
          FamilyCustomizationDay
              .values[(weekStartDay.index + offset) % FamilyCustomizationDay.values.length],
    ),
  );

  String? labelFor(FamilyGuardianLabelKey key) => labels[key];
}

/// The family's own profile, and nothing else.
///
/// Two operations, matching the two routes: read what this family chose, and change the fields a
/// screen actually touched. Nothing here computes a policy, decides whether a day is a rest day
/// for a given child, or stores an answer locally — the spine holds those, and this class either
/// carries its answer or reports that it could not.
class FamilyCustomizationApiClient {
  FamilyCustomizationApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
  }) : _configuration = configuration,
       _transport = transport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;

  Future<FamilyCustomizationProfile> readProfile({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _get(
      _configuration.familyCustomizationUri(familyId),
      idToken,
    );
    if (response.statusCode != 200) {
      throw _refusalFor(response);
    }
    return _profileFrom(_envelope(response.body));
  }

  /// Changes only the fields that are given.
  ///
  /// [expectedVersion] is never optional: a family's profile is read by every system in the app,
  /// so a write that does not say which version it was drawn from would be one guardian silently
  /// overwriting another. A day list replaces the week rather than growing it, and a label mapped
  /// to null drops that word back to the app's own.
  Future<FamilyCustomizationProfile> updateProfile({
    required String familyId,
    required String idToken,
    required String idempotencyKey,
    required int expectedVersion,
    FamilyCustomizationDay? weekStartDay,
    List<FamilyCustomizationDay>? restDays,
    FamilyNumeralSystem? numerals,
    Map<FamilyGuardianLabelKey, String?>? labels,
  }) async {
    final body = <String, Object?>{'expectedVersion': expectedVersion};
    if (weekStartDay != null) body['weekStartDay'] = weekStartDay.wire;
    if (restDays != null) {
      body['restDays'] = restDays
          .map((day) => day.wire)
          .toList(growable: false);
    }
    if (numerals != null) body['numerals'] = numerals.wire;
    if (labels != null) {
      body['labels'] = <String, Object?>{
        for (final entry in labels.entries) entry.key.wire: entry.value,
      };
    }
    if (body.length == 1) {
      // A version and nothing else is not a change. Refused here, because the alternative is a
      // request the server must reject and a guardian watching a spinner for nothing.
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
      );
    }
    final response = await _patch(
      _configuration.familyCustomizationUri(familyId),
      idToken,
      body,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode != 200) {
      throw _refusalFor(response);
    }
    return _profileFrom(_envelope(response.body));
  }

  Future<FoundationGateHttpResponse> _get(Uri uri, String idToken) async {
    try {
      return await _transport.get(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
        },
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  Future<FoundationGateHttpResponse> _patch(
    Uri uri,
    String idToken,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) async {
    try {
      return await _transport.patch(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
          'authorization': 'Bearer $idToken',
          'content-type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode(body),
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  /// The safe error envelope, kept with the status.
  ///
  /// `customization_stale_version` and `customization_primary_guardian_required` are two different
  /// sentences — one means "read it again", the other means "you may not write this" — and a
  /// screen that flattens them into "failed" tells a guardian nothing about what to do next.
  FoundationGateApiException _refusalFor(FoundationGateHttpResponse response) {
    String? serverCode;
    String? serverMessage;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?> &&
          decoded['error'] is Map<String, Object?>) {
        final error = decoded['error']! as Map<String, Object?>;
        if (error['code'] is String) serverCode = error['code']! as String;
        if (error['message'] is String) {
          serverMessage = error['message']! as String;
        }
      }
    } catch (_) {
      // A body that is not the envelope is still a status code, and a status code is an answer.
    }
    final failure = switch (response.statusCode) {
      400 => FoundationGateApiFailure.invalidInput,
      401 => FoundationGateApiFailure.unauthenticated,
      403 => FoundationGateApiFailure.accessDenied,
      404 => FoundationGateApiFailure.notFound,
      409 => FoundationGateApiFailure.conflict,
      429 || 503 => FoundationGateApiFailure.serviceUnavailable,
      _ => FoundationGateApiFailure.invalidResponse,
    };
    return FoundationGateApiException(
      failure,
      statusCode: response.statusCode,
      serverCode: serverCode,
      serverMessage: serverMessage,
    );
  }

  Object? _envelope(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      return decoded['profile'];
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  FamilyCustomizationProfile _profileFrom(Object? raw) {
    try {
      if (raw is! Map<String, Object?>) throw const FormatException();
      final weekStartDay = FamilyCustomizationDay.parse(raw['weekStartDay']);
      if (weekStartDay == null) throw const FormatException();
      final numerals = FamilyNumeralSystem.parse(raw['numerals']);
      if (numerals == null) throw const FormatException();
      final source = raw['source'];
      if (source != 'default' && source != 'family') throw const FormatException();
      final version = raw['version'];
      if (version is! int || version < 0) throw const FormatException();

      final rawRest = raw['restDays'];
      if (rawRest is! List<Object?> || rawRest.isEmpty || rawRest.length > 7) {
        throw const FormatException();
      }
      final rest = <FamilyCustomizationDay>{};
      FamilyCustomizationDay? previous;
      for (final entry in rawRest) {
        final day = FamilyCustomizationDay.parse(entry);
        // Canonical order and no repeats: the server derives the list from one flag per day, so
        // anything else means the two of us disagree about what a rest day is.
        if (day == null || !rest.add(day)) throw const FormatException();
        if (previous != null && day.index <= previous.index) {
          throw const FormatException();
        }
        previous = day;
      }

      final rawLabels = raw['guardianLabels'];
      if (rawLabels is! Map<String, Object?>) throw const FormatException();
      final labels = <FamilyGuardianLabelKey, String>{};
      for (final entry in rawLabels.entries) {
        final key = FamilyGuardianLabelKey.parse(entry.key);
        if (key == null || entry.value is! String) throw const FormatException();
        final text = (entry.value! as String).trim();
        if (text.isEmpty) throw const FormatException();
        labels[key] = text;
      }

      final updatedAt = _nullableDateTime(raw['updatedAt']);
      final updatedBy = raw['updatedByMembershipId'];
      if (updatedBy != null && updatedBy is! String) throw const FormatException();

      return FamilyCustomizationProfile(
        version: version,
        weekStartDay: weekStartDay,
        restDays: List<FamilyCustomizationDay>.unmodifiable(rest.toList()),
        numerals: numerals,
        labels: Map<FamilyGuardianLabelKey, String>.unmodifiable(labels),
        updatedAt: updatedAt,
        updatedByMembershipId: updatedBy is String ? updatedBy : null,
        isFamilyChosen: source == 'family',
      );
    } on FoundationGateApiException {
      rethrow;
    } catch (_) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException();
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw const FormatException();
    return parsed;
  }
}
