import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_models.dart';
import 'package:family_os/features/n17_child_learn/child_daily_review_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

abstract final class ChildDailyReviewKeys {
  static const screen = Key('child_daily_review_screen');
  static const loading = Key('child_daily_review_loading');
  static const empty = Key('child_daily_review_empty');
  static const body = Key('child_daily_review_body');
  static const hero = Key('child_daily_review_hero');
  static const cards = Key('child_daily_review_cards');
  static const startCta = Key('child_daily_review_start');
  static const parentLean = Key('child_daily_review_parent_lean');
  static const sosIconCta = Key('child_daily_review_sos_icon');

  static Key card(String id) => Key('child_daily_review_card_$id');
}

/// SCR-CHD-029 — مراجعة اليوم.
class ChildDailyReviewScreen extends StatefulWidget {
  const ChildDailyReviewScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildDailyReviewRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildDailyReviewScreen> createState() => _ChildDailyReviewScreenState();
}

class _ChildDailyReviewScreenState extends State<ChildDailyReviewScreen> {
  late ChildDailyReviewRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildDailyReviewSnapshot _snap = const ChildDailyReviewSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.dailyReview;
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

  String _title(AppLocalizations l10n, String key) => switch (key) {
    'fractions' => l10n.childDailyReviewCardFractions,
    'unit4' => l10n.childDailyReviewCardUnit4,
    'waterCycle' => l10n.childDailyReviewCardWaterCycle,
    _ => key,
  };

  String _meta(AppLocalizations l10n, String key) => switch (key) {
    'threeDays' => l10n.childDailyReviewMetaThreeDays,
    'oneWeek' => l10n.childDailyReviewMetaOneWeek,
    'twiceStrong' => l10n.childDailyReviewMetaTwiceStrong,
    _ => key,
  };

  Future<void> _start() async {
    final snap = await _repo.completeSession();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(
        context,
      ).childDailyReviewDoneToast(snap.rewardMinutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: ChildDailyReviewKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childDailyReviewTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildDailyReviewKeys.sosIconCta,
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
    if (!_isChild) {
      return AppEmptyState(
        key: ChildDailyReviewKeys.parentLean,
        title: l10n.childDailyReviewParentLeanTitle,
        message: l10n.childDailyReviewParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildDailyReviewKeys.loading,
        child: Semantics(
          label: l10n.childDailyReviewLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildDailyReviewKeys.empty,
        title: l10n.childDailyReviewEmptyTitle,
        message: l10n.childDailyReviewEmptyMessage,
        actionLabel: l10n.childDailyReviewEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildDailyReviewKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            key: ChildDailyReviewKeys.hero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.teal, colors.teal600],
              ),
              borderRadius: BorderRadius.circular(radii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
              child: Column(
                children: [
                  Text(
                    l10n.childDailyReviewHeroTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.childDailyReviewHeroSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: ChildDailyReviewKeys.cards,
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
                    l10n.childDailyReviewCardsHeading(_snap.cards.length),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  for (final c in _snap.cards)
                    Padding(
                      key: ChildDailyReviewKeys.card(c.id),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title(l10n, c.titleKey),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                Text(
                                  _meta(l10n, c.metaKey),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tag(
                            label: c.strong
                                ? l10n.childDailyReviewTagStrong
                                : l10n.childDailyReviewTagDue,
                            variant: c.strong ? TagVariant.g : TagVariant.t,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ChildDailyReviewKeys.startCta,
            label: _snap.sessionDone
                ? l10n.childDailyReviewDoneCta
                : l10n.childDailyReviewStartCta,
            variant: PrimaryBtnVariant.teal,
            onPressed: _snap.sessionDone ? null : _start,
          ),
        ],
      ),
    );
  }
}
