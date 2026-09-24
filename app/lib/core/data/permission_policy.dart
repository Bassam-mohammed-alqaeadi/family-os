import 'family_database.dart';

/// ADR-050 as executable policy — pure logic, testable without a device.
///
/// The four rules, in code:
///  1. contextual request — the "core at launch" whitelist is empty;
///  2. pre-prompt before the system window (the UI owns that copy);
///  3. no nagging — a hard denial is never re-asked, only routed;
///  4. one home for what is missing — the device-health surface.
///
/// The second guarantee of ADR-050 also lives here: most of our keys are
/// *Special app access* (granted from a system settings screen, not from a
/// runtime dialog), so the caller must explain, give instructions, open that
/// screen and re-check on resume — [PermissionRoute] tells it which case it is.

/// Where a key is granted from.
enum PermissionRoute {
  /// A normal runtime permission dialog.
  runtimeDialog,

  /// Settings > Apps > Special app access — usage access, accessibility,
  /// notification access, battery-optimisation exemption, autostart.
  specialAppAccess,

  /// An OS authorisation sheet rather than a runtime dialog
  /// (iOS Screen Time / Family Controls).
  platformAuthorization,

  /// The key does not exist on this platform (ADR-045).
  notOnPlatform,
}

/// What the UI should do right now for one (device, key) pair.
enum PermissionAction {
  /// Ask in context, after the pre-prompt.
  askInContext,

  /// Already granted — nothing to do.
  nothing,

  /// One re-ask is left: only for a user-initiated action, only with a rationale.
  reaskOnce,

  /// Never ask again — offer the settings path from the device-health row.
  routeToHealthOnly,

  /// The key does not exist on this platform.
  notApplicable,
}

/// ADR-050 rule 1: the "core at launch" whitelist is **empty**. It is a named
/// constant so the rule is testable and any future exception must be added
/// here, by name — never assumed.
const Set<PermKey> kCoreAtLaunch = <PermKey>{};

abstract final class PermissionPolicy {
  /// Which mechanism grants this key on this platform.
  ///
  /// iOS has no counterpart for the Android monitoring keys — but location is
  /// real on both (Core Location on iOS, the ACCESS_LOCATION runtime
  /// permission on Android), so it is *not* marked not-applicable.
  static PermissionRoute routeFor(PermKey key, {required String platform}) {
    final ios = platform.toLowerCase() == 'ios';
    switch (key) {
      case PermKey.screenTimeIos:
        return ios
            ? PermissionRoute.platformAuthorization
            : PermissionRoute.notOnPlatform;
      case PermKey.locationFg:
      case PermKey.locationBg:
        return PermissionRoute.runtimeDialog;
      case PermKey.accessibility:
      case PermKey.notifications:
      case PermKey.usageStats:
      case PermKey.batteryUnrestricted:
      case PermKey.autostart:
        // `notifications` here is notification *access* (reading other apps'
        // notifications), not our own push permission. iOS has no such API.
        return ios
            ? PermissionRoute.notOnPlatform
            : PermissionRoute.specialAppAccess;
    }
  }

  /// The decision for one key, given its observed state.
  ///
  /// [userInitiated] is rule 3's condition: the parent must have asked for the
  /// feature themselves — merely opening the screen is never enough.
  /// [rationaleAvailable] mirrors Android's
  /// `shouldShowRequestPermissionRationale()`.
  static PermissionAction actionFor(
    PermStatus status, {
    bool userInitiated = false,
    bool rationaleAvailable = false,
  }) {
    switch (status) {
      case PermStatus.granted:
        return PermissionAction.nothing;
      case PermStatus.notAsked:
        return PermissionAction.askInContext;
      case PermStatus.deniedSoft:
        return (userInitiated && rationaleAvailable)
            ? PermissionAction.reaskOnce
            : PermissionAction.routeToHealthOnly;
      case PermStatus.deniedPermanent:
      case PermStatus.restrictedByOs:
        // A hard no. Android will not show the dialog again, so the only path
        // left is the settings screen — offered from the device-health row.
        return PermissionAction.routeToHealthOnly;
      case PermStatus.notApplicable:
        return PermissionAction.notApplicable;
    }
  }

  /// A key with no mechanism on this device's platform is NOT_APPLICABLE, never
  /// DENIED — the parent has nothing to fix.
  static PermStatus statusFor(
    PermKey key, {
    required String platform,
    required PermStatus observed,
  }) {
    return routeFor(key, platform: platform) == PermissionRoute.notOnPlatform
        ? PermStatus.notApplicable
        : observed;
  }

  /// ADR-050 rule 4: the keys the device-health surface should list, in a
  /// stable order, and never as popups.
  static List<PermKey> healthRows(Iterable<PermKey> observed) {
    final list = observed.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }
}
