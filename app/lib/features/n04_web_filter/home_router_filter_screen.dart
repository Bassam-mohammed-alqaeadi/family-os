import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n04_web_filter/home_router_filter_models.dart';
import 'package:family_os/features/n04_web_filter/home_router_filter_repository.dart';

abstract final class HomeRouterFilterKeys {
  static const screen = Key('home_router_filter_screen');
  static const loading = Key('home_router_filter_loading');
  static const empty = Key('home_router_filter_empty');
  static const body = Key('home_router_filter_body');
  static const hero = Key('home_router_filter_hero');
  static const howCard = Key('home_router_filter_how');
  static const guideCta = Key('home_router_filter_guide');
  static const checkCta = Key('home_router_filter_check');
  static const observerHint = Key('home_router_filter_observer');
  static const childLean = Key('home_router_filter_child_lean');
  static const sosIconCta = Key('home_router_filter_sos_icon');
}

/// SCR-FAT-078 — فلترة الراوتر المنزلي.
class HomeRouterFilterScreen extends StatefulWidget {
  const HomeRouterFilterScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final HomeRouterFilterRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<HomeRouterFilterScreen> createState() => _HomeRouterFilterScreenState();
}

class _HomeRouterFilterScreenState extends State<HomeRouterFilterScreen> {
  late HomeRouterFilterRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  HomeRouterFilterSnapshot _snap = const HomeRouterFilterSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;
  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.full ||
          widget.motherLevel == MotherLevel.partner;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1HomeRouterFilterRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _loading = false;
    });
  }

  Future<void> _openSos() async {
    if (_sosBusy) return;
    if (widget.onSos != null) {
      widget.onSos!();
      return;
    }
    setState(() => _sosBusy = true);
    await _sos.fire(childId: 'self');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  Future<void> _guide() async {
    if (!_canAct) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).homeRouterFilterObserverBlocked,
      );
      return;
    }
    final snap = await _repo.openGuide();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(context).homeRouterFilterGuideToast,
    );
  }

  Future<void> _check() async {
    if (!_canAct) {
      AppToast.show(
        context,
        message: AppLocalizations.of(context).homeRouterFilterObserverBlocked,
      );
      return;
    }
    await _repo.runProtectionCheck();
    if (!mounted) return;
    AppToast.show(
      context,
      message: AppLocalizations.of(context).homeRouterFilterCheckToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: HomeRouterFilterKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.homeRouterFilterTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: HomeRouterFilterKeys.sosIconCta,
            tooltip: l10n.spineCtaSosSemantics,
            onPressed: _sosBusy ? null : _openSos,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
            icon: Icon(Icons.sos, color: colors.coral),
          ),
        ],
      ),
      body: SafeArea(child: _body(l10n, colors)),
    );
  }

  Widget _body(AppLocalizations l10n, FamilyColors colors) {
    if (_isChild) {
      return AppEmptyState(
        key: HomeRouterFilterKeys.childLean,
        title: l10n.homeRouterFilterChildLeanTitle,
        message: l10n.homeRouterFilterChildLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: HomeRouterFilterKeys.loading,
        child: Semantics(
          label: l10n.homeRouterFilterLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: HomeRouterFilterKeys.empty,
        title: l10n.homeRouterFilterEmptyTitle,
        message: l10n.homeRouterFilterEmptyMessage,
        actionLabel: l10n.homeRouterFilterEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: HomeRouterFilterKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: HomeRouterFilterKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.homeRouterFilterObserverHint,
            ),
            const SizedBox(height: 10),
          ],
          DecoratedBox(
            key: HomeRouterFilterKeys.hero,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  const Text('📡', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  Text(
                    _snap.protected
                        ? l10n.homeRouterFilterHeroProtected
                        : l10n.homeRouterFilterHeroUnprotected,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.homeRouterFilterHeroSub(_snap.deviceCount),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _snap.protected ? 1 : 0.35,
                      minHeight: 8,
                      backgroundColor: colors.border,
                      color: colors.mint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: HomeRouterFilterKeys.howCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.homeRouterFilterHowHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  _howRow(
                    colors,
                    '1️⃣',
                    l10n.homeRouterFilterHowDnsTitle,
                    l10n.homeRouterFilterHowDnsSub,
                    _snap.dnsActive
                        ? l10n.homeRouterFilterTagActive
                        : l10n.homeRouterFilterTagOff,
                    _snap.dnsActive,
                  ),
                  _howRow(
                    colors,
                    '2️⃣',
                    l10n.homeRouterFilterHowCatsTitle,
                    l10n.homeRouterFilterHowCatsSub,
                    _snap.categoriesSynced
                        ? l10n.homeRouterFilterTagSynced
                        : l10n.homeRouterFilterTagOff,
                    _snap.categoriesSynced,
                  ),
                  _howRow(
                    colors,
                    '3️⃣',
                    l10n.homeRouterFilterHowAwayTitle,
                    l10n.homeRouterFilterHowAwaySub,
                    l10n.homeRouterFilterTagAuto,
                    false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: HomeRouterFilterKeys.guideCta,
            label: l10n.homeRouterFilterGuideCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _canAct ? _guide : null,
          ),
          const SizedBox(height: 8),
          PrimaryBtn(
            key: HomeRouterFilterKeys.checkCta,
            label: l10n.homeRouterFilterCheckCta,
            variant: PrimaryBtnVariant.teal,
            onPressed: _canAct ? _check : null,
          ),
          const SizedBox(height: 10),
          BannerNote(
            variant: BannerVariant.t,
            message: l10n.homeRouterFilterGuestBanner,
          ),
        ],
      ),
    );
  }

  Widget _howRow(
    FamilyColors colors,
    String num,
    String title,
    String sub,
    String tag,
    bool mint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(num, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Tag(label: tag, variant: mint ? TagVariant.g : TagVariant.t),
        ],
      ),
    );
  }
}
