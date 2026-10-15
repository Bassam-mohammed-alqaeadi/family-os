import 'package:family_os/foundation_gate/family_tasks_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// S3 — the guardian's read of a child's minutes balance, with the guardian's own session.
///
/// A guardian's phone holds no device credential, so the balance is read as the guardian. The
/// answer is per app, or null when there is no answer. Null means the screen shows no number:
/// it never falls back to a figure this device made up.
final class GuardianMinutesBalanceAuthority {
  GuardianMinutesBalanceAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
  });

  final FamilyTasksApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  Future<Map<String, int>?> balanceByApp(String childId) async {
    final family = familyId();
    if (family == null) return null;
    try {
      final token = await idToken();
      final balance = await api.readMinutesBalance(
        familyId: family,
        childId: childId,
        idToken: token,
      );
      return {for (final app in balance.apps) app.appId: app.minutes};
    } on FoundationGateApiException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

GuardianMinutesBalanceAuthority? _activeGuardianBalance;

/// Binds the guardian balance read to the server session, or clears it.
void bindGuardianMinutesBalance(GuardianMinutesBalanceAuthority? authority) {
  _activeGuardianBalance = authority;
}

/// The bound guardian's balance by app; null when no server session is bound.
Future<Map<String, int>?> guardianMinutesBalanceByApp(String childId) {
  final authority = _activeGuardianBalance;
  if (authority == null) return Future.value(null);
  return authority.balanceByApp(childId);
}
