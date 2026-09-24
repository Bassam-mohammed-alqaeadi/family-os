import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n14_studio/results_followup_models.dart';
import 'package:family_os/features/n14_studio/results_followup_repository.dart';

/// Widget keys for SCR-FAT-050 acceptance.
abstract final class ResultsFollowupKeys {
  static const screen = Key('results_followup_screen');
  static const loading = Key('results_followup_loading');
  static const empty = Key('results_followup_empty');
  static const body = Key('results_followup_body');
  static const masteryCard = Key('results_followup_mastery');
  static const masteryHero = Key('results_followup_mastery_hero');
  static const masteryProgress = Key('results_followup_mastery_progress');
  static const gapCard = Key('results_followup_gap');
  static const gapCta = Key('results_followup_gap_cta');
  static const gapMastered = Key('results_followup_gap_mastered');
  static const activityLog = Key('results_followup_activity_log');
  static const focusCta = Key('results_followup_focus_cta');
  static const observerHint = Key('results_followup_observer');
  static const childLean = Key('results_followup_child_lean');
  static const sosCta = Key('results_followup_sos');
  static const sosIconCta = Key('results_followup_sos_icon');

  static Key gapRow(String id) => Key('results_followup_gap_$id');
  static Key activityRow(String id) => Key('results_followup_act_$id');
}

/// SCR-FAT-050 — متابعة النتائج (results follow-up).
///
/// Prototype FAT-050 · education wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · minutes-only (ع-١) · gap CTA → FAT-049.
class ResultsFollowupScreen extends StatefulWidget {
  const ResultsFollowupScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1ResultsFollowupRepository].
  final ResultsFollowupRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may remediate gaps.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<ResultsFollowupScreen> createState() => _ResultsFollowupScreenState();
}

