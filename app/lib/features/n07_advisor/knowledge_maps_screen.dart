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
import 'package:family_os/features/n07_advisor/knowledge_maps_models.dart';
import 'package:family_os/features/n07_advisor/knowledge_maps_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

/// Widget keys for SCR-FAT-064 acceptance.
abstract final class KnowledgeMapsKeys {
  static const screen = Key('knowledge_maps_screen');
  static const loading = Key('knowledge_maps_loading');
  static const empty = Key('knowledge_maps_empty');
  static const body = Key('knowledge_maps_body');
  static const learningCard = Key('knowledge_maps_learning');
  static const socialCard = Key('knowledge_maps_social');
  static const socialBar = Key('knowledge_maps_social_bar');
  static const dinnerCard = Key('knowledge_maps_dinner');
  static const dinnerNextCta = Key('knowledge_maps_dinner_next');
  static const dinnerSendCta = Key('knowledge_maps_dinner_send');
  static const observerHint = Key('knowledge_maps_observer');
  static const childLean = Key('knowledge_maps_child_lean');
  static const sosIconCta = Key('knowledge_maps_sos_icon');

  static Key pathRow(String id) => Key('knowledge_maps_path_$id');

  static Key pathCta(String id) => Key('knowledge_maps_path_cta_$id');

  static Key socialRow(String segment) => Key('knowledge_maps_social_$segment');
}

/// SCR-FAT-064 — خرائط المعرفة (knowledge / growth maps).
///
/// Prototype FAT-064 · S-AIC-014/015 · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · empty → FAT-003 · paths → FAT-072/049.
class KnowledgeMapsScreen extends StatefulWidget {
  const KnowledgeMapsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1KnowledgeMapsRepository].
  final KnowledgeMapsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may act.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<KnowledgeMapsScreen> createState() => _KnowledgeMapsScreenState();
}

class _KnowledgeMapsScreenState extends State<KnowledgeMapsScreen> {
  late KnowledgeMapsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _actionBusy = false;
  KnowledgeMapsSnapshot _snap = const KnowledgeMapsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

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
    _repo = widget.repository ?? Stage1ReportsRuntime.knowledgeMaps;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant KnowledgeMapsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1ReportsRuntime.knowledgeMaps;
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
    AppToast.show(context, message: l10n.knowledgeMapsObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    return switch (_snap.childNameKey) {
      'childOne' => l10n.knowledgeMapsChildOne,
      'childTwo' => l10n.knowledgeMapsChildTwo,
      'childThree' => l10n.knowledgeMapsChildThree,
      _ => l10n.knowledgeMapsChildOne,
    };
  }

