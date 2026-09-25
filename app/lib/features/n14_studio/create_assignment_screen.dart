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
import 'package:family_os/features/n14_studio/create_assignment_models.dart';
import 'package:family_os/features/n14_studio/create_assignment_repository.dart';
import 'package:family_os/features/n14_studio/studio_ux_bridge.dart';

/// Widget keys for SCR-FAT-049 acceptance.
abstract final class CreateAssignmentKeys {
  static const screen = Key('create_assignment_screen');
  static const loading = Key('create_assignment_loading');
  static const empty = Key('create_assignment_empty');
  static const body = Key('create_assignment_body');
  static const introBanner = Key('create_assignment_intro');
  static const homeworkCard = Key('create_assignment_homework');
  static const homeworkField = Key('create_assignment_hw_field');
  static const homeworkCta = Key('create_assignment_hw_cta');
  static const skillCard = Key('create_assignment_skill');
  static const skillCta = Key('create_assignment_skill_cta');
  static const skillEmpty = Key('create_assignment_skill_empty');
  static const familyCard = Key('create_assignment_family');
  static const familyField = Key('create_assignment_family_field');
  static const familyCta = Key('create_assignment_family_cta');
  static const resultsCta = Key('create_assignment_results');
  static const observerHint = Key('create_assignment_observer');
  static const childLean = Key('create_assignment_child_lean');
  static const sosCta = Key('create_assignment_sos');
  static const sosIconCta = Key('create_assignment_sos_icon');
}