class _ResultsFollowupScreenState extends State<ResultsFollowupScreen> {
  late ResultsFollowupRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ResultsFollowupSnapshot _snap = const ResultsFollowupSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may tap gap remediation CTA.
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ResultsFollowupRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ResultsFollowupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1ResultsFollowupRepository;
      _load();
    }
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String screenId) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.resultsFollowupObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    final key = _snap.child?.nameKey;
    return switch (key) {
      'one' => l10n.resultsFollowupChildOne,
      'two' => l10n.resultsFollowupChildTwo,
      'three' => l10n.resultsFollowupChildThree,
      _ => l10n.resultsFollowupChildOne,
    };
  }

  String _masterySubject(AppLocalizations l10n, String subjectKey) {
    return switch (subjectKey) {
      'math' => l10n.resultsFollowupMasterySubjectMath,
      _ => l10n.resultsFollowupMasterySubjectMath,
    };
  }

  String _skillTitle(AppLocalizations l10n, ResultsFollowupSkillGap gap) {
    return switch (gap.titleKey) {
      'fractionDivision' => l10n.resultsFollowupSkillFractionDivision,
      _ => l10n.resultsFollowupSkillFractionDivision,
    };
  }

  String _activityTitle(AppLocalizations l10n, ResultsFollowupActivity act) {
    return switch (act.titleKey) {
      'schoolFractions' => l10n.resultsFollowupActivitySchoolFractionsTitle,
      'dailyChallenge' => l10n.resultsFollowupActivityDailyChallengeTitle,
      'quizSubmitted' => l10n.resultsFollowupActivityQuizSubmittedTitle,
      _ => l10n.resultsFollowupActivitySchoolFractionsTitle,
    };
  }

  String _activitySubtitle(AppLocalizations l10n, ResultsFollowupActivity act) {
    return switch (act.subtitleKey) {
      'onTimePhoto' => l10n.resultsFollowupActivityOnTimePhoto,
      'earnedMinutes' => l10n.resultsFollowupActivityEarnedMinutes(
        act.minutes ?? 0,
      ),
      'justSubmitted' => l10n.resultsFollowupActivityJustSubmitted,
      _ => l10n.resultsFollowupActivityOnTimePhoto,
    };
  }

  String _activityStatus(AppLocalizations l10n, ResultsFollowupActivity act) {
    return switch (act.statusKey) {
      'complete' => l10n.resultsFollowupActivityStatusComplete,
      'approved' => l10n.resultsFollowupActivityStatusApproved,
      _ => l10n.resultsFollowupActivityStatusComplete,
    };
  }

  void _onRemediateGap() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-049');
  }

  void _onFocusReport() {
    _go('SCR-FAT-051');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ResultsFollowupKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.resultsFollowupTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ResultsFollowupKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: ResultsFollowupKeys.childLean,
        title: l10n.resultsFollowupChildLeanTitle,
        message: l10n.resultsFollowupChildLeanMessage,
        actionLabel: l10n.resultsFollowupSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: ResultsFollowupKeys.loading,
        child: Semantics(
          label: l10n.resultsFollowupLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ResultsFollowupKeys.empty,
        title: l10n.resultsFollowupEmptyTitle,
        message: l10n.resultsFollowupEmptyMessage,
        actionLabel: l10n.resultsFollowupEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final childName = _childName(l10n);

    return SingleChildScrollView(
      key: ResultsFollowupKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: ResultsFollowupKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.resultsFollowupObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.resultsFollowupHeading(childName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (_snap.mastery != null)
            _MasteryCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              mastery: _snap.mastery!,
              subjectLabel: _masterySubject(l10n, _snap.mastery!.subjectKey),
            ),
          if (_snap.skillGap != null) ...[
            const SizedBox(height: 10),
            _SkillGapCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              gap: _snap.skillGap!,
              skillTitle: _skillTitle(l10n, _snap.skillGap!),
              onRemediate: _onRemediateGap,
            ),
          ],
          if (_snap.activities.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ActivityLogCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              activities: _snap.activities,
              titleFor: (act) => _activityTitle(l10n, act),
              subtitleFor: (act) => _activitySubtitle(l10n, act),
              statusFor: (act) => _activityStatus(l10n, act),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryBtn(
            key: ResultsFollowupKeys.focusCta,
            label: l10n.resultsFollowupFocusCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _onFocusReport,
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.mastery,
    required this.subjectLabel,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final ResultsFollowupMastery mastery;
  final String subjectLabel;

  @override
  Widget build(BuildContext context) {
    final improved = mastery.hasImprovement;
    final tagLabel = improved
        ? l10n.resultsFollowupMasteryImprovedTag(mastery.percent)
        : l10n.resultsFollowupMasteryAverageTag(mastery.percent);

    return DecoratedBox(
      key: ResultsFollowupKeys.masteryCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.resultsFollowupMasteryCaption(subjectLabel),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(label: tagLabel, variant: TagVariant.g),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.resultsFollowupMasteryHero(mastery.percent),
              key: ResultsFollowupKeys.masteryHero,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colors.p600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            ProgressBar(
              key: ResultsFollowupKeys.masteryProgress,
              value: mastery.percent / 100.0,
              variant: ProgressBarVariant.mint,
              height: 7,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillGapCard extends StatelessWidget {
  const _SkillGapCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.gap,
    required this.skillTitle,
    required this.onRemediate,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final ResultsFollowupSkillGap gap;
  final String skillTitle;
  final VoidCallback onRemediate;

  @override
  Widget build(BuildContext context) {
    final mastered = gap.isMastered;
    return DecoratedBox(
      key: ResultsFollowupKeys.gapCard,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.resultsFollowupGapSectionTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: mastered
                      ? l10n.resultsFollowupGapMasteredTag
                      : l10n.resultsFollowupGapNeedsFixTag,
                  variant: mastered ? TagVariant.g : TagVariant.a,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _GapRow(
              rowKey: ResultsFollowupKeys.gapRow(gap.id),
              colors: colors,
              emoji: '➗',
              title: skillTitle,
              detail: mastered
                  ? l10n.resultsFollowupGapMasteredDetail(
                      gap.masteryPercent ?? 90,
                    )
                  : l10n.resultsFollowupGapPendingDetail(gap.missed, gap.total),
              detailColor: mastered ? colors.mintInk : colors.amberInk,
              trailing: mastered
                  ? Tag(
                      key: ResultsFollowupKeys.gapMastered,
                      label: l10n.resultsFollowupGapMasteredLabel,
                      variant: TagVariant.g,
                    )
                  : PrimaryBtn(
                      key: ResultsFollowupKeys.gapCta,
                      label: l10n.resultsFollowupGapCta,
                      variant: PrimaryBtnVariant.mint,
                      fullWidth: false,
                      onPressed: onRemediate,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.rowKey,
    required this.colors,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.detailColor,
    required this.trailing,
  });

  final Key rowKey;
  final FamilyColors colors;
  final String emoji;
  final String title;
  final String detail;
  final Color detailColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
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
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: detailColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.activities,
    required this.titleFor,
    required this.subtitleFor,
    required this.statusFor,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<ResultsFollowupActivity> activities;
  final String Function(ResultsFollowupActivity act) titleFor;
  final String Function(ResultsFollowupActivity act) subtitleFor;
  final String Function(ResultsFollowupActivity act) statusFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ResultsFollowupKeys.activityLog,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resultsFollowupActivitySectionTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final act in activities)
              _ActivityRow(
                rowKey: ResultsFollowupKeys.activityRow(act.id),
                colors: colors,
                title: titleFor(act),
                subtitle: subtitleFor(act),
                status: statusFor(act),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.rowKey,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final Key rowKey;
  final FamilyColors colors;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tag(label: status, variant: TagVariant.g),
        ],
      ),
    );
  }
}
