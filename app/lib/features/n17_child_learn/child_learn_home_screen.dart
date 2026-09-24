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
import 'package:family_os/features/n17_child_learn/child_learn_home_models.dart';
import 'package:family_os/features/n17_child_learn/child_learn_home_repository.dart';

/// Widget keys for SCR-CHD-012 acceptance.
abstract final class ChildLearnHomeKeys {
  static const screen = Key('child_learn_home_screen');
  static const loading = Key('child_learn_home_loading');
  static const empty = Key('child_learn_home_empty');
  static const body = Key('child_learn_home_body');
  static const levelCard = Key('child_learn_home_level');
  static const challengeCard = Key('child_learn_home_challenge');
  static const challengeCta = Key('child_learn_home_challenge_cta');
  static const materialsCard = Key('child_learn_home_materials');
  static const quickActions = Key('child_learn_home_qact');
  static const parentLean = Key('child_learn_home_parent_lean');
  static const sosIconCta = Key('child_learn_home_sos_icon');

  static Key materialRow(String id) => Key('child_learn_home_mat_$id');

  static Key quickAction(String id) => Key('child_learn_home_qact_$id');
}

/// SCR-CHD-012 — تعلّمي — الرئيسة (child learn home).
///
/// Prototype CHD-012 · S-EDU-002/033/034 · RoleGuard child · minutes-only ·
/// mock-first · ARB · P-4 SOS · Rule 12/23 · challenge→015 · math→013.
class ChildLearnHomeScreen extends StatefulWidget {
  const ChildLearnHomeScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.onSos,
    this.onNavigate,
  });

  final ChildLearnHomeRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildLearnHomeScreen> createState() => _ChildLearnHomeScreenState();
}

class _ChildLearnHomeScreenState extends State<ChildLearnHomeScreen> {
  late ChildLearnHomeRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildLearnHomeSnapshot _snap = const ChildLearnHomeSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.child;
  }

  bool get _isChild => _role == AppRole.child;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1ChildLearnHomeRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildLearnHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1ChildLearnHomeRepository;
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

  String _levelTitle(AppLocalizations l10n, String? key) {
    return switch (key) {
      'explorer' => l10n.childLearnHomeLevelExplorer,
      _ => l10n.childLearnHomeLevelExplorer,
    };
  }

  String _challengeTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'fractionsQuiz' => l10n.childLearnHomeChallengeFractions,
      'assignedChallenge' => l10n.childLearnHomeChallengeAssigned,
      'assignedHomework' => l10n.childLearnHomeChallengeAssignedHomework,
      'assignedSkillGap' => l10n.childLearnHomeChallengeAssignedSkill,
      'assignedFamily' => l10n.childLearnHomeChallengeAssignedFamily,
      _ => l10n.childLearnHomeChallengeFractions,
    };
  }

  String _materialTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'math' => l10n.childLearnHomeSubjectMath,
      'quran' => l10n.childLearnHomeSubjectQuran,
      'english' => l10n.childLearnHomeSubjectEnglish,
      _ => l10n.childLearnHomeSubjectMath,
    };
  }

  String _materialSubtitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'mathNewLesson' => l10n.childLearnHomeMathNewLesson,
      'quranWird' => l10n.childLearnHomeQuranWird,
      'englishCardsLeft' => l10n.childLearnHomeEnglishCardsLeft,
      'assignedFromFather' => l10n.childLearnHomeAssignedFromFather,
      _ => l10n.childLearnHomeMathNewLesson,
    };
  }

  IconData _subjectIcon(ChildLearnSubjectKind kind) {
    return switch (kind) {
      ChildLearnSubjectKind.math => Icons.calculate_outlined,
      ChildLearnSubjectKind.quran => Icons.menu_book_outlined,
      ChildLearnSubjectKind.english => Icons.translate_outlined,
    };
  }

  void _onMaterialTap(ChildLearnMaterialRow row) {
    final target = row.ctaScreenId;
    if (target != null) {
      _go(target);
      return;
    }
    final l10n = AppLocalizations.of(context);
    AppToast.show(context, message: l10n.childLearnHomeMaterialSoonToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildLearnHomeKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.childLearnHomeTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.teal100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  l10n.childLearnHomeChildChip,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.teal600,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: ChildLearnHomeKeys.sosIconCta,
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
    if (!_isChild) {
      return AppEmptyState(
        key: ChildLearnHomeKeys.parentLean,
        title: l10n.childLearnHomeParentLeanTitle,
        message: l10n.childLearnHomeParentLeanMessage,
      );
    }

    if (_loading) {
      return Center(
        key: ChildLearnHomeKeys.loading,
        child: Semantics(
          label: l10n.childLearnHomeLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildLearnHomeKeys.empty,
        title: l10n.childLearnHomeEmptyTitle,
        message: l10n.childLearnHomeEmptyMessage,
        actionLabel: l10n.childLearnHomeEmptyCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final gradients = Theme.of(context).extension<FamilyGradients>()!;

    return SingleChildScrollView(
      key: ChildLearnHomeKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LevelHeroCard(
            colors: colors,
            radii: radii,
            gradients: gradients,
            l10n: l10n,
            levelLabel: l10n.childLearnHomeLevelLabel(
              _snap.level,
              _levelTitle(l10n, _snap.levelTitleKey),
            ),
            minutesLabel: l10n.childLearnHomeMinutesEarned(
              _snap.minutesEarnedThisMonth,
            ),
            progress: _snap.levelProgressPercent / 100.0,
            streakLabel: l10n.childLearnHomeStreakDays(_snap.streakDays),
            freeTime: _snap.freeTime,
          ),
          if (_snap.challenge != null) ...[
            const SizedBox(height: 12),
            _ChallengeCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              title: _challengeTitle(l10n, _snap.challenge!.titleKey),
              rewardMinutes: _snap.challenge!.rewardMinutes,
              onStart: () => _go(_snap.challenge!.ctaScreenId),
            ),
          ],
          const SizedBox(height: 12),
          _MaterialsCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            materials: _snap.materials,
            titleFor: _materialTitle,
            subtitleFor: _materialSubtitle,
            iconFor: _subjectIcon,
            onTap: _onMaterialTap,
          ),
          const SizedBox(height: 16),
          _QuickActionsRow(
            l10n: l10n,
            colors: colors,
            radii: radii,
            onTutor: () => _go('SCR-CHD-017'),
            onFocus: () => _go('SCR-CHD-018'),
            onHomework: () => _go('SCR-CHD-014'),
          ),
        ],
      ),
    );
  }
}

