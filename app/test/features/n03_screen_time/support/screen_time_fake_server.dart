// W5 — the screen-time test server: a transport that answers per path, and the snapshots the
// server actually returns.
//
// It is shared by the panel tests and the screen-wiring test on purpose: two fakes would
// drift, and the one that drifted would be the one that stopped catching the bug. The
// transport answers by path suffix with the most specific match winning, so a write to
// `/screen-time/lock` is never answered by the read entry for `/screen-time`.
import 'dart:convert';

import 'package:family_os/features/n03_screen_time/screen_time_server_authority.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

const screenTimeFamilyId = '11111111-1111-4111-8111-111111111111';
const screenTimeChildId = '22222222-2222-4222-8222-222222222222';
const screenTimeRequestId = '55555555-5555-4555-8555-555555555555';

/// A transport that answers per path and remembers every request it was handed.
final class ScreenTimeFakeTransport implements FoundationGateHttpTransport {
  ScreenTimeFakeTransport(this.responses);

  final Map<String, FoundationGateHttpResponse> responses;
  final List<String> calls = <String>[];
  final List<String> bodies = <String>[];
  Object? failure;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('POST ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PATCH ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    calls.add('PUT ${uri.path}');
    bodies.add(body);
    if (failure != null) throw failure!;
    return _match(uri);
  }

  FoundationGateHttpResponse _match(Uri uri) {
    for (final entry in responses.entries) {
      if (uri.path.endsWith(entry.key)) return entry.value;
    }
    throw StateError('No canned answer for ${uri.path}');
  }
}

String screenTimeSnapshotJson({
  String kind = 'limited',
  Object? reason,
  Object? lock,
  String? openRequest,
  int usedMinutes = 30,
  int? remaining = 30,
  int cap = 60,
}) => jsonEncode(<String, Object?>{
  'childId': screenTimeChildId,
  'date': '2026-10-07',
  'policy': <String, Object?>{
    'childId': screenTimeChildId,
    'configured': true,
    'dailyLimitMinutes': cap,
    'schoolMode': <String, Object?>{
      'enabled': false,
      'days': <int>[7, 1, 2, 3, 4],
      'startMinute': 420,
      'endMinute': 840,
    },
    'bedtime': <String, Object?>{'startMinute': 1260, 'endMinute': 360},
    'timezoneOffsetMinutes': 180,
    'version': 4,
    'updatedAt': '2026-10-07T09:00:00.000Z',
  },
  'state': <String, Object?>{
    'kind': kind,
    'reasonCode': reason,
    'since': lock == null ? null : '2026-10-07T12:00:00.000Z',
    'date': '2026-10-07',
    'minuteOfDay': 720,
    'weekday': 3,
    'capMinutes': cap,
    'grantedMinutes': 0,
    'countableUsedMinutes': usedMinutes,
    'remainingMinutes': remaining,
    'lock': lock,
  },
  'lock': lock,
  'usage': <String, Object?>{
    'date': '2026-10-07',
    'countableUsedMinutes': usedMinutes,
    'grantedMinutes': 0,
    'remainingMinutes': remaining,
    'byApp': <Object?>[
      <String, Object?>{'appId': 'com.example.puzzle', 'usedMinutes': usedMinutes},
    ],
  },
  'openRequest': openRequest == null ? null : jsonDecode(openRequest),
});

String screenTimeLockJson() => jsonEncode(<String, Object?>{
  'id': '33333333-3333-4333-8333-333333333333',
  'reasonCode': 'parent_lock',
  'lockedAt': '2026-10-07T12:00:00.000Z',
  'lockedByMembershipId': '44444444-4444-4444-8444-444444444444',
  'releasedAt': null,
  'version': 1,
});

String screenTimeRequestJson() => jsonEncode(<String, Object?>{
  'id': screenTimeRequestId,
  'childId': screenTimeChildId,
  'usageDate': '2026-10-07',
  'requestedMinutes': 20,
  'requestedByKind': 'child',
  'reasonCode': null,
  'status': 'pending',
  'grantedMinutes': null,
  'expiresAt': '2026-10-07T21:00:00.000Z',
  'decidedAt': null,
  'decidedByMembershipId': null,
  'version': 1,
  'createdAt': '2026-10-07T15:00:00.000Z',
});

ScreenTimeServerAuthority screenTimeAuthorityFor(ScreenTimeFakeTransport transport) =>
    ScreenTimeServerAuthority(
      api: FamilyScreenTimeApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'test-token',
      familyId: () => screenTimeFamilyId,
    );
