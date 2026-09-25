import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/entitlement_service.dart';
import 'package:family_os/features/n11_billing/billing_ux_bridge.dart';
import 'package:go_router/go_router.dart';

/// Widget keys for SCR-FAT-057 / UI-007 acceptance.
abstract final class ManageSubscriptionKeys {
  static const screen = Key('manage_subscription_screen');
  static const safetyBanner = Key('manage_safety_never_gated_banner');
  static const denyPanel = Key('manage_deny_panel');
  static const statusTag = Key('manage_status_tag');
  static const cancelRenewal = Key('manage_cancel_renewal');
  static const openPlans = Key('manage_open_plans');
}

/// SCR-FAT-057 — إدارة الاشتراك (UI-007 / Rule 9 / P-4).
///
/// Cancel / trial end never disables SOS or chat. Father OWNER only.
class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({
    super.key,
    this.entitlement,
    this.roleOverride,
  });

  final EntitlementService? entitlement;
  final AppRole? roleOverride;

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  late final EntitlementService _entitlement;
  Listenable? _listenable;
  var _cancelling = false;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _allowed => canOpenBilling(_role);

  @override
  void initState() {
    super.initState();
    _entitlement = widget.entitlement ?? Stage1BillingRuntime.service;
    final e = _entitlement;
    if (e is Listenable) {
      final listenable = e as Listenable;
      _listenable = listenable;
      listenable.addListener(_onEntitlement);
    }
  }

  @override
  void dispose() {
    _listenable?.removeListener(_onEntitlement);
    super.dispose();
  }

  void _onEntitlement() {
    if (mounted) setState(() {});
  }

  Future<void> _cancelRenewal() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    await _entitlement.cancelRenewal();
    if (!mounted) return;
    setState(() => _cancelling = false);
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.billingCancelAck);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    if (!_allowed) {
      return Scaffold(
        key: ManageSubscriptionKeys.screen,
        appBar: AppBar(title: Text(l10n.manageSubscriptionTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BannerNote(
            key: ManageSubscriptionKeys.denyPanel,
            variant: BannerVariant.a,
            message: l10n.billingOwnerOnlyDeny,
          ),
        ),
      );
    }

    final ent = _entitlement.current;

    return Scaffold(
      key: ManageSubscriptionKeys.screen,
      appBar: AppBar(title: Text(l10n.manageSubscriptionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BannerNote(
            key: ManageSubscriptionKeys.safetyBanner,
            variant: BannerVariant.t,
            message: l10n.billingSafetyNeverGated,
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.manageCurrentPlan(_planDisplayName(l10n, ent)),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Tag(
                        key: ManageSubscriptionKeys.statusTag,
                        label: _statusLabel(l10n, ent),
                        variant: switch (ent.status) {
                          EntitlementStatus.active => TagVariant.g,
                          EntitlementStatus.trial => TagVariant.p,
                          EntitlementStatus.expired => TagVariant.a,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ent.autoRenew
                        ? l10n.manageAutoRenewOn
                        : l10n.manageAutoRenewOff,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: ManageSubscriptionKeys.openPlans,
            label: l10n.manageChangePlan,
            onPressed: () => context.go(screenPath('SCR-FAT-056')),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ManageSubscriptionKeys.cancelRenewal,
            label: l10n.manageCancelRenewal,
            variant: PrimaryBtnVariant.ghost,
            onPressed: ent.isExpired || _cancelling ? null : _cancelRenewal,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.manageCancelSafetyNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.ink2,
                ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, Entitlement ent) {
    return switch (ent.status) {
      EntitlementStatus.active => l10n.billingStatusActive,
      EntitlementStatus.trial => l10n.billingStatusTrial(
          ent.trialDaysRemaining ?? 0,
        ),
      EntitlementStatus.expired => l10n.billingStatusExpired,
    };
  }

  String _planDisplayName(AppLocalizations l10n, Entitlement ent) {
    return switch (ent.planId) {
      'family_smart' => l10n.plansFamilySmartTitle,
      'trial_full' => l10n.plansFamilySmartTitle,
      _ => l10n.plansBasicSafetyTitle,
    };
  }
}
