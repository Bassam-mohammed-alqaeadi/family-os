import 'package:family_os/core/domain/identity_ids.dart';

import 'app_control_disposition.dart';
import 'app_control_document.dart';
import 'app_control_protected.dart';
import 'app_control_verdict.dart';
import 'package_id.dart';

/// Deterministic App Control evaluation (domain only — no OS intercept claim).
///
/// Precedence:
/// 1. Protected → always allow
/// 2. Active Lock Now → deny
/// 3. Active Exception → allow (policy row unchanged)
/// 4. Permanent Block → deny
/// 5. Exempt → allow
/// 6. Explicit Allow → allow
/// 7. Pending install / unknown → deny-until-approved (APP-OD-08)
abstract final class AppControlEngine {
  static AppControlDocument resolveEffective({
    required AppControlDocument? familyBaseline,
    required AppControlDocument? childOverride,
    required FamilyId familyId,
  }) {
    if (childOverride != null) return childOverride;
    if (familyBaseline != null) return familyBaseline;
    return AppControlDocument.familyDefaults(familyId);
  }

  static AppControlVerdict decide({
    required String packageId,
    required AppControlDocument document,
    bool lockNowActive = false,
    bool exceptionActive = false,
    bool installPending = false,
  }) {
    final version = document.policyVersion;
    final pkg = PackageId.normalize(packageId);
    final underlying = document.dispositionOf(pkg);

    // 1. Protected — cannot be denied by App Control
    if (ProtectedPackageIds.isProtected(pkg)) {
      return AppControlVerdict.allow(
        policyVersion: version,
        allowSource: AppControlAllowSource.protected,
        underlyingDisposition: underlying ?? AppPackageDisposition.allow,
      );
    }

    // 2. Lock Now temporary deny overlay
    if (lockNowActive) {
      return AppControlVerdict.deny(
        policyVersion: version,
        denySource: AppControlDenySource.lockNow,
        underlyingDisposition: underlying,
      );
    }

    // 3. Timed exception — evaluation allow; does not rewrite Permanent Block
    if (exceptionActive) {
      return AppControlVerdict.allow(
        policyVersion: version,
        allowSource: AppControlAllowSource.exception,
        underlyingDisposition: underlying,
      );
    }

    // 4–6. Explicit dispositions
    switch (underlying) {
      case AppPackageDisposition.block:
        return AppControlVerdict.deny(
          policyVersion: version,
          denySource: AppControlDenySource.permanentBlock,
          underlyingDisposition: underlying,
        );
      case AppPackageDisposition.exempt:
        return AppControlVerdict.allow(
          policyVersion: version,
          allowSource: AppControlAllowSource.exempt,
          underlyingDisposition: underlying,
        );
      case AppPackageDisposition.allow:
        return AppControlVerdict.allow(
          policyVersion: version,
          allowSource: AppControlAllowSource.explicitAllow,
          underlyingDisposition: underlying,
        );
      case null:
        break;
    }

    // 7. Pending install or unknown → deny-until-approved
    if (installPending || underlying == null) {
      return AppControlVerdict.deny(
        policyVersion: version,
        denySource: AppControlDenySource.pendingUnknown,
        underlyingDisposition: underlying,
      );
    }

    return AppControlVerdict.deny(
      policyVersion: version,
      denySource: AppControlDenySource.pendingUnknown,
      underlyingDisposition: underlying,
    );
  }
}
