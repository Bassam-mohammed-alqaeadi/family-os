import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/entitlement.dart';
import 'package:family_os/core/policy/entitlement_service.dart';
import 'package:go_router/go_router.dart';

/// Widget keys for SCR-FAT-056 / UI-007 acceptance.
abstract final class PlansScreenKeys {
  static const screen = Key('plans_screen');
  static const safetyBanner = Key('plans_safety_never_gated_banner');
  static const denyPanel = Key('plans_deny_panel');
  static const planBasic = Key('plans_basic_safety');
  static const planFamily = Key('plans_family_smart');
  static const statusTag = Key('plans_status_tag');
  static const openManage = Key('plans_open_manage');
}

/// SCR-FAT-056 — الباقات والاشتراك (UI-007 / Rule 9 / P-4).
///
/// Father OWNER only. Plan UI never disables SOS/chat/location.
/// Numbers are provisional (prototype). Mock entitlement only.
class PlansScreen extends StatefulWidget {
  const PlansScreen({
    super.key,
    this.entitlement,
    this.roleOverride,
  });

  /// Rule 25 seam — null → [stage1EntitlementService].
  final EntitlementService? entitlement;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late final EntitlementService _entitlement;
  Listenable? _listenable;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _allowed => canOpenBilling(_role);

  @override
  void initState() {
    super.initState();
    _entitlement = widget.entitlement ?? stage1EntitlementService;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    if (!_allowed) {
      return Scaffold(
        key: PlansScreenKeys.screen,
        appBar: AppBar(title: Text(l10n.plansTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BannerNote(
            key: PlansScreenKeys.denyPanel,
            variant: BannerVariant.a,
            message: l10n.billingOwnerOnlyDeny,
          ),
        ),
      );
    }

    final ent = _entitlement.current;

    return Scaffold(
      key: PlansScreenKeys.screen,
      appBar: AppBar(title: Text(l10n.plansTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BannerNote(
            key: PlansScreenKeys.safetyBanner,
            variant: BannerVariant.t,
            message: l10n.billingSafetyNeverGated,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Tag(
              key: PlansScreenKeys.statusTag,
              label: _statusLabel(l10n, ent),
              variant: switch (ent.status) {
                EntitlementStatus.active => TagVariant.g,
                EntitlementStatus.trial => TagVariant.p,
                EntitlementStatus.expired => TagVariant.a,
              },
            ),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            key: PlansScreenKeys.planFamily,
            title: l10n.plansFamilySmartTitle,
            subtitle: l10n.plansFamilySmartSubtitle,
            price: l10n.plansFamilySmartPrice,
            recommended: true,
            borderColor: colors.p500,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            key: PlansScreenKeys.planBasic,
            title: l10n.plansBasicSafetyTitle,
            subtitle: l10n.plansBasicSafetySubtitle,
            price: l10n.plansBasicSafetyPrice,
            bullets: [
              l10n.plansBasicBulletSos,
              l10n.plansBasicBulletChat,
              l10n.plansBasicBulletScreenTime,
            ],
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            key: PlansScreenKeys.openManage,
            label: l10n.plansOpenManage,
            onPressed: () => context.go(screenPath('SCR-FAT-057')),
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
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    this.bullets = const [],
    this.recommended = false,
    this.borderColor,
  });

  final String title;
  final String subtitle;
  final String price;
  final List<String> bullets;
  final bool recommended;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(
          color: borderColor ?? colors.border,
          width: recommended ? 2 : 1,
        ),
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
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (recommended)
                  Tag(label: l10n.plansRecommended, variant: TagVariant.p),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.ink2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            for (final b in bullets) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative glyph only — Rule 12 / UI-016 (not ARB copy).
                  Icon(Icons.check, size: 18, color: colors.mintInk),
                  const SizedBox(width: 4),
                  Expanded(child: Text(b)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