  String _pathTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'quranSurah' => l10n.knowledgeMapsPathQuranTitle,
      'mathFractions' => l10n.knowledgeMapsPathMathTitle,
      _ => l10n.knowledgeMapsPathMathTitle,
    };
  }

  String _pathSubtitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'quranProgressStreak' => l10n.knowledgeMapsPathQuranSubtitle,
      'mathFractionsHint' => l10n.knowledgeMapsPathMathSubtitle,
      _ => l10n.knowledgeMapsPathMathSubtitle,
    };
  }

  String _pathCta(AppLocalizations l10n, KnowledgeMapPathKind kind) {
    return switch (kind) {
      KnowledgeMapPathKind.quran => l10n.knowledgeMapsPathQuranCta,
      KnowledgeMapPathKind.math => l10n.knowledgeMapsPathMathCta,
    };
  }

  IconData _pathIcon(KnowledgeMapPathKind kind) {
    return switch (kind) {
      KnowledgeMapPathKind.quran => Icons.menu_book_outlined,
      KnowledgeMapPathKind.math => Icons.calculate_outlined,
    };
  }

  ProgressBarVariant _pathProgressVariant(KnowledgeMapPathKind kind) {
    return switch (kind) {
      KnowledgeMapPathKind.quran => ProgressBarVariant.mint,
      KnowledgeMapPathKind.math => ProgressBarVariant.pu,
    };
  }

  String _socialTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'familyDirect' => l10n.knowledgeMapsSocialFamilyTitle,
      'approvedFriends' => l10n.knowledgeMapsSocialFriendsTitle,
      'newInteraction' => l10n.knowledgeMapsSocialNewTitle,
      _ => l10n.knowledgeMapsSocialFamilyTitle,
    };
  }

  String? _socialSubtitle(AppLocalizations l10n, String? key) {
    return switch (key) {
      'familyWarmDaily' => l10n.knowledgeMapsSocialFamilySubtitle,
      _ => null,
    };
  }

  Color _socialColor(FamilyColors colors, KnowledgeMapSocialSegment segment) {
    return switch (segment) {
      KnowledgeMapSocialSegment.family => colors.p500,
      KnowledgeMapSocialSegment.approvedFriends => colors.teal,
      KnowledgeMapSocialSegment.newInteraction => colors.amber,
    };
  }

  String _dinnerQuestion(AppLocalizations l10n, String? key) {
    return switch (key) {
      'dinnerQ1' => l10n.knowledgeMapsDinnerQ1,
      'dinnerQ2' => l10n.knowledgeMapsDinnerQ2,
      'dinnerQ3' => l10n.knowledgeMapsDinnerQ3,
      _ => l10n.knowledgeMapsDinnerQ1,
    };
  }

  Future<void> _onPathCta(KnowledgeMapLearningPath path) async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go(path.ctaScreenId);
  }

  Future<void> _onNextDinner() async {
    if (_actionBusy) return;
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    setState(() => _actionBusy = true);
    final snap = await _repo.nextDinnerQuestion();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _actionBusy = false;
    });
  }

  void _onSendDinner() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.knowledgeMapsDinnerSendToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final childName = _childName(l10n);

    return Scaffold(
      key: KnowledgeMapsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.knowledgeMapsTitle(childName),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: KnowledgeMapsKeys.sosIconCta,
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
        key: KnowledgeMapsKeys.childLean,
        title: l10n.knowledgeMapsChildLeanTitle,
        message: l10n.knowledgeMapsChildLeanMessage,
        actionLabel: l10n.knowledgeMapsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: KnowledgeMapsKeys.loading,
        child: Semantics(
          label: l10n.knowledgeMapsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: KnowledgeMapsKeys.empty,
        title: l10n.knowledgeMapsEmptyTitle,
        message: l10n.knowledgeMapsEmptyMessage,
        actionLabel: l10n.knowledgeMapsEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: KnowledgeMapsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: KnowledgeMapsKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.knowledgeMapsObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          _LearningPathsCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            masteryPercent: _snap.masteryPercent,
            paths: _snap.learningPaths,
            pathTitle: _pathTitle,
            pathSubtitle: _pathSubtitle,
            pathCta: _pathCta,
            pathIcon: _pathIcon,
            pathVariant: _pathProgressVariant,
            onPathCta: _onPathCta,
          ),
          const SizedBox(height: 12),
          _SocialNetworkCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            shares: _snap.socialShares,
            titleFor: _socialTitle,
            subtitleFor: _socialSubtitle,
            colorFor: _socialColor,
          ),
          const SizedBox(height: 12),
          _DinnerQuestionCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            question: _dinnerQuestion(l10n, _snap.currentDinnerQuestionKey),
            busy: _actionBusy,
            onNext: _onNextDinner,
            onSend: _onSendDinner,
          ),
        ],
      ),
    );
  }
}

