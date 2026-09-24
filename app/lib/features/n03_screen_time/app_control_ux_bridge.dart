import 'package:family_os/core/app_control/app_control.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';

/// FS-003-UX helpers — bind Stage-1 FAT-034/035 to App Control domain.
abstract final class AppControlUxBridge {
  static AppControlActor actorFor({
    required AppRole role,
    MotherLevel motherLevel = MotherLevel.partner,
  }) {
    if (role == AppRole.father) return const AppControlActor.father();
    if (role == AppRole.mother) return AppControlActor.mother(motherLevel);
    return const AppControlActor.child();
  }

  /// Permanent Block / Allow disposition — Primary + Full (APP-OD-02/03).
  static bool canConfigureAccess({
    required AppRole role,
    MotherLevel motherLevel = MotherLevel.partner,
  }) {
    return actorFor(role: role, motherLevel: motherLevel).canConfigure;
  }

  /// Install + Exception decide — Primary + Partner + Full (APP-OD-05/07).
  static bool canDecideTickets({
    required AppRole role,
    MotherLevel motherLevel = MotherLevel.partner,
  }) {
    return actorFor(role: role, motherLevel: motherLevel).canDecideTickets;
  }

  static bool isProtectedApp(ChildAppEntry app) {
    return ProtectedPackageIds.isProtected(app.id);
  }

  static String denyReasonLabel(
    AppLocalizations l10n,
    AppControlDenySource? source,
  ) {
    return switch (source) {
      AppControlDenySource.permanentBlock => l10n.appDenyReasonBlocked,
      AppControlDenySource.lockNow => l10n.appDenyReasonLockNow,
      AppControlDenySource.pendingUnknown => l10n.appDenyReasonPending,
      null => l10n.appDenyReasonGeneric,
    };
  }
}
