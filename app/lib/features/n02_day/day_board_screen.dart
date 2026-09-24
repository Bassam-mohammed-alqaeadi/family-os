import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/day_board_motion.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Widget keys for SCR-FAT-010 / UI-004 / UI-017 acceptance.
abstract final class DayBoardKeys {
  static const greeting = Key('day_board_greeting');
  static const offlineBanner = Key('day_board_offline_banner');
  static const emptyChildren = Key('day_board_empty_children');
  static const emptyPending = Key('day_board_empty_pending');
  static const activeChild = Key('day_board_active_child');
  static const priority = Key('day_board_priority');
  static const advisorCta = Key('day_board_advisor_cta');
  static const loading = Key('day_board_loading');
  static const syncLine = Key('day_board_sync_line');

  /// UI-017 — decorative pulse motion host (reduce-motion gated).
  static const pulseMotion = Key('day_board_pulse_motion');

  static Key pulse(int i) => Key('day_board_pulse_$i');
}

/// SCR-FAT-010 — لوحة اليوم (bare parent shell, mock-first MVP).
///
/// UI-004: cards bind to [DayBoardProjectionRepository] — empty/loading/error/
/// one/many. No planted Khaled or sample numerals. Pending → real inbox
/// (FAT-033). Advisor CTA → suggest surface only (never silent apply).
class DayBoardScreen extends StatefulWidget {
  const DayBoardScreen({
    super.key,
    this.guardianDisplayName = '',
    this.projectionRepository,
    this.projection,
    this.activeChildIndex = 0,
    this.onChildProfile,
    this.onAllChildren,
    this.onQuran,
    this.onTasks,
    this.onLock,
    this.onMap,
    this.onPendingRequest,
    this.onAdvisor,
  });

  /// Empty → ARB generic guardian fallback (Rule 23).
  final String guardianDisplayName;

  /// Rule 25 seam — null → [stage1DayBoardProjectionRepository]
  /// (Register §10 mock seed for Stage-1 demos; tests pass explicit empty).
  final DayBoardProjectionRepository? projectionRepository;

  /// Sync override for tests — skips async load when non-null.
  final DayBoardProjection? projection;

  final int activeChildIndex;

  /// Test seams — when null, navigates via go_router.
  final VoidCallback? onChildProfile;
  final VoidCallback? onAllChildren;
  final VoidCallback? onQuran;
  final VoidCallback? onTasks;
  final VoidCallback? onLock;
  final VoidCallback? onMap;
  final VoidCallback? onPendingRequest;
  final VoidCallback? onAdvisor;

  @override
  State<DayBoardScreen> createState() => DayBoardScreenState();
}

