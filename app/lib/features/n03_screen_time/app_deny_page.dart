import 'package:flutter/material.dart';

import 'package:family_os/core/app_control/app_control.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n03_screen_time/app_control_ux_bridge.dart';

/// Widget keys for child App Control deny interstitial (L3 AC-C-DENY).
abstract final class AppDenyPageKeys {
  static const page = Key('app_deny_page');
  static const title = Key('app_deny_title');
  static const reason = Key('app_deny_reason');
  static const disclosure = Key('app_deny_disclosure');
  static const exceptionCta = Key('app_deny_exception_cta');
  static const chatCta = Key('app_deny_chat_cta');
  static const quranCta = Key('app_deny_quran_cta');
  static const sosCta = Key('app_deny_sos_cta');
  static const pendingBanner = Key('app_deny_pending_banner');
}

/// Child-facing package deny interstitial — no admin, honest source-of-deny.
///
/// Hosted like [WebBlockPage] (no new SCR id). Exception Request ≠ ST minutes.
class AppDenyPage extends StatelessWidget {
  const AppDenyPage({
    super.key,
    required this.packageId,
    required this.packageLabel,
    required this.verdict,
    this.childId,
    this.appControl,
    this.exceptionPending = false,
    this.onExceptionRequested,
    this.onOpenChat,
    this.onOpenQuran,
    this.onSos,
    this.isPreview = false,
  });

  final String packageId;
  final String packageLabel;
  final AppControlVerdict verdict;
  final ChildId? childId;
  final AppControlService? appControl;
  final bool exceptionPending;
  final VoidCallback? onExceptionRequested;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenQuran;
  final VoidCallback? onSos;
  final bool isPreview;

  bool get _showExceptionCta {
    if (isPreview || exceptionPending) return false;
    if (verdict.allowed) return false;
    return verdict.denySource == AppControlDenySource.permanentBlock ||
        verdict.denySource == AppControlDenySource.lockNow ||
        verdict.denySource == AppControlDenySource.pendingUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return Material(
      key: AppDenyPageKeys.page,
      color: colors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.apps_outage_outlined, size: 48, color: colors.p700),
              const SizedBox(height: 16),
              Text(
                l10n.appDenyTitle,
                key: AppDenyPageKeys.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                packageLabel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.ink2),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                key: AppDenyPageKeys.reason,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    AppControlUxBridge.denyReasonLabel(
                      l10n,
                      verdict.denySource,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appDenyDisclosure,
                key: AppDenyPageKeys.disclosure,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: colors.ink2),
              ),
              if (exceptionPending) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.appDenyExceptionPending,
                  key: AppDenyPageKeys.pendingBanner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.amberDeep,
                  ),
                ),
              ],
              const Spacer(),
              if (_showExceptionCta) ...[
                PrimaryBtn(
                  key: AppDenyPageKeys.exceptionCta,
                  label: l10n.appDenyExceptionCta,
                  variant: PrimaryBtnVariant.mint,
                  onPressed: () => _requestException(context),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appDenyExceptionNotMinutes,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      key: AppDenyPageKeys.chatCta,
                      label: l10n.appDenyChatCta,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: onOpenChat,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryBtn(
                      key: AppDenyPageKeys.quranCta,
                      label: l10n.appDenyQuranCta,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: onOpenQuran,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PrimaryBtn(
                key: AppDenyPageKeys.sosCta,
                label: l10n.appDenySosCta,
                variant: PrimaryBtnVariant.coral,
                onPressed: onSos,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestException(BuildContext context) async {
    final service = appControl;
    final id = childId;
    if (service == null || id == null) {
      onExceptionRequested?.call();
      return;
    }
    await service.requestException(childId: id, packageId: packageId);
    if (!context.mounted) return;
    onExceptionRequested?.call();
  }
}
