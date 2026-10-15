// S3 — the child's handset: the last good balance survives a restart, is flagged stale when the
// newest read fails, and is ignored when the handset is paired to a different device.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/fs_foundation/memory_local_database.dart';
import 'package:family_os/features/n03_screen_time/minutes_balance_cache.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';
import 'package:family_os/foundation_gate/child_minutes_balance_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

const _balanceBody =
    '{"daily":0,"temporary":0,"free":0,"apps":[{"appId":"youtube","minutes":25}],"total":25,"asOf":"2026-10-15T10:00:00.000Z"}';

final class _Handset implements ChildMinutesBalanceTransport {
  _Handset({required this.deviceId, this.status = 200});

  String? deviceId;
  int status;

  @override
  Future<String?> configuredDeviceId() async => deviceId;

  @override
  Future<FoundationGateHttpResponse> readBalance(String deviceId) async =>
      FoundationGateHttpResponse(statusCode: status, body: _balanceBody);
}

ServerChildWalletRepository _repo(_Handset handset, MemoryLocalDatabase db) =>
    ServerChildWalletRepository(
      client: ChildMinutesBalanceClient(transport: handset),
      cacheOpener: () async => SqliteMinutesBalanceCache(db),
    );

void main() {
  test('a fresh read is not stale and is kept on the device', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    final snap = await _repo(_Handset(deviceId: 'dev-a'), db).load();
    expect(snap.simulated, isFalse);
    expect(snap.stale, isFalse);
    expect(snap.totalMinutes, 25);
    expect(
      (await SqliteMinutesBalanceCache(db).read('dev-a', scope: 'dev-a'))?.total,
      25,
    );
  });

  test('after a restart, a failed read shows the kept balance flagged stale', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await _repo(_Handset(deviceId: 'dev-a'), db).load();

    // Restart: a new repository on the same store, the network is down.
    final offline = await _repo(_Handset(deviceId: 'dev-a', status: 503), db).load();
    expect(offline.stale, isTrue);
    expect(offline.totalMinutes, 25);
    expect(offline.apps.single.id, 'youtube');
    expect(offline.apps.single.walletMinutes, 25);
  });

  test('a handset paired to another device ignores the kept balance', () async {
    final db = MemoryLocalDatabase();
    await db.open();
    await _repo(_Handset(deviceId: 'dev-a'), db).load();

    await expectLater(
      _repo(_Handset(deviceId: 'dev-b', status: 503), db).load(),
      throwsA(isA<FoundationGateApiException>()),
    );
  });

  test('with no durable store, a failed read is an error, never a number', () async {
    final repo = ServerChildWalletRepository(
      client: ChildMinutesBalanceClient(
        transport: _Handset(deviceId: 'dev-a', status: 503),
      ),
      cacheOpener: () async => null,
    );
    await expectLater(repo.load(), throwsA(isA<FoundationGateApiException>()));
  });
}
