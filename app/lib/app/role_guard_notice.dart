import 'package:flutter/material.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/i18n/app_localizations.dart';

/// Wraps a role home route; when the route was reached through a RoleGuard
/// redirect ([roleGuardLandingFor]) it shows one polite toast (Owner D4).
class RoleGuardLandingNotice extends StatefulWidget {
  const RoleGuardLandingNotice({
    super.key,
    required this.uri,
    required this.isChildHome,
    required this.child,
  });

  final Uri uri;

  /// Child home (SCR-CHD-004) uses the gentle child wording.
  final bool isChildHome;

  final Widget child;

  @override
  State<RoleGuardLandingNotice> createState() => _RoleGuardLandingNoticeState();
}

class _RoleGuardLandingNoticeState extends State<RoleGuardLandingNotice> {
  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  @override
  void didUpdateWidget(covariant RoleGuardLandingNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uri != oldWidget.uri) _maybeShow();
  }

  void _maybeShow() {
    if (!isRoleGuardBlockedLanding(widget.uri)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppToast.show(
        context,
        message: widget.isChildHome
            ? l10n.roleGuardBlockedChild
            : l10n.roleGuardBlockedParent,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
