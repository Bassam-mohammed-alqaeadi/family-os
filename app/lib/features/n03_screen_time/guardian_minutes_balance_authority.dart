import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// One reading of a child's balance per app.
///
/// [stale] is true when this is the last good server reading, shown because the newest read
/// failed. A stale reading is never presented as fresh.
final class MinutesBalanceReading {
  const MinutesBalanceReading(this.byApp, {this.stale = false});

  final Map<String, int> byApp;
  final bool stale;
}

/// S3 — the guardian's read of a child's minutes balance, with the guardian's own session.
///
/// A guardian's phone holds no device credential, so the balance is read as the guardian. The
/// last good reading per child is kept in memory for this session only: nothing is written to
/// disk, and a failed read shows that reading flagged stale instead of an empty screen. With no
/// reading at all, the answer is null and no number is shown.
final class GuardianMinutesBalanceAuthority {
  GuardianMinutesBalanceAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyTasksApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  final Map<String, Map<String, int>> _lastGood = <String, Map<String, int>>{};

  Future<MinutesBalanceReading?> balanceByApp(String childId) async {
    final family = familyId();
    if (family == null) return null;
    try {
      final token = await idToken();
      final balance = await api.readMinutesBalance(
        familyId: family,
        childId: childId,
        idToken: token,
      );
      final byApp = {for (final app in balance.apps) app.appId: app.minutes};
      _lastGood[childId] = byApp;
      return MinutesBalanceReading(byApp);
    } on FoundationGateApiException {
      return _stale(childId);
    } on ArgumentError {
      return _stale(childId);
    }
  }

  MinutesBalanceReading? _stale(String childId) {
    final cached = _lastGood[childId];
    if (cached == null) return null;
    return MinutesBalanceReading(cached, stale: true);
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
