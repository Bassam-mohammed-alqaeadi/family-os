import 'package:flutter/foundation.dart';

import 'entitlement.dart';

/// Billing entitlement seam (UI-007 / Rule 25 mock).
///
/// **Must not** be injected into SOS / chat / location fire paths.
abstract class EntitlementService {
  Entitlement get current;

  /// Test / Stage-1 seam — set plan lifecycle without a store.
  void setEntitlement(Entitlement value);

  /// Cancel auto-renew / end trial UI — never disables safety (P-4).
  Future<void> cancelRenewal();
}

/// In-memory mock — no RevenueCat / Firebase this card.
final class MockEntitlementService extends ChangeNotifier
    implements EntitlementService {
  MockEntitlementService([Entitlement? initial])
      : _current = initial ?? Entitlement.trial();

  Entitlement _current;

  @override
  Entitlement get current => _current;

  @override
  void setEntitlement(Entitlement value) {
    _current = value;
    notifyListeners();
  }

  @override
  Future<void> cancelRenewal() async {
    // Cancel renew → expired-looking plan state; safety unaffected by design.
    _current = _current.copyWith(
      status: EntitlementStatus.expired,
      planId: 'basic_safety',
      autoRenew: false,
      clearTrialDays: true,
    );
    notifyListeners();
  }
}

/// Stage-1 process singleton for billing screens.
final MockEntitlementService stage1EntitlementService = MockEntitlementService();
