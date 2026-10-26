// الطابع العائلة · الغرفة ٢ — the spine this card talks to.
//
// Shared by the client test, the authority test and the panel test on purpose: two fakes would
// drift, and the one that drifted would be the one that stopped catching the bug.
//
// This is not a stub that returns a fixed body. It stores the family's row, checks the version it
// was handed, refuses the same things the real spine refuses in the same order, and answers from
// what it holds afterwards. That is what lets the panel test say a write changed what this family
// is told — rather than "the transport was called with something".
import 'dart:convert';

import 'package:family_os/features/n12_devices/family_customization_server_authority.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const familyCustomizationFamilyId =
    '11111111-1111-4111-8111-111111111111';
const familyCustomizationMembershipId =
    '22222222-2222-4222-8222-222222222222';
const familyCustomizationPath =
    '/v1/families/$familyCustomizationFamilyId/customization';

const _dayKeys = <String>['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const _labelKeys = <String>['father', 'mother', 'guardian', 'child'];
const _patchKeys = <String>[
  'expectedVersion',
  'weekStartDay',
  'restDays',
  'numerals',
  'labels',
];

/// A spine that holds a family's profile and enforces its laws.
final class FamilyCustomizationFakeSpine
    implements FoundationGateHttpTransport {
  FamilyCustomizationFakeSpine({
    bool stored = false,
    this.isPrimaryGuardian = true,
  }) : _profile = stored ? _storedProfile() : _defaultProfile();

  Map<String, Object?> _profile;

  /// When false, the caller is a co-guardian: reads work, writes are refused by name.
  bool isPrimaryGuardian;

  /// Set to throw instead of answering — the shape of a build with no network.
  Object? failure;

  /// When set, every verb returns this instead of consulting the row: the shape of a spine that
  /// answered something this build cannot read.
  FoundationGateHttpResponse? forced;

  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  final List<Map<String, String>> headers = <Map<String, String>>[];

  Map<String, Object?>? get lastBody => bodies.isEmpty
      ? null
      : jsonDecode(bodies.last) as Map<String, Object?>;

  Map<String, String>? get lastHeaders =>
      headers.isEmpty ? null : headers.last;

  int get version => _profile['version']! as int;

  List<String> get restDays =>
      (_profile['restDays']! as List<Object?>).cast<String>();

  String get weekStartDay => _profile['weekStartDay']! as String;

  String get numerals => _profile['numerals']! as String;

  Map<String, Object?> get labels =>
      _profile['guardianLabels']! as Map<String, Object?>;

  static Map<String, Object?> _defaultProfile() => <String, Object?>{
    'version': 0,
    'weekStartDay': 'mon',
    'numerals': 'western',
    'restDays': <String>['fri', 'sat'],
    'guardianLabels': <String, Object?>{},
    'updatedAt': null,
    'updatedByMembershipId': null,
    'source': 'default',
  };

  static Map<String, Object?> _storedProfile() => <String, Object?>{
    'version': 3,
    'weekStartDay': 'sun',
    'numerals': 'western',
    'restDays': <String>['fri'],
    'guardianLabels': <String, Object?>{'father': 'بابا'},
    'updatedAt': '2026-10-20T09:00:00.000Z',
    'updatedByMembershipId': familyCustomizationMembershipId,
    'source': 'family',
  };

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    this.headers.add(headers);
    if (failure != null) throw failure!;
    if (forced != null) return forced!;
    _requirePath(uri);
    return _ok(<String, Object?>{'profile': _profile});
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    this.headers.add(headers);
    bodies.add(body);
    if (failure != null) throw failure!;
    if (forced != null) return forced!;
    _requirePath(uri);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      return _refusal(400, 'invalid_request');
    }
    return _apply(decoded);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    throw UnsupportedError('a family profile has no POST: $uri');
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    throw UnsupportedError('a family profile has no PUT: $uri');
  }

  @override
  Future<FoundationGateHttpResponse> delete(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    throw UnsupportedError('a family profile is never deleted: $uri');
  }

  void _requirePath(Uri uri) {
    if (uri.path != familyCustomizationPath || uri.query.isNotEmpty) {
      throw StateError('unexpected request: $uri');
    }
  }

  /// The real spine's order: the shape of a change is judged before the caller's standing, and
  /// standing before the version. A screen that sent both problems at once should hear about the
  /// first, because fixing the second would not have made the change legal.
  FoundationGateHttpResponse _apply(Map<String, Object?> body) {
    for (final key in body.keys) {
      if (!_patchKeys.contains(key)) {
        return _refusal(400, 'invalid_request');
      }
    }
    final next = Map<String, Object?>.of(_profile);
    if (body['weekStartDay'] != null) {
      final day = body['weekStartDay'];
      if (day is! String || !_dayKeys.contains(day)) {
        return _refusal(400, 'invalid_request');
      }
      next['weekStartDay'] = day;
    }
    if (body.containsKey('restDays')) {
      final raw = body['restDays'];
      if (raw is! List<Object?>) {
        return _refusal(400, 'invalid_request');
      }
      if (raw.isEmpty) {
        return _refusal(400, 'customization_rest_day_required');
      }
      final picked = <String>{};
      for (final entry in raw) {
        if (entry is! String || !_dayKeys.contains(entry) || !picked.add(entry)) {
          return _refusal(400, 'invalid_request');
        }
      }
      next['restDays'] = _dayKeys.where(picked.contains).toList();
    }
    if (body['numerals'] != null) {
      final value = body['numerals'];
      if (value != 'western' && value != 'eastern') {
        return _refusal(400, 'invalid_request');
      }
      next['numerals'] = value;
    }
    if (body.containsKey('labels')) {
      final raw = body['labels'];
      if (raw is! Map<String, Object?>) {
        return _refusal(400, 'invalid_request');
      }
      final words = Map<String, Object?>.of(labels);
      for (final entry in raw.entries) {
        if (!_labelKeys.contains(entry.key)) {
          return _refusal(400, 'invalid_request');
        }
        if (entry.value == null) {
          words.remove(entry.key);
          continue;
        }
        final value = entry.value;
        if (value is! String) {
          return _refusal(400, 'invalid_request');
        }
        final text = value.trim();
        if (text.isEmpty ||
            text.length > 24 ||
            text.runes.any((rune) => rune < 32 || rune == 127)) {
          return _refusal(400, 'invalid_request');
        }
        words[entry.key] = text;
      }
      next['guardianLabels'] = words;
    }

    if (!isPrimaryGuardian) {
      return _refusal(403, 'customization_primary_guardian_required');
    }
    final expected = body['expectedVersion'];
    if (expected is! int || expected != version) {
      return _refusal(409, 'customization_stale_version');
    }
    next['version'] = version + 1;
    next['source'] = 'family';
    next['updatedAt'] = '2026-10-26T10:00:00.000Z';
    next['updatedByMembershipId'] = familyCustomizationMembershipId;
    _profile = next;
    return _ok(<String, Object?>{'profile': _profile});
  }

  FoundationGateHttpResponse _ok(Map<String, Object?> body) =>
      FoundationGateHttpResponse(
        statusCode: 200,
        body: jsonEncode(body),
      );

  FoundationGateHttpResponse _refusal(int statusCode, String code) =>
      FoundationGateHttpResponse(
        statusCode: statusCode,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': code,
            'message': 'refused by the family-customization test spine',
          },
        }),
      );
}

/// The client under test, wired to [spine] and nothing else.
FamilyCustomizationApiClient familyCustomizationClientFor(
  FamilyCustomizationFakeSpine spine,
) => FamilyCustomizationApiClient(
  configuration: _configuration,
  transport: spine,
);

/// The authority under test, wired to [spine] and nothing else.
FamilyCustomizationAuthority familyCustomizationAuthorityFor(
  FamilyCustomizationFakeSpine spine, {
  String? familyId = familyCustomizationFamilyId,
  Future<String> Function()? idToken,
}) => FamilyCustomizationAuthority(
  api: familyCustomizationClientFor(spine),
  idToken: idToken ?? _testToken,
  familyId: () => familyId,
);

final _configuration = FoundationGateConfiguration.fromStagingApiOrigin(
  Uri.parse('https://staging.example.test'),
);

Future<String> _testToken() async => 'test-token';
