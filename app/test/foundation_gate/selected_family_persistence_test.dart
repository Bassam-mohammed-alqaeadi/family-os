// The selected family survives a cold start, and is forgotten at sign-in, sign-out and return to
// the family list. Pinned here: the store round-trip, where the controller writes and clears it,
// and that a guardian with no family in memory still sees the kept minutes reading for the family
// remembered on this device, flagged stale.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n03_screen_time/guardian_minutes_balance_authority.dart';
import 'package:family_os/features/n03_screen_time/minutes_balance_cache.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:family_os/foundation_gate/selected_family_store.dart';

import 'foundation_gate_test_fakes.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _familyBody =
    '{"families":[{"id":"$_familyId","displayName":"Synthetic family","role":"primary_guardian"}]}';
const _emptyRosterBody = '{"children":[]}';
const _balanceBody =
    '{"daily":0,"temporary":0,"free":0,"apps":[{"appId":"youtube","minutes":25}],"total":25,"asOf":"2026-10-15T10:00:00.000Z"}';

final class _MemoryStore implements SelectedFamilyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String familyId) async => value = familyId;

  @override
  Future<void> clear() async => value = null;
}

FoundationGateConfiguration _config() =>
    FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse('https://staging.example.test'));

FoundationGateSessionController _controller(_MemoryStore store) =>
    FoundationGateSessionController(
      identity: FakeIdentity(),
      discoveryApi: FamilyDiscoveryApiClient(
        configuration: _config(),
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: _familyBody),
        ),
      ),
      rosterApi: ChildrenRosterApiClient(
        configuration: _config(),
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: _emptyRosterBody),
        ),
      ),
      selectedFamilyStore: store,
    );

void main() {
  test('the durable store round-trips the family id and clears it', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final store = SqliteSelectedFamilyStore(db);

    expect(await store.read(), isNull);
    await store.write(_familyId);
    expect(await store.read(), _familyId);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('a broken store never throws into the app: it reads as nothing remembered', () async {
    final store = DeferredSelectedFamilyStore(() async => throw StateError('no database'));

    expect(await store.read(), isNull);
    await store.write(_familyId);
    await store.clear();
  });

  test('selecting a family remembers it; signing out forgets it', () async {
    final store = _MemoryStore();
    final controller = _controller(store);
    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);
    expect(store.value, _familyId);

    await controller.signOut();
    expect(store.value, isNull);
  });

  test('returning to the family list forgets the family', () async {
    final store = _MemoryStore();
    final controller = _controller(store);
    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    await controller.selectFamily(controller.families.single);
    expect(store.value, _familyId);

    controller.returnToFamilySelection();
    await Future<void>.delayed(Duration.zero);
    expect(store.value, isNull);
  });

  test('signing in clears a family left by an earlier account on this device', () async {
    final store = _MemoryStore()..value = 'earlier-account-family';
    final controller = _controller(store);
    await controller.signIn(email: 'synthetic@example.test', password: 'synthetic-password');
    expect(store.value, isNull);
  });

  test('cold start offline: no family in memory, the remembered family shows the kept reading stale', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await SqliteMinutesBalanceCache(db).write(
      _childId,
      const CachedMinutesBalance(scope: _familyId, total: 25, byApp: {'youtube': 25}),
    );
    final authority = GuardianMinutesBalanceAuthority(
      api: FamilyTasksApiClient(
        configuration: _config(),
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 503, body: _balanceBody),
        ),
      ),
      idToken: () async => 'token',
      familyId: () => null,
      persistedFamilyId: () async => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );

    final reading = await authority.balanceByApp(_childId);
    expect(reading?.stale, isTrue);
    expect(reading?.byApp, {'youtube': 25});
  });

  test('no usable session: the kept reading for the family is shown stale, with no server call', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await SqliteMinutesBalanceCache(db).write(
      _childId,
      const CachedMinutesBalance(scope: _familyId, total: 25, byApp: {'youtube': 25}),
    );
    final authority = GuardianMinutesBalanceAuthority(
      api: FamilyTasksApiClient(
        configuration: _config(),
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: _balanceBody),
        ),
      ),
      idToken: () async => throw StateError('token refresh failed offline'),
      familyId: () => _familyId,
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );

    final reading = await authority.balanceByApp(_childId);
    expect(reading?.stale, isTrue);
    expect(reading?.byApp, {'youtube': 25});
  });
}
