/// Policy disposition for a package under App Control (not Screen Time axes).
enum AppPackageDisposition {
  /// May launch subject to ST / Modes / Instant Lock / WF.
  allow,

  /// Permanent Block (P2) — Minutes/grants/Unlimited never open.
  block,

  /// Access-plane exempt under AC — ≠ ST Unlimited (APP-SF-17).
  exempt,
}

extension AppPackageDispositionCodec on AppPackageDisposition {
  String get wire => name;

  static AppPackageDisposition parse(String? raw) {
    return switch (raw) {
      'block' => AppPackageDisposition.block,
      'exempt' => AppPackageDisposition.exempt,
      _ => AppPackageDisposition.allow,
    };
  }
}