/// SCR-FAT-049 — إنشاء واجب واختبار (create assignment / quiz).
///
/// Prototype FAT-049 · education wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · minutes-only (ع-١) · CTA → FAT-050 results.
class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1CreateAssignmentRepository].
  final CreateAssignmentRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may assign.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  late CreateAssignmentRepository _repo;
  late final SosFireService _sos;
  late final TextEditingController _homeworkCtrl;
  late final TextEditingController _familyCtrl;
  var _sosBusy = false;
  var _loading = true;
  var _assignBusy = false;
  CreateAssignmentSnapshot _snap = const CreateAssignmentSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may assign (prototype §7).
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
    _repo = widget.repository ?? Stage1StudioRuntime.createAssignment;
    _sos = widget.sosFire ?? stage1SosFireService;
    _homeworkCtrl = TextEditingController();
    _familyCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _homeworkCtrl.dispose();
    _familyCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CreateAssignmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1StudioRuntime.createAssignment;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await _repo.load();
    if (!mounted) return;
    _homeworkCtrl.text = snap.homeworkTitle;
    _familyCtrl.text = snap.familyQuestion;
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
    AppToast.show(context, message: l10n.createAssignmentObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    final key = _snap.child?.nameKey;
    return switch (key) {
      'one' => l10n.createAssignmentChildOne,
      'two' => l10n.createAssignmentChildTwo,
      'three' => l10n.createAssignmentChildThree,
      _ => l10n.createAssignmentChildOne,
    };
  }

  String _skillTitle(AppLocalizations l10n, CreateAssignmentSkillGap gap) {
    return switch (gap.titleKey) {
      'fractionDivision' => l10n.createAssignmentSkillFractionDivision,
      _ => l10n.createAssignmentSkillFractionDivision,
    };
  }

  Future<void> _onAssignHomework() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_assignBusy) return;
    final title = _homeworkCtrl.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, message: l10n.createAssignmentHomeworkEmptyToast);
      return;
    }
    setState(() => _assignBusy = true);
    final snap = await _repo.assignHomework(title);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _assignBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.createAssignmentHomeworkAssignedToast(_childName(l10n)),
    );
    _go('SCR-FAT-050');
  }

  Future<void> _onAssignSkill() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_assignBusy || _snap.skillGap == null) return;
    setState(() => _assignBusy = true);
    final snap = await _repo.assignSkillGap();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _assignBusy = false;
    });
    final minutes = snap.skillGap?.rewardMinutes ?? 50;
    AppToast.show(
      context,
      message: l10n.createAssignmentSkillAssignedToast(
        _childName(l10n),
        minutes,
      ),
    );
    _go('SCR-FAT-050');
  }

  Future<void> _onAssignFamily() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_assignBusy) return;
    final question = _familyCtrl.text.trim();
    if (question.isEmpty) {
      AppToast.show(context, message: l10n.createAssignmentFamilyEmptyToast);
      return;
    }
    setState(() => _assignBusy = true);
    final snap = await _repo.assignFamilyChallenge(question);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _assignBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.createAssignmentFamilyAssignedToast(_childName(l10n)),
    );
    _go('SCR-FAT-050');
  }

  void _onResultsFollowUp() {
    _go('SCR-FAT-050');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: CreateAssignmentKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.createAssignmentTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: CreateAssignmentKeys.sosIconCta,
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
        key: CreateAssignmentKeys.childLean,
        title: l10n.createAssignmentChildLeanTitle,
        message: l10n.createAssignmentChildLeanMessage,
        actionLabel: l10n.createAssignmentSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: CreateAssignmentKeys.loading,
        child: Semantics(
          label: l10n.createAssignmentLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: CreateAssignmentKeys.empty,
        title: l10n.createAssignmentEmptyTitle,
        message: l10n.createAssignmentEmptyMessage,
        actionLabel: l10n.createAssignmentEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final childName = _childName(l10n);

    return SingleChildScrollView(
      key: CreateAssignmentKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: CreateAssignmentKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.createAssignmentObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.createAssignmentHeading(childName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: CreateAssignmentKeys.introBanner,
            variant: BannerVariant.t,
            message: l10n.createAssignmentIntroBanner(childName),
          ),
          const SizedBox(height: 12),
          _HomeworkCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            controller: _homeworkCtrl,
            rewardMinutes: _snap.homeworkRewardMinutes,
            onAssign: _assignBusy ? null : _onAssignHomework,
          ),
          const SizedBox(height: 10),
          _SkillGapCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            skillGap: _snap.skillGap,
            skillTitle: _snap.skillGap != null
                ? _skillTitle(l10n, _snap.skillGap!)
                : null,
            childName: childName,
            onAssign: _assignBusy ? null : _onAssignSkill,
          ),
          const SizedBox(height: 10),
          _FamilyChallengeCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            controller: _familyCtrl,
            rewardMinutes: _snap.familyRewardMinutes,
            onAssign: _assignBusy ? null : _onAssignFamily,
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: CreateAssignmentKeys.resultsCta,
            label: l10n.createAssignmentResultsCta,
            variant: PrimaryBtnVariant.sec,
            onPressed: _onResultsFollowUp,
          ),
        ],
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.controller,
    required this.rewardMinutes,
    required this.onAssign,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final TextEditingController controller;
  final int rewardMinutes;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: CreateAssignmentKeys.homeworkCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📘', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createAssignmentHomeworkTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.createAssignmentHomeworkSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: CreateAssignmentKeys.homeworkField,
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
              decoration: InputDecoration(
                hintText: l10n.createAssignmentHomeworkHint,
                filled: true,
                fillColor: colors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.createAssignmentHomeworkReward(rewardMinutes),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.createAssignmentHomeworkProofTag,
                  variant: TagVariant.g,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: CreateAssignmentKeys.homeworkCta,
              label: l10n.createAssignmentHomeworkCta,
              variant: PrimaryBtnVariant.mint,
              onPressed: onAssign,
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
    required this.skillGap,
    required this.skillTitle,
    required this.childName,
    required this.onAssign,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final CreateAssignmentSkillGap? skillGap;
  final String? skillTitle;
  final String childName;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final hasGap = skillGap != null;
    return DecoratedBox(
      key: CreateAssignmentKeys.skillCard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.p50, colors.p100],
        ),
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.p500, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createAssignmentSkillTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.p700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.createAssignmentSkillSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasGap)
                  Tag(
                    label: l10n.createAssignmentSkillRecommendedTag,
                    variant: TagVariant.a,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasGap)
              DecoratedBox(
                key: CreateAssignmentKeys.skillEmpty,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.createAssignmentSkillEmptyMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
              )
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createAssignmentSkillGapLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.createAssignmentSkillGapLine(
                          skillTitle!,
                          l10n.createAssignmentSkillMissed(
                            skillGap!.missed,
                            skillGap!.total,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.p700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.createAssignmentSkillQuizReady(
                          skillGap!.quizQuestions,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.mintInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryBtn(
                key: CreateAssignmentKeys.skillCta,
                label: l10n.createAssignmentSkillCta(
                  childName,
                  skillGap!.rewardMinutes,
                ),
                onPressed: onAssign,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FamilyChallengeCard extends StatelessWidget {
  const _FamilyChallengeCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.controller,
    required this.rewardMinutes,
    required this.onAssign,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final TextEditingController controller;
  final int rewardMinutes;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: CreateAssignmentKeys.familyCard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.amber100.withValues(alpha: 0.45), colors.amber100],
        ),
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.amber, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👑', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.createAssignmentFamilyTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.amberInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.createAssignmentFamilySubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: CreateAssignmentKeys.familyField,
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
              decoration: InputDecoration(
                hintText: l10n.createAssignmentFamilyHint,
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.createAssignmentFamilyReward(rewardMinutes),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.createAssignmentFamilyGoldTag,
                  variant: TagVariant.p,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryBtn(
              key: CreateAssignmentKeys.familyCta,
              label: l10n.createAssignmentFamilyCta,
              variant: PrimaryBtnVariant.teal,
              onPressed: onAssign,
            ),
          ],
        ),
      ),
    );
  }
}
