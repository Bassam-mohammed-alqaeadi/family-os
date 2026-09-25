import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n17_child_learn/child_result_models.dart';
import 'package:family_os/features/n17_child_learn/child_result_repository.dart';
import 'package:family_os/features/n17_child_learn/learn_ux_bridge.dart';

/// Widget keys for SCR-CHD-016 acceptance.
abstract final class ChildResultKeys {
  static const screen = Key('child_result_screen');
  static const loading = Key('child_result_loading');
  static const empty = Key('child_result_empty');
  static const body = Key('child_result_body');
  static const score = Key('child_result_score');
  static const rewardsCard = Key('child_result_rewards');
  static const missedCard = Key('child_result_missed');
  static const reviewCta = Key('child_result_review');
  static const homeCta = Key('child_result_home');
  static const parentLean = Key('child_result_parent_lean');
  static const sosIconCta = Key('child_result_sos_icon');

  static Key rewardRow(String id) => Key('child_result_reward_$id');
}

/// SCR-CHD-016 — نتيجتي (child quiz result — encourage, never punish).
///
/// Prototype CHD-016 · RoleGuard child · minutes-only rewards · review→013 ·
/// home→012 · P-4 SOS · Rule 12/23.
class ChildResultScreen extends StatefulWidget {
  const ChildResultScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildResultRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildResultScreen> createState() => _ChildResultScreenState();
}

class _ChildResultScreenState extends State<ChildResultScreen> {
  late ChildResultRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildResultSnapshot _snap = const ChildResultSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1LearnRuntime.result;
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

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  String _praise(AppLocalizations l10n) {
    return switch (_snap.praiseKey) {
      'masteredAdd' => l10n.childResultPraiseMasteredAdd,
      _ => l10n.childResultPraiseMasteredAdd,
    };
  }

  String _rewardTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'wallet20' => l10n.childResultRewardWallet20,
      'play15' => l10n.childResultRewardPlay15,
      'bonus30' => l10n.childResultRewardBonus30,
      _ => l10n.childResultRewardWallet20,
    };
  }

  String? _rewardSub(AppLocalizations l10n, String? key) {
    return switch (key) {
      'nearLevel4' => l10n.childResultRewardNearLevel4,
      _ => null,
    };
  }

  String _rewardTag(AppLocalizations l10n, String key) {
    return switch (key) {
      'arrived' => l10n.childResultTagArrived,
      'added' => l10n.childResultTagAdded,
      'progress370' => l10n.childResultTagProgress370,
      _ => l10n.childResultTagArrived,
    };
  }

  TagVariant _tagVariant(String key) {
    return switch (key) {
      'progress370' => TagVariant.t,
      _ => TagVariant.g,
    };
  }

  String _missedTitle(AppLocalizations l10n) {
    return switch (_snap.missedTitleKey) {
      'missedQ7' => l10n.childResultMissedQ7,
      _ => l10n.childResultMissedQ7,
    };
  }

  String _missedBody(AppLocalizations l10n) {
    return switch (_snap.missedBodyKey) {
      'missedDivisionOk' => l10n.childResultMissedDivisionOk,
      _ => l10n.childResultMissedDivisionOk,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildResultKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childResultTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildResultKeys.sosIconCta,
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
        key: ChildResultKeys.parentLean,
        title: l10n.childResultParentLeanTitle,
        message: l10n.childResultParentLeanMessage,
      );
    }
    if (_loading) {
      return Center(
        key: ChildResultKeys.loading,
        child: Semantics(
          label: l10n.childResultLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildResultKeys.empty,
        title: l10n.childResultEmptyTitle,
        message: l10n.childResultEmptyMessage,
        actionLabel: l10n.childResultEmptyCta,
        onAction: () => _go('SCR-CHD-012'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: ChildResultKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🏆',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            key: ChildResultKeys.score,
            l10n.childResultScore(_snap.scoreCorrect!, _snap.scoreTotal!),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: colors.teal600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _praise(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            key: ChildResultKeys.rewardsCard,
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
                    l10n.childResultRewardsHeading,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final row in _snap.rewards)
                    Padding(
                      key: ChildResultKeys.rewardRow(row.id),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: colors.ink2,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rewardTitle(l10n, row.titleKey),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.ink,
                                  ),
                                ),
                                if (_rewardSub(l10n, row.subtitleKey)
                                    case final sub?)
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
                          Tag(
                            label: _rewardTag(l10n, row.tagKey),
                            variant: _tagVariant(row.tagKey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_snap.missedTitleKey != null) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              key: ChildResultKeys.missedCard,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(radii.card),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.childResultMissedHeading,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _missedTitle(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _missedBody(l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryBtn(
                      key: ChildResultKeys.reviewCta,
                      label: l10n.childResultReviewCta,
                      variant: PrimaryBtnVariant.teal,
                      onPressed: () => _go(_snap.reviewScreenId),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ChildResultKeys.homeCta,
            label: l10n.childResultHomeCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: () => _go(_snap.learnHomeScreenId),
          ),
        ],
      ),
    );
  }
}
