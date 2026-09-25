import 'package:flutter/material.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/advisor_repository.dart';
import 'package:family_os/core/policy/ai_stage_flags.dart';
import 'package:family_os/core/policy/ai_stage_flags_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

/// Widget keys for SCR-FAT-029 / SET-014 + SET-015 acceptance.
abstract final class BrainControlKeys {
  static const servesBanner = Key('brain_serves_banner');
  static const suggestionsList = Key('brain_suggestions_list');
  static const comingSoonLabel = Key('brain_coming_soon');
  static const denyPanel = Key('brain_deny_panel');

  static Key stageRow(AiStageId id) => Key('brain_stage_row_${id.name}');

  static Key stageCta(AiStageId id) => Key('brain_stage_cta_${id.name}');

  static Key stageStatus(AiStageId id) => Key('brain_stage_status_${id.name}');
}

/// SCR-FAT-029 — لوحة تحكم العقل (SET-014 server flags; SET-015 father-only).
///
/// Stages gated by remote flags. Flag off → coming-soon / disabled CTA.
/// Flag on → CTA loads mock [AdvisorRepository.suggestions] (no auto-apply).
/// Non-father (mother any level / child) → deny panel; zero stage controls.
class BrainControlScreen extends StatefulWidget {
  const BrainControlScreen({
    super.key,
    this.flagsRepository,
    this.advisor,
    this.roleOverride,
  });

  /// Rule 25 seam — null → [stage1AiStageFlags].
  final AiStageFlagsRepository? flagsRepository;

  /// Rule 26 gateway — null → [stage1AdvisorRepository].
  final AdvisorRepository? advisor;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  @override
  BrainControlScreenState createState() => BrainControlScreenState();
}

class BrainControlScreenState extends State<BrainControlScreen> {
  late final AiStageFlagsRepository _flagsRepo;
  late final AdvisorRepository _advisor;
  AiStageFlags _flags = AiStageFlags.allOff();
  var _loading = true;
  List<AiSuggestion>? _suggestions;
  AiStageId? _openStage;

  AppRole get _role =>
      widget.roleOverride ??
      CurrentRole.maybeNotifierOf(context)?.value ??
      AppRole.father;

  bool get _allowed => canOpenBrainControl(_role);

  @override
  void initState() {
    super.initState();
    _flagsRepo = widget.flagsRepository ?? stage1AiStageFlags;
    _advisor = widget.advisor ?? Stage1ReportsRuntime.brainControl;
    // Defer load until first frame so roleOverride / CurrentRole is readable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_allowed) {
        _load();
      } else {
        setState(() => _loading = false);
      }
    });
  }

  Future<void> _load() async {
    // Prefer remote fetch; offline falls back to cache / all-off.
    try {
      final fetched = await _flagsRepo.fetchFlags();
      if (!mounted) return;
      setState(() {
        _flags = fetched;
        _loading = false;
      });
    } on Object {
      final repo = _flagsRepo;
      if (repo is MockRemoteAiStageFlags) {
        final cached = await repo.loadCachedOrOff();
        if (!mounted) return;
        setState(() {
          _flags = cached;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _flags = repo.cachedFlags ?? AiStageFlags.allOff();
          _loading = false;
        });
      }
    }
  }

  /// Opens mock Advisor suggestions for an enabled stage (suggest-only; no apply).
  void openSuggestions(AiStageId stage) {
    if (!_allowed) return;
    if (!_flags.isEnabled(stage)) return;
    final advisor = _advisor;
    if (advisor is MockAdvisorRepository) {
      setState(() {
        _openStage = stage;
        _suggestions = advisor.suggestionsSync(stage: stage);
      });
      return;
    }
    advisor.suggestions(stage: stage).then((list) {
      if (!mounted) return;
      setState(() {
        _openStage = stage;
        _suggestions = list;
      });
    });
  }

  String _stageTitle(AppLocalizations l10n, AiStageId id) => switch (id) {
        AiStageId.analyze => l10n.brainStageAnalyzeTitle,
        AiStageId.suggest => l10n.brainStageSuggestTitle,
        AiStageId.coach => l10n.brainStageCoachTitle,
      };

  String _stageSubtitle(AppLocalizations l10n, AiStageId id) => switch (id) {
        AiStageId.analyze => l10n.brainStageAnalyzeSubtitle,
        AiStageId.suggest => l10n.brainStageSuggestSubtitle,
        AiStageId.coach => l10n.brainStageCoachSubtitle,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.brainControlTitle),
        backgroundColor: colors.bg,
        foregroundColor: colors.ink,
        elevation: 0,
      ),
      body: !_allowed
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: _BrainDenyPanel(message: l10n.brainControlUnavailable),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BannerNote(
                        key: BrainControlKeys.servesBanner,
                        message: l10n.brainServesNotDecidesBanner,
                        variant: BannerVariant.p,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.brainStagesHeading,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final id in AiStageId.values) ...[
                        _StageCard(
                          stageId: id,
                          title: _stageTitle(l10n, id),
                          subtitle: _stageSubtitle(l10n, id),
                          enabled: _flags.isEnabled(id),
                          activeLabel: l10n.brainStageActive,
                          comingSoonLabel: l10n.brainStageComingSoon,
                          ctaLabel: l10n.brainStageViewSuggestions,
                          onCta: () {
                            openSuggestions(id);
                          },
                          colors: colors,
                          radii: Theme.of(context).extension<FamilyRadii>()!,
                        ),
                        const SizedBox(height: 10),
                      ],
                      ..._suggestionSection(l10n, colors),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _suggestionSection(
    AppLocalizations l10n,
    FamilyColors colors,
  ) {
    final suggestions = _suggestions;
    if (suggestions == null) return const [];
    return [
      const SizedBox(height: 8),
      Text(
        key: BrainControlKeys.suggestionsList,
        l10n.brainSuggestionsHeading,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
      ),
      const SizedBox(height: 8),
      for (final s in suggestions) ...[
        Text(
          s.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colors.ink,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.body,
          style: TextStyle(
            color: colors.ink2,
            fontSize: 12,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (suggestions.isEmpty)
        Text(
          l10n.brainSuggestionsEmpty,
          style: TextStyle(color: colors.ink2, fontSize: 12.5),
        ),
      if (_openStage != null)
        Text(
          l10n.brainSuggestionsDecideHint,
          style: TextStyle(
            color: colors.ink2,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
    ];
  }
}

class _BrainDenyPanel extends StatelessWidget {
  const _BrainDenyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return DecoratedBox(
      key: BrainControlKeys.denyPanel,
      decoration: BoxDecoration(
        color: colors.coral100,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.coral),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stageId,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.activeLabel,
    required this.comingSoonLabel,
    required this.ctaLabel,
    required this.onCta,
    required this.colors,
    required this.radii,
  });

  final AiStageId stageId;
  final String title;
  final String subtitle;
  final bool enabled;
  final String activeLabel;
  final String comingSoonLabel;
  final String ctaLabel;
  final VoidCallback onCta;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: BrainControlKeys.stageRow(stageId),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.ink2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                KeyedSubtree(
                  key: BrainControlKeys.stageStatus(stageId),
                  child: enabled
                      ? Tag(label: activeLabel, variant: TagVariant.g)
                      : Tag(
                          key: BrainControlKeys.comingSoonLabel,
                          label: comingSoonLabel,
                          variant: TagVariant.a,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryBtn(
              key: BrainControlKeys.stageCta(stageId),
              label: enabled ? ctaLabel : comingSoonLabel,
              onPressed: enabled ? onCta : null,
              variant: enabled ? PrimaryBtnVariant.primary : PrimaryBtnVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }
}
