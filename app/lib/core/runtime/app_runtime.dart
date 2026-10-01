import 'package:flutter/foundation.dart';

import 'package:family_os/core/runtime/identity_source.dart';

/// Application composition boundary for runtime services.
///
/// New ports are added here as typed fields, rather than screens importing
/// concrete adapters or reaching into mutable process-wide singletons.
final class AppRuntime extends ChangeNotifier {
  AppRuntime({required this.identity}) {
    identity.addListener(notifyListeners);
  }

  final IdentitySource identity;

  /// Refreshes only the identity projection. Future runtime ports expose their
  /// own explicit refresh/sync commands; there is intentionally no generic
  /// "pretend everything synchronized" operation.
  Future<IdentitySnapshot> refreshIdentity() => identity.refresh();

  @override
  void dispose() {
    identity.removeListener(notifyListeners);
    identity.dispose();
    super.dispose();
  }
}
