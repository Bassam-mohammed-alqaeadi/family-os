import 'package:flutter/foundation.dart';

import 'privacy_collection_policy.dart';

/// Same-session father→child sync for collection scopes (SET-012 / P12).
///
/// Mirrors [PolicySyncBus] spirit without coupling to screen-time: father
/// [publish] → child [watch]/[policyOf] update in-process (no cold restart).
final class PrivacyCollectionSyncBus extends ChangeNotifier {
  PrivacyCollectionSyncBus();

  final Map<String, PrivacyCollectionPolicy> _byChild = {};

  /// Last published / hydrated policy for [childId], or null.
  PrivacyCollectionPolicy? policyOf(String childId) => _byChild[childId];

  /// Seed without counting as a father save (hydrate from repo load).
  void hydrate(PrivacyCollectionPolicy policy) {
    _byChild[policy.childId] = policy;
  }

  /// Father save → notify listeners (child mirror rebuilds same session).
  void publish(PrivacyCollectionPolicy policy) {
    _byChild[policy.childId] = policy;
    notifyListeners();
  }
}

/// Stage-1 shared bus (survives within process).
final PrivacyCollectionSyncBus stage1PrivacyCollectionSyncBus =
    PrivacyCollectionSyncBus();
