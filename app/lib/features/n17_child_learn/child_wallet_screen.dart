import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/enforcement_status_badge.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_models.dart';
import 'package:family_os/features/n17_child_learn/child_wallet_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Widget keys for SCR-CHD-019 acceptance.
abstract final class ChildWalletKeys {
  static const screen = Key('child_wallet_screen');
  static const loading = Key('child_wallet_loading');
  static const empty = Key('child_wallet_empty');
  static const body = Key('child_wallet_body');
  static const hero = Key('child_wallet_hero');
  static const badges = Key('child_wallet_badges');
  static const apps = Key('child_wallet_apps');
  static const earnQuran = Key('child_wallet_earn_quran');
  static const earnTasks = Key('child_wallet_earn_tasks');
  static const earnQuiz = Key('child_wallet_earn_quiz');
  static const parentLean = Key('child_wallet_parent_lean');
  static const sosIconCta = Key('child_wallet_sos_icon');

  static Key appRow(String id) => Key('child_wallet_app_$id');
  static Key badge(String id) => Key('child_wallet_badge_$id');
}

/// SCR-CHD-019 — محفظتي وشاراتي (minutes wallet + prestige badges).
///
/// Prototype CHD-019 · RoleGuard child · minutes-only (no points/XP) ·
/// badges = pride not currency · P-4 SOS · Rule 12/23.
class ChildWalletScreen extends StatefulWidget {
  const ChildWalletScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildWalletRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildWalletScreen> createState() => _ChildWalletScreenState();
}

class _ChildWalletScreenState extends State<ChildWalletScreen> {
  late ChildWalletRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildWalletSnapshot _snap = const ChildWalletSnapshot();
  var _scopedRepoBound = false;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return resolveAuthorizationContext(context, fallbackRole: AppRole.child).role;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.wallet;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.repository != null || _scopedRepoBound) return;
    // The Drift wallet resolves the acting child at load time, so a scope
    // change is followed by the next load instead of rebuilding the repo here.
    _repo = Stage1LearnRuntime.wallet;
    _scopedRepoBound = true;
    _load();
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
    final childId = CurrentIdentity.maybeOf(context)?.activeChildId.value ?? 'self';
    await _sos.fire(childId: childId);
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-CHD-005'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _appName(AppLocalizations l10n, String key) {
    return switch (key) {
      'youtube' => l10n.childWalletAppYoutube,
      'games' => l10n.childWalletAppGames,
      'social' => l10n.childWalletAppSocial,
      'quran' => l10n.childWalletAppQuran,
      _ => key,
    };
  }

  String _badgeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'firstWird' => l10n.childWalletBadgeFirstWird,
      'adhkarWeek' => l10n.childWalletBadgeAdhkarWeek,
      'focusFive' => l10n.childWalletBadgeFocusFive,
      'monthStreak' => l10n.childWalletBadgeMonthStreak,
      'familyHero' => l10n.childWalletBadgeFamilyHero,
      _ => l10n.childWalletBadgeFirstWird,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildWalletKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childWalletTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildWalletKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(l10n, colors)),
    );
  }

  Widget _buildBody(AppLocalizations l10n, FamilyColors colors) {
    if (!_isChild) {
      return AppEmptyState(
        key: ChildWalletKeys.parentLean,
        title: l10n.childWalletParentLeanTitle,
        message: l10n.childWalletParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildWalletKeys.loading,
        child: Semantics(
          label: l10n.childWalletLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildWalletKeys.empty,
        title: l10n.childWalletEmptyTitle,
        message: l10n.childWalletEmptyMessage,
        actionLabel: l10n.childWalletEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildWalletKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_snap.simulated) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: EnforcementStatusBadge(
                label: l10n.childWalletSimulatedTag,
              ),
            ),
            const SizedBox(height: 10),
          ],
          DecoratedBox(
            key: ChildWalletKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.teal, colors.teal600]),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                children: [
                  Text(
                    l10n.childWalletTotalMinutes(_snap.totalMinutes),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.childWalletTotalCaption,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.childWalletStreakAndBadges(
                      _snap.streakDays,
                      _snap.earnedBadgeCount,
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            colors: colors,
            radii: radii,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childWalletCompeteHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.childWalletRecordLine(_snap.recordStreakDays),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                Text(
                  l10n.childWalletCurrentStreakLine(_snap.streakDays),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            colors: colors,
            radii: radii,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childWalletBadgesHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  key: ChildWalletKeys.badges,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final b in _snap.badges)
                      Tag(
                        key: ChildWalletKeys.badge(b.id),
                        label: _badgeLabel(l10n, b.labelKey),
                        variant: b.earned ? TagVariant.g : TagVariant.t,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.childWalletBadgesFootnote(_snap.earnedBadgeCount),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.childWalletBadgesNotCurrency,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            colors: colors,
            radii: radii,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childWalletAppsHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                Text(
                  l10n.childWalletAppsCaption,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  key: ChildWalletKeys.apps,
                  children: [
                    for (final a in _snap.apps) ...[
                      ListTile(
                        key: ChildWalletKeys.appRow(a.id),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _appName(l10n, a.nameKey),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                        subtitle: Text(
                          a.walletMinutes > 0
                              ? l10n.childWalletAppBalance(a.walletMinutes)
                              : l10n.childWalletAppNoBalance,
                          style: TextStyle(fontSize: 12, color: colors.ink2),
                        ),
                        trailing: Tag(
                          label: a.walletMinutes > 0
                              ? l10n.childWalletMinutesTag(a.walletMinutes)
                              : l10n.childWalletZeroTag,
                          variant: a.walletMinutes > 0
                              ? TagVariant.g
                              : TagVariant.t,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            colors: colors,
            radii: radii,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childWalletEarnHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  key: ChildWalletKeys.earnQuran,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.childWalletEarnQuranTitle),
                  subtitle: Text(l10n.childWalletEarnQuranBody),
                  trailing: Icon(Icons.chevron_left, color: colors.ink2),
                  onTap: () => _go('SCR-CHD-025'),
                ),
                ListTile(
                  key: ChildWalletKeys.earnTasks,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.childWalletEarnTasksTitle),
                  subtitle: Text(l10n.childWalletEarnTasksBody),
                  trailing: Icon(Icons.chevron_left, color: colors.ink2),
                  onTap: () => _go('SCR-CHD-022'),
                ),
                ListTile(
                  key: ChildWalletKeys.earnQuiz,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.childWalletEarnQuizTitle),
                  subtitle: Text(l10n.childWalletEarnQuizBody),
                  trailing: Icon(Icons.chevron_left, color: colors.ink2),
                  onTap: () => _go('SCR-CHD-015'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.colors, required this.radii, required this.child});

  final FamilyColors colors;
  final FamilyRadii radii;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: child,
      ),
    );
  }
}
