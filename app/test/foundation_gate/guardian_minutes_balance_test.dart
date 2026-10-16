// S3 — the guardian's read of a child's minutes balance.
//
// Pinned here: the URL and verb (GET only: nothing on this path writes minutes), the wire
// answer becoming per-app minutes, the refusals mapping to a failure the screen can name, and
// the authority returning null on every non-answer so no screen shows a number this device made up.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n03_screen_time/guardian_minutes_balance_authority.dart';
import 'package:family_os/features/n03_screen_time/minutes_balance_cache.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _balanceBody =
    '{"daily":0,"temporary":0,"free":0,"apps":[{"appId":"youtube","minutes":25}],"total":25,"asOf":"2026-10-15T10:00:00.000Z"}';

final class _Transport implements FoundationGateHttpTransport {
  _Transport(this.status, this.body);

  int status;
  final String body;
  final List<String> calls = <String>[];

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    calls.add('GET ${uri.path}');
    return FoundationGateHttpResponse(statusCode: status, body: body);
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => throw StateError('the balance read must not write');
}

FamilyTasksApiClient _api(_Transport transport) => FamilyTasksApiClient(
  configuration: FoundationGateConfiguration.fromStagingApiOrigin(
    Uri.parse('https://api.example.com'),
  ),
  transport: transport,
);

void main() {
  test('reads the guardian balance with GET on the family child path', () async {
    final transport = _Transport(200, _balanceBody);
    final balance = await _api(transport).readMinutesBalance(
      familyId: _familyId,
      childId: _childId,
      idToken: 'token',
    );

    expect(transport.calls, ['GET /v1/families/$_familyId/children/$_childId/minutes/balance']);
    expect(balance.apps.single.appId, 'youtube');
    expect(balance.apps.single.minutes, 25);
  });

  test('refusals map to named failures, never to a number', () async {
    for (final entry in {
      401: FoundationGateApiFailure.unauthenticated,
      403: FoundationGateApiFailure.accessDenied,
      404: FoundationGateApiFailure.notFound,
      503: FoundationGateApiFailure.serviceUnavailable,
      418: FoundationGateApiFailure.invalidResponse,
    }.entries) {
      await expectLater(
        _api(_Transport(entry.key, _balanceBody)).readMinutesBalance(
          familyId: _familyId,
          childId: _childId,
          idToken: 'token',
        ),
        throwsA(
          isA<FoundationGateApiException>().having((e) => e.failure, 'failure', entry.value),
        ),
        reason: 'status ${entry.key}',
      );
    }
  });

  test('the authority answers per app, and null on every non-answer', () async {
    GuardianMinutesBalanceAuthority authority(_Transport transport) =>
        GuardianMinutesBalanceAuthority(
          api: _api(transport),
          idToken: () async => 'token',
          familyId: () => _familyId,
          cacheOpener: () async => null,
        );

    final fresh = await authority(_Transport(200, _balanceBody)).balanceByApp(_childId);
    expect(fresh?.byApp, {'youtube': 25});
    expect(fresh?.stale, isFalse);
    expect(await authority(_Transport(403, _balanceBody)).balanceByApp(_childId), isNull);
    expect(await authority(_Transport(200, _balanceBody)).balanceByApp('not-a-uuid'), isNull);

    final noFamily = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(200, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => null,
      cacheOpener: () async => null,
    );
    expect(await noFamily.balanceByApp(_childId), isNull);
  });

  test('a failed read shows the reading kept on this device for the same family, flagged stale', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final transport = _Transport(200, _balanceBody);
    final authority = GuardianMinutesBalanceAuthority(
      api: _api(transport),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );

    expect((await authority.balanceByApp(_childId))?.stale, isFalse);

    transport.status = 503;
    final stale = await authority.balanceByApp(_childId);
    expect(stale?.stale, isTrue);
    expect(stale?.byApp, {'youtube': 25});
  });

  test('the cached reading survives a restart: a new authority on the same store', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final before = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(200, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );
    expect((await before.balanceByApp(_childId))?.byApp, {'youtube': 25});

    // Restart: a brand-new authority and cache object, offline, same family.
    final after = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(503, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );
    final offline = await after.balanceByApp(_childId);
    expect(offline?.stale, isTrue);
    expect(offline?.byApp, {'youtube': 25});
  });

  test('a refused read (token expired) never falls back to the kept reading', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final transport = _Transport(200, _balanceBody);
    final authority = GuardianMinutesBalanceAuthority(
      api: _api(transport),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );
    expect((await authority.balanceByApp(_childId))?.stale, isFalse);

    transport.status = 401;
    expect(await authority.balanceByApp(_childId), isNull);
  });

  test('no family selected means no pairing to verify: nothing is shown from the cache', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await SqliteMinutesBalanceCache(db).write(
      _childId,
      const CachedMinutesBalance(scope: _familyId, total: 25, byApp: {'youtube': 25}),
    );
    final authority = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(503, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => null,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );
    expect(await authority.balanceByApp(_childId), isNull);
  });

  test('a reading from a different family is ignored, never shown', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await SqliteMinutesBalanceCache(db).write(
      _childId,
      const CachedMinutesBalance(scope: _familyId, total: 25, byApp: {'youtube': 25}),
    );
    final otherFamily = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(503, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => '44444444-4444-4444-8444-444444444444',
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );
    expect(await otherFamily.balanceByApp(_childId), isNull);
  });

  test('a fresh answer replaces the cached one, and a child never sees another child', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final cache = SqliteMinutesBalanceCache(db);
    const otherChild = '33333333-3333-4333-8333-333333333333';
    await cache.write(
      _childId,
      const CachedMinutesBalance(scope: _familyId, total: 25, byApp: {'youtube': 25}),
    );
    await cache.write(
      otherChild,
      const CachedMinutesBalance(scope: _familyId, total: 9, byApp: {'games': 9}),
    );

    final authority = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(200, '{"daily":0,"temporary":0,"free":0,"apps":[{"appId":"youtube","minutes":7}],"total":7,"asOf":"2026-10-15T11:00:00.000Z"}')),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => cache,
    );
    expect((await authority.balanceByApp(_childId))?.byApp, {'youtube': 7});
    final replaced = await cache.read(_childId, scope: _familyId);
    expect(replaced?.byApp, {'youtube': 7});
    expect(replaced?.total, 7);
    expect((await cache.read(otherChild, scope: _familyId))?.byApp, {'games': 9});
  });

  test('with no durable store and a failed read, no number is shown', () async {
    final authority = GuardianMinutesBalanceAuthority(
      api: _api(_Transport(503, _balanceBody)),
      idToken: () async => 'token',
      familyId: () => _familyId,
      cacheOpener: () async => null,
    );
    expect(await authority.balanceByApp(_childId), isNull);
  });
}
