import 'package:family_os/features/n03_screen_time/minutes_balance_cache.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// One reading of a child's balance per app.
///
/// [stale] is true when this is the last good reading, shown because the newest read failed.
/// A stale reading is never presented as fresh.
final class MinutesBalanceReading {
  const MinutesBalanceReading(this.byApp, {this.stale = false});

  final Map<String, int> byApp;
  final bool stale;
}

/// S3 — the guardian's read of a child's minutes balance, with the guardian's own session.
///
/// A guardian's phone holds no device credential, so the balance is read as the guardian.
/// A fresh answer is written to the device's durable cache. When the read fails, the cached
/// reading is shown flagged stale, so the screen still works offline. With no reading at all,
/// the answer is null and no number is shown.
final class GuardianMinutesBalanceAuthority {
  GuardianMinutesBalanceAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
    required this.cacheOpener,
  });

  final FamilyTasksApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;
  final Future<MinutesBalanceCache?> Function() cacheOpener;

  Future<MinutesBalanceReading?> balanceByApp(String childId) async {
    final cache = await cacheOpener();
    final family = familyId();
    if (family != null) {
      try {
        final token = await idToken();
        final balance = await api.readMinutesBalance(
          familyId: family,
          childId: childId,
          idToken: token,
        );
        final byApp = {for (final app in balance.apps) app.appId: app.minutes};
        await _writeCache(cache, childId, byApp);
        return MinutesBalanceReading(byApp);
      } on FoundationGateApiException {
        // Fall through to the cached reading.
      } on ArgumentError {
        // Fall through to the cached reading.
      }
    }
    final cached = await _readCache(cache, childId);
    return cached == null ? null : MinutesBalanceReading(cached, stale: true);
  }

  static Future<void> _writeCache(
    MinutesBalanceCache? cache,
    String childId,
    Map<String, int> byApp,
  ) async {
    if (cache == null) return;
    try {
      await cache.write(childId, byApp);
    } on Object {
      // A failed cache write never hides a fresh answer.
      return;
    }
  }

  static Future<Map<String, int>?> _readCache(
    MinutesBalanceCache? cache,
    String childId,
  ) async {
    if (cache == null) return null;
    try {
      return await cache.read(childId);
    } on Object {
      return null;
    }
  }
}

GuardianMinutesBalanceAuthority? _activeGuardianBalance;

/// Binds the guardian balance read to the server session, or clears it.
void bindGuardianMinutesBalance(GuardianMinutesBalanceAuthority? authority) {
  _activeGuardianBalance = authority;
}

/// The bound guardian's balance; null when no server session is bound.
Future<MinutesBalanceReading?> guardianMinutesBalanceByApp(String childId) {
  final authority = _activeGuardianBalance;
  if (authority == null) return Future.value(null);
  return authority.balanceByApp(childId);
}
