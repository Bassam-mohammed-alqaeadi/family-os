import 'package:family_os/features/n03_screen_time/minutes_balance_cache.dart';
import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
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
/// A fresh answer is written to the device's durable cache under the family it was read for.
/// When the read fails, the cached reading for that same family is shown flagged stale. With no
/// family selected there is no pairing to verify a cached reading against, so nothing is shown.
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
    final family = familyId();
    if (family == null) return null;
    final cache = await cacheOpener();
    try {
      final token = await idToken();
      final balance = await api.readMinutesBalance(
        familyId: family,
        childId: childId,
        idToken: token,
      );
      final byApp = {for (final app in balance.apps) app.appId: app.minutes};
      await writeCachedMinutes(
        cache,
        childId,
        CachedMinutesBalance(scope: family, total: balance.total, byApp: byApp),
      );
      return MinutesBalanceReading(byApp);
    } on FoundationGateApiException catch (e) {
      // A refusal is not a reason to show the kept reading (token expired, access revoked).
      if (e.failure != FoundationGateApiFailure.networkUnavailable &&
          e.failure != FoundationGateApiFailure.serviceUnavailable) {
        return null;
      }
      return _stale(cache, childId, family);
    } on ArgumentError {
      return _stale(cache, childId, family);
    }
  }

  Future<MinutesBalanceReading?> _stale(
    MinutesBalanceCache? cache,
    String childId,
    String family,
  ) async {
    final cached = await readCachedMinutes(cache, childId, scope: family);
    return cached == null
        ? null
        : MinutesBalanceReading(cached.byApp, stale: true);
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