class DayBoardScreenState extends State<DayBoardScreen> {
  late final DayBoardProjectionRepository _repo;
  DayBoardProjection _projection = DayBoardProjection.loading;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.projectionRepository ?? stage1DayBoardProjectionRepository;
    if (widget.projection != null) {
      _projection = widget.projection!;
      _loaded = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reload();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DayBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projection != null &&
        widget.projection != oldWidget.projection) {
      setState(() {
        _projection = widget.projection!;
        _loaded = true;
      });
    }
  }

  Future<void> _reload() async {
    setState(() {
      _projection = DayBoardProjection.loading;
      _loaded = false;
    });
    try {
      final next = await _repo.load();
      if (!mounted) return;
      setState(() {
        _projection = next.phase == DayBoardPhase.loading
            ? next.copyWith(phase: DayBoardPhase.ready)
            : next;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projection = DayBoardProjection(
          phase: DayBoardPhase.error,
          errorMessage: e.toString(),
        );
        _loaded = true;
      });
    }
  }

  String _resolvedGuardian(AppLocalizations l10n) {
    final raw = widget.guardianDisplayName.trim();
    return raw.isEmpty ? l10n.dayBoardGuardianFallback : raw;
  }

  DayChildMock? get _active {
    final children = _projection.children;
    if (children.isEmpty) return null;
    final i = widget.activeChildIndex.clamp(0, children.length - 1);
    return children[i];
  }

  void _goChild(BuildContext context) {
    if (widget.onChildProfile != null) {
      widget.onChildProfile!();
      return;
    }
    context.go('/scr-fat-013');
  }

  void _go(BuildContext context, VoidCallback? seam, String path) {
    if (seam != null) {
      seam();
      return;
    }
    context.go(path);
  }

  /// Suggest-only — navigate to FAT-011; never approve/apply policy (UI-004 AC3).
  void _openAdvisor(BuildContext context) {
    _go(context, widget.onAdvisor, '/scr-fat-011');
  }

  void _openPending(BuildContext context) {
    final pending = _projection.primaryPending;
    final path = pending?.inboxPath ?? '/scr-fat-033';
    _go(context, widget.onPendingRequest, path);
  }

  String _pendingTitle(AppLocalizations l10n, DayBoardPendingRequest pending) {
    return switch (pending.titleKey) {
      'quizSubmitted' => l10n.dayBoardPendingQuizSubmittedTitle,
      _ =>
        pending.title.isNotEmpty ? pending.title : l10n.dayBoardPriorityTitle,
    };
  }

  String _pendingSubtitle(
    AppLocalizations l10n,
    DayBoardPendingRequest pending,
  ) {
    return switch (pending.subtitleKey) {
      'earnedMinutes' => l10n.dayBoardPendingEarnedMinutes(
        pending.minutes ?? 0,
      ),
      'justSubmitted' => l10n.dayBoardPendingJustSubmitted,
      _ =>
        pending.subtitle.isNotEmpty
            ? pending.subtitle
            : l10n.dayBoardPrioritySubtitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.dayBoardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            Text(
              l10n.dayBoardShellNote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildBody(context, l10n, colors, radii, gradients),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    FamilyRadii radii,
    FamilyGradients gradients,
  ) {
    if (!_loaded || _projection.phase == DayBoardPhase.loading) {
      return Center(
        key: DayBoardKeys.loading,
        child: CircularProgressIndicator(color: colors.p500),
      );
    }

    if (_projection.phase == DayBoardPhase.error) {
      return AppErrorState(
        kind: AppErrorKind.network,
        message: _projection.errorMessage,
        onRetry: _reload,
      );
    }

    final active = _active;
    final pulse = _projection.children.take(3).toList();
    final pending = _projection.primaryPending;
    final syncLabel = _projection.lastSyncLabel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (_projection.offline) ...[
          BannerNote(
            key: DayBoardKeys.offlineBanner,
            message: l10n.dayBoardOfflineBanner(
              syncLabel ?? l10n.dayBoardSyncUnknown,
            ),
            variant: BannerVariant.a,
            leading: Text(
              '☁️',
              style: TextStyle(fontSize: 18, color: colors.ink),
            ),
          ),
          const SizedBox(height: 12),
        ] else if (syncLabel != null) ...[
          Text(
            key: DayBoardKeys.syncLine,
            l10n.dayBoardSyncLine(syncLabel),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _GreetingRow(
          greeting: l10n.dayBoardGreeting(_resolvedGuardian(l10n)),
          subtitle: _projection.hasChildren
              ? l10n.dayBoardGreetingSub
              : l10n.dayBoardGreetingSubEmpty,
          pulseLabel: l10n.dayBoardPulseLabel,
          children: pulse,
          colors: colors,
          onAvatarTap: () => _goChild(context),
        ),
        const SizedBox(height: 12),
        if (active == null)
          _EmptyChildrenCard(
            colors: colors,
            radii: radii,
            title: l10n.dayBoardEmptyChildrenTitle,
            subtitle: l10n.dayBoardEmptyChildrenSubtitle,
          )
        else
          _ActiveChildCard(
            child: active,
            colors: colors,
            radii: radii,
            gradients: gradients,
            activeTag: l10n.dayBoardActiveTag,
            timeLeft: l10n.dayBoardStatTimeLeft(active.timeLeftLabel),
            quran: l10n.dayBoardStatQuran(active.quranLabel),
            wallet: l10n.dayBoardStatWallet(active.walletLabel),
            title: l10n.dayBoardChildTitle(active.displayName, active.ageYears),
            locationBattery: l10n.dayBoardLocationBattery(
              active.locationLabel,
              active.batteryLabel,
            ),
            onTap: () => _goChild(context),
          ),
        const SizedBox(height: 12),
        AppCard(
          title: l10n.dayBoardQuickTitle,
          linkLabel: l10n.dayBoardAllChildren,
          onLinkTap: () => _go(context, widget.onAllChildren, '/scr-fat-012'),
          child: _QuickGrid(
            colors: colors,
            radii: radii,
            quran: l10n.dayBoardQuickQuran,
            tasks: l10n.dayBoardQuickTasks,
            lock: l10n.dayBoardQuickLock,
            lockSemantics: l10n.spineCtaLockSemantics,
            map: l10n.dayBoardQuickMap,
            onQuran: () => _go(context, widget.onQuran, '/scr-fat-072'),
            onTasks: () => _go(context, widget.onTasks, '/scr-fat-054'),
            onLock: () => _go(context, widget.onLock, '/scr-fat-037'),
            onMap: () => _go(context, widget.onMap, '/scr-fat-014'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.dayBoardPrioritySection,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (pending == null)
          _EmptyPendingCard(
            colors: colors,
            radii: radii,
            title: l10n.dayBoardEmptyPendingTitle,
            subtitle: l10n.dayBoardEmptyPendingSubtitle,
          )
        else
          _PriorityCard(
            colors: colors,
            radii: radii,
            title: _pendingTitle(l10n, pending),
            subtitle: _pendingSubtitle(l10n, pending),
            tagLabel: l10n.dayBoardPriorityTag,
            onTap: () => _openPending(context),
          ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BannerNote(
                message: l10n.dayBoardAdvisorBanner,
                variant: BannerVariant.p,
                leading: Text(
                  '🧠',
                  style: TextStyle(fontSize: 18, color: colors.ink),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryBtn(
                key: DayBoardKeys.advisorCta,
                label: l10n.dayBoardAdvisorCta,
                variant: PrimaryBtnVariant.ghost,
                onPressed: () => _openAdvisor(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.greeting,
    required this.subtitle,
    required this.pulseLabel,
    required this.children,
    required this.colors,
    required this.onAvatarTap,
  });

  final String greeting;
  final String subtitle;
  final String pulseLabel;
  final List<DayChildMock> children;
  final FamilyColors colors;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: DayBoardKeys.greeting,
                greeting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
            ],
          ),
        ),
        if (children.isNotEmpty)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pulseLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
                const SizedBox(height: 4),
                _PulseAvatarRow(
                  children: children,
                  colors: colors,
                  onAvatarTap: onAvatarTap,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// UI-017 — nonessential scale pulse; duration=0 when reduce-motion.
class _PulseAvatarRow extends StatelessWidget {
  const _PulseAvatarRow({
    required this.children,
    required this.colors,
    required this.onAvatarTap,
  });

  final List<DayChildMock> children;
  final FamilyColors colors;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return DayBoardMotionPulse(
      key: DayBoardKeys.pulseMotion,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        children: [
          for (var i = 0; i < children.length; i++)
            _PulseAvatar(
              key: DayBoardKeys.pulse(i),
              child: children[i],
              colors: colors,
              onTap: onAvatarTap,
            ),
        ],
      ),
    );
  }
}

class _PulseAvatar extends StatelessWidget {
  const _PulseAvatar({
    super.key,
    required this.child,
    required this.colors,
    required this.onTap,
  });

  final DayChildMock child;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: child.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: child.resolveColor(colors),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(child.emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  const _EmptyChildrenCard({
    required this.colors,
    required this.radii,
    required this.title,
    required this.subtitle,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: DayBoardKeys.emptyChildren,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPendingCard extends StatelessWidget {
  const _EmptyPendingCard({
    required this.colors,
    required this.radii,
    required this.title,
    required this.subtitle,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: DayBoardKeys.emptyPending,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text('📭', style: TextStyle(fontSize: 22, color: colors.ink)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChildCard extends StatelessWidget {
  const _ActiveChildCard({
    required this.child,
    required this.colors,
    required this.radii,
    required this.gradients,
    required this.activeTag,
    required this.timeLeft,
    required this.quran,
    required this.wallet,
    required this.title,
    required this.locationBattery,
    required this.onTap,
  });

  final DayChildMock child;
  final FamilyColors colors;
  final FamilyRadii radii;
  final FamilyGradients gradients;
  final String activeTag;
  final String timeLeft;
  final String quran;
  final String wallet;
  final String title;
  final String locationBattery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: DayBoardKeys.activeChild,
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.card),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradients.grad,
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          child.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationBattery,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(radii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            child: Text(
                              activeTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: colors.mintInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeLeft,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              quran,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              wallet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.colors,
    required this.radii,
    required this.quran,
    required this.tasks,
    required this.lock,
    required this.lockSemantics,
    required this.map,
    required this.onQuran,
    required this.onTasks,
    required this.onLock,
    required this.onMap,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String quran;
  final String tasks;
  final String lock;
  final String lockSemantics;
  final String map;
  final VoidCallback onQuran;
  final VoidCallback onTasks;
  final VoidCallback onLock;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        key: 'day_board_quick_quran',
        icon: '📖',
        label: quran,
        semantics: quran,
        onTap: onQuran,
      ),
      (
        key: 'day_board_quick_tasks',
        icon: '📋',
        label: tasks,
        semantics: tasks,
        onTap: onTasks,
      ),
      (
        key: 'day_board_quick_lock',
        icon: '🔒',
        label: lock,
        semantics: lockSemantics,
        onTap: onLock,
      ),
      (
        key: 'day_board_quick_map',
        icon: '🗺️',
        label: map,
        semantics: map,
        onTap: onMap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileW = (constraints.maxWidth - gap * 3) / 4;
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: tileW,
                child: _QuickTile(
                  key: Key(items[i].key),
                  icon: items[i].icon,
                  label: items[i].label,
                  semanticsLabel: items[i].semantics,
                  colors: colors,
                  radii: radii,
                  onTap: items[i].onTap,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.colors,
    required this.radii,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String semanticsLabel;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.tcard),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(radii.tcard),
              border: Border.all(color: colors.border),
            ),
            child: ConstrainedBox(
              // UI-015 / Rule 16 — quick-lock (and peers) ≥48×48.
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      icon,
                      style: TextStyle(fontSize: 22, color: colors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.colors,
    required this.radii,
    required this.title,
    required this.subtitle,
    required this.tagLabel,
    required this.onTap,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String title;
  final String subtitle;
  final String tagLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: DayBoardKeys.priority,
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.amber100,
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.amber, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text('⏱️', style: TextStyle(fontSize: 22, color: colors.ink)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.amberDeep,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.amberInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Tag(label: tagLabel, variant: TagVariant.a),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
