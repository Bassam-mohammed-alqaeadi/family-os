import 'package:flutter/foundation.dart';

import 'app_control_disposition.dart';

/// Why App Control allowed a package.
enum AppControlAllowSource { protected, exception, exempt, explicitAllow }

/// Why App Control denied a package (source-of-deny contribution).
enum AppControlDenySource { lockNow, permanentBlock, pendingUnknown }

/// Domain access verdict for `(child, package)` — no native enforcement claim.
@immutable
final class AppControlVerdict {
  const AppControlVerdict._({
    required this.allowed,
    required this.policyVersion,
    this.allowSource,
    this.denySource,
    this.underlyingDisposition,
  });

  factory AppControlVerdict.allow({
    required int policyVersion,
    required AppControlAllowSource allowSource,
    AppPackageDisposition? underlyingDisposition,
  }) {
    return AppControlVerdict._(
      allowed: true,
      policyVersion: policyVersion,
      allowSource: allowSource,
      underlyingDisposition: underlyingDisposition,
    );
  }

  factory AppControlVerdict.deny({
    required int policyVersion,
    required AppControlDenySource denySource,
    AppPackageDisposition? underlyingDisposition,
  }) {
    return AppControlVerdict._(
      allowed: false,
      policyVersion: policyVersion,
      denySource: denySource,
      underlyingDisposition: underlyingDisposition,
    );
  }

  final bool allowed;
  final int policyVersion;
  final AppControlAllowSource? allowSource;
  final AppControlDenySource? denySource;

  /// Policy row disposition (unchanged by exception overlay).
  final AppPackageDisposition? underlyingDisposition;

  bool get isDenied => !allowed;
}