class _LevelHeroCard extends StatelessWidget {
  const _LevelHeroCard({
    required this.colors,
    required this.radii,
    required this.gradients,
    required this.l10n,
    required this.levelLabel,
    required this.minutesLabel,
    required this.progress,
    required this.streakLabel,
    required this.freeTime,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final FamilyGradients gradients;
  final AppLocalizations l10n;
  final String levelLabel;
  final String minutesLabel;
  final double progress;
  final String streakLabel;
  final bool freeTime;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildLearnHomeKeys.levelCard,
      decoration: BoxDecoration(
        gradient: gradients.gradTeal,
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    levelLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  minutesLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(radii.pill),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      alignment: AlignmentDirectional.centerStart,
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(label: streakLabel),
                if (freeTime) _HeroChip(label: l10n.childLearnHomeFreeTimeChip),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.title,
    required this.rewardMinutes,
    required this.onStart,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final String title;
  final int rewardMinutes;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildLearnHomeKeys.challengeCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.teal, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.childLearnHomeChallengeHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.childLearnHomeChallengeBody(title, rewardMinutes),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.ink,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryBtn(
              key: ChildLearnHomeKeys.challengeCta,
              label: l10n.childLearnHomeChallengeCta,
              variant: PrimaryBtnVariant.teal,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialsCard extends StatelessWidget {
  const _MaterialsCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.materials,
    required this.titleFor,
    required this.subtitleFor,
    required this.iconFor,
    required this.onTap,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<ChildLearnMaterialRow> materials;
  final String Function(AppLocalizations, String) titleFor;
  final String Function(AppLocalizations, String) subtitleFor;
  final IconData Function(ChildLearnSubjectKind) iconFor;
  final void Function(ChildLearnMaterialRow) onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildLearnHomeKeys.materialsCard,
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
              l10n.childLearnHomeMaterialsHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            for (final row in materials)
              InkWell(
                key: ChildLearnHomeKeys.materialRow(row.id),
                onTap: () => onTap(row),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(iconFor(row.kind), size: 22, color: colors.ink2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleFor(l10n, row.titleKey),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            Text(
                              subtitleFor(l10n, row.subtitleKey),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MaterialTrailing(row: row, l10n: l10n, colors: colors),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTrailing extends StatelessWidget {
  const _MaterialTrailing({
    required this.row,
    required this.l10n,
    required this.colors,
  });

  final ChildLearnMaterialRow row;
  final AppLocalizations l10n;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return switch (row.tag) {
      ChildLearnMaterialTag.neu => Tag(
        label: l10n.childLearnHomeTagNew,
        variant: TagVariant.t,
      ),
      ChildLearnMaterialTag.progress => Tag(
        label: l10n.childLearnHomeTagProgress(row.progressPercent ?? 0),
        variant: TagVariant.g,
      ),
      ChildLearnMaterialTag.chevron => Icon(
        Icons.chevron_left,
        color: colors.ink2,
      ),
    };
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.l10n,
    required this.colors,
    required this.radii,
    required this.onTutor,
    required this.onFocus,
    required this.onHomework,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final FamilyRadii radii;
  final VoidCallback onTutor;
  final VoidCallback onFocus;
  final VoidCallback onHomework;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ChildLearnHomeKeys.quickActions,
      children: [
        Expanded(
          child: _QuickAction(
            actionKey: ChildLearnHomeKeys.quickAction('tutor'),
            colors: colors,
            radii: radii,
            icon: Icons.smart_toy_outlined,
            label: l10n.childLearnHomeQuickTutor,
            onTap: onTutor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            actionKey: ChildLearnHomeKeys.quickAction('focus'),
            colors: colors,
            radii: radii,
            icon: Icons.center_focus_strong_outlined,
            label: l10n.childLearnHomeQuickFocus,
            onTap: onFocus,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            actionKey: ChildLearnHomeKeys.quickAction('homework'),
            colors: colors,
            radii: radii,
            icon: Icons.assignment_outlined,
            label: l10n.childLearnHomeQuickHomework,
            onTap: onHomework,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.actionKey,
    required this.colors,
    required this.radii,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key actionKey;
  final FamilyColors colors;
  final FamilyRadii radii;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radii.card),
      child: InkWell(
        key: actionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(radii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radii.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: colors.teal600, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