class _LearningPathsCard extends StatelessWidget {
  const _LearningPathsCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.masteryPercent,
    required this.paths,
    required this.pathTitle,
    required this.pathSubtitle,
    required this.pathCta,
    required this.pathIcon,
    required this.pathVariant,
    required this.onPathCta,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final int masteryPercent;
  final List<KnowledgeMapLearningPath> paths;
  final String Function(AppLocalizations, String) pathTitle;
  final String Function(AppLocalizations, String) pathSubtitle;
  final String Function(AppLocalizations, KnowledgeMapPathKind) pathCta;
  final IconData Function(KnowledgeMapPathKind) pathIcon;
  final ProgressBarVariant Function(KnowledgeMapPathKind) pathVariant;
  final Future<void> Function(KnowledgeMapLearningPath) onPathCta;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: KnowledgeMapsKeys.learningCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, size: 20, color: colors.ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.knowledgeMapsLearningHeading,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.knowledgeMapsMasteryTag(masteryPercent),
                  variant: TagVariant.g,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < paths.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: colors.border),
              _PathRow(
                path: paths[i],
                colors: colors,
                title: pathTitle(l10n, paths[i].titleKey),
                subtitle: pathSubtitle(l10n, paths[i].subtitleKey),
                ctaLabel: pathCta(l10n, paths[i].kind),
                icon: pathIcon(paths[i].kind),
                variant: pathVariant(paths[i].kind),
                onCta: () => onPathCta(paths[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.path,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.icon,
    required this.variant,
    required this.onCta,
  });

  final KnowledgeMapLearningPath path;
  final FamilyColors colors;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;
  final ProgressBarVariant variant;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: KnowledgeMapsKeys.pathRow(path.id),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: colors.ink2),
              const SizedBox(width: 8),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: PrimaryBtn(
                  key: KnowledgeMapsKeys.pathCta(path.id),
                  label: ctaLabel,
                  variant: PrimaryBtnVariant.sec,
                  fullWidth: true,
                  onPressed: onCta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            value: path.progressPercent / 100.0,
            variant: variant,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _SocialNetworkCard extends StatelessWidget {
  const _SocialNetworkCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.shares,
    required this.titleFor,
    required this.subtitleFor,
    required this.colorFor,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<KnowledgeMapSocialShare> shares;
  final String Function(AppLocalizations, String) titleFor;
  final String? Function(AppLocalizations, String?) subtitleFor;
  final Color Function(FamilyColors, KnowledgeMapSocialSegment) colorFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: KnowledgeMapsKeys.socialCard,
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
              children: [
                Icon(Icons.groups_outlined, size: 20, color: colors.ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.knowledgeMapsSocialHeading,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  label: l10n.knowledgeMapsSocialSafeTag,
                  variant: TagVariant.t,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              key: KnowledgeMapsKeys.socialBar,
              borderRadius: BorderRadius.circular(radii.pill),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (var i = 0; i < shares.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: shares[i].percent.clamp(1, 100),
                        child: ColoredBox(
                          color: colorFor(colors, shares[i].segment),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final share in shares)
              if (share.segment == KnowledgeMapSocialSegment.family)
                Padding(
                  key: KnowledgeMapsKeys.socialRow(share.segment.name),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.family_restroom, size: 22, color: colors.ink2),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleFor(l10n, share.titleKey),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            if (subtitleFor(l10n, share.subtitleKey)
                                case final sub?)
                              Text(
                                sub,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.ink2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Tag(
                        label: l10n.knowledgeMapsSocialFoundationTag,
                        variant: TagVariant.p,
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

class _DinnerQuestionCard extends StatelessWidget {
  const _DinnerQuestionCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.question,
    required this.busy,
    required this.onNext,
    required this.onSend,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final String question;
  final bool busy;
  final VoidCallback onNext;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: KnowledgeMapsKeys.dinnerCard,
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
            Text(
              l10n.knowledgeMapsDinnerHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '«$question»',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: colors.ink,
                height: 1.75,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryBtn(
                    key: KnowledgeMapsKeys.dinnerNextCta,
                    label: l10n.knowledgeMapsDinnerNextCta,
                    variant: PrimaryBtnVariant.sec,
                    onPressed: busy ? null : onNext,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryBtn(
                    key: KnowledgeMapsKeys.dinnerSendCta,
                    label: l10n.knowledgeMapsDinnerSendCta,
                    variant: PrimaryBtnVariant.teal,
                    onPressed: busy ? null : onSend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.knowledgeMapsDinnerFooter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
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
