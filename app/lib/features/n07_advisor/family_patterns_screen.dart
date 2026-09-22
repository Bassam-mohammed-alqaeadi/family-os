import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n07_advisor/family_patterns_models.dart';
import 'package:family_os/features/n07_advisor/family_patterns_repository.dart';

/// Widget keys for SCR-FAT-062 acceptance.
abstract final class FamilyPatternsKeys {
  static const screen = Key('family_patterns_screen');
  static const loading = Key('family_patterns_loading');
  static const empty = Key('family_patterns_empty');
  static const body = Key('family_patterns_body');
  static const advisorBanner = Key('family_patterns_advisor_banner');
  static const footerNote = Key('family_patterns_footer');
  static const observerHint = Key('family_patterns_observer');
  static const childLean = Key('family_patterns_child_lean');
  static const sosCta = Key('family_patterns_sos');
  static const sosIconCta = Key('family_patterns_sos_icon');

  static Key childCard(String id) => Key('family_patterns_child_$id');

  static Key confidenceSeal(String id) => Key('family_patterns_seal_$id');

  static Key timelineLink(String childId) => Key('family_patterns_timeline_$childId');

  static Key patternRow(String id) => Key('family_patterns_row_$id');
}

/// SCR-FAT-062 — أنماط العائلة (family patterns).
///
/// Prototype FAT-062 · S-AIC-007–011 · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · empty → FAT-003 · timeline → FAT-063.
class FamilyPatternsScreen extends StatefulWidget {
  const FamilyPatternsScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1FamilyPatternsRepository].
  final FamilyPatternsRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only timeline; partner/full may open.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId, {String? childId})? onNavigate;

  @override
  State<FamilyPatternsScreen> createState() => _FamilyPatternsScreenState();
}

class _FamilyPatternsScreenState extends State<FamilyPatternsScreen> {
  late FamilyPatternsRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  FamilyPatternsSnapshot _snap = const FamilyPatternsSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  bool get _canOpenTimeline {
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
    _repo = widget.repository ?? stage1FamilyPatternsRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant FamilyPatternsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1FamilyPatternsRepository;
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

  void _go(String screenId, {String? childId}) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(screenId, childId: childId);
      return;
    }
    context.push(screenPath(screenId));
  }

  void _blockedToast(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.familyPatternsObserverBlocked);
  }

  void _onTimelineTap(String childId) {
    final l10n = AppLocalizations.of(context);
    if (!_canOpenTimeline) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-063', childId: childId);
  }

  String _childName(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'childOne' => l10n.familyPatternsChildOne,
      'childTwo' => l10n.familyPatternsChildTwo,
      _ => l10n.familyPatternsChildOne,
    };
  }

  String _patternTitle(AppLocalizations l10n, FamilyPatternRow row) {
    return switch (row.titleKey) {
      'sleepDelay' => l10n.familyPatternsSleepDelayTitle,
      'communicationStable' => l10n.familyPatternsCommunicationStableTitle,
      'educationImprove' => l10n.familyPatternsEducationImproveTitle,
      'morningActivityDrop' => l10n.familyPatternsMorningActivityDropTitle,
      _ => l10n.familyPatternsCommunicationStableTitle,
    };
  }

  String? _patternSubtitle(AppLocalizations l10n, FamilyPatternRow row) {
    return switch (row.subtitleKey) {
      'sleepBaseline' => l10n.familyPatternsSleepBaselineSubtitle,
      'morningActivityHint' => l10n.familyPatternsMorningActivityHint,
      _ => null,
    };
  }

  (String label, TagVariant variant) _tagFor(
    AppLocalizations l10n,
    FamilyPatternTag tag,
  ) {
    return switch (tag) {
      FamilyPatternTag.anomaly => (
        l10n.familyPatternsTagAnomaly,
        TagVariant.a,
      ),
      FamilyPatternTag.ok => (l10n.familyPatternsTagOk, TagVariant.g),
      FamilyPatternTag.watch => (l10n.familyPatternsTagWatch, TagVariant.a),
      FamilyPatternTag.improve => (
        l10n.familyPatternsTagImprove,
        TagVariant.g,
      ),
    };
  }

  IconData _domainIcon(FamilyPatternDomain domain) {
    return switch (domain) {
      FamilyPatternDomain.sleep => Icons.nightlight_round,
      FamilyPatternDomain.communication => Icons.chat_bubble_outline,
      FamilyPatternDomain.education => Icons.menu_book_outlined,
      FamilyPatternDomain.morningActivity => Icons.wb_sunny_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FamilyPatternsKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.familyPatternsTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyPatternsKeys.sosIconCta,
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
        key: FamilyPatternsKeys.childLean,
        title: l10n.familyPatternsChildLeanTitle,
        message: l10n.familyPatternsChildLeanMessage,
        actionLabel: l10n.familyPatternsSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: FamilyPatternsKeys.loading,
        child: Semantics(
          label: l10n.familyPatternsLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdvisorBanner(
              l10n: l10n,
              confidencePercent: _snap.advisorConfidencePercent,
            ),
            const SizedBox(height: 16),
            AppEmptyState(
              key: FamilyPatternsKeys.empty,
              title: l10n.familyPatternsEmptyTitle,
              message: l10n.familyPatternsEmptyMessage,
              actionLabel: l10n.familyPatternsEmptyCta,
              onAction: () => _go('SCR-FAT-003'),
            ),
          ],
        ),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: FamilyPatternsKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdvisorBanner(
            l10n: l10n,
            confidencePercent: _snap.advisorConfidencePercent,
          ),
          if (_isObserverMother) ...[
            const SizedBox(height: 10),
            BannerNote(
              key: FamilyPatternsKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.familyPatternsObserverHint,
            ),
          ],
          const SizedBox(height: 14),
          for (final child in _snap.children) ...[
            _ChildPatternCard(
              card: child,
              colors: colors,
              radii: radii,
              l10n: l10n,
              childName: _childName(l10n, child.nameKey),
              confidenceLabel: l10n.familyPatternsConfidenceSeal(
                child.confidencePercent,
              ),
              timelineLabel: l10n.familyPatternsTimelineLink,
              patternTitle: _patternTitle,
              patternSubtitle: _patternSubtitle,
              tagFor: _tagFor,
              domainIcon: _domainIcon,
              onTimeline: () => _onTimelineTap(child.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text(
            l10n.familyPatternsFooterNote,
            key: FamilyPatternsKeys.footerNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.ink2,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorBanner extends StatelessWidget {
  const _AdvisorBanner({
    required this.l10n,
    required this.confidencePercent,
  });

  final AppLocalizations l10n;
  final int confidencePercent;

  @override
  Widget build(BuildContext context) {
    return BannerNote(
      key: FamilyPatternsKeys.advisorBanner,
      variant: BannerVariant.p,
      message: l10n.familyPatternsAdvisorBanner(confidencePercent),
    );
  }
}

class _ChildPatternCard extends StatelessWidget {
  const _ChildPatternCard({
    required this.card,
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.childName,
    required this.confidenceLabel,
    required this.timelineLabel,
    required this.patternTitle,
    required this.patternSubtitle,
    required this.tagFor,
    required this.domainIcon,
    required this.onTimeline,
  });

  final FamilyPatternChildCard card;
  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final String childName;
  final String confidenceLabel;
  final String timelineLabel;
  final String Function(AppLocalizations, FamilyPatternRow) patternTitle;
  final String? Function(AppLocalizations, FamilyPatternRow) patternSubtitle;
  final (String, TagVariant) Function(AppLocalizations, FamilyPatternTag) tagFor;
  final IconData Function(FamilyPatternDomain) domainIcon;
  final VoidCallback onTimeline;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: FamilyPatternsKeys.childCard(card.id),
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
                Expanded(
                  child: Text(
                    childName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                ),
                Tag(
                  key: FamilyPatternsKeys.confidenceSeal(card.id),
                  label: confidenceLabel,
                  variant: TagVariant.t,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < card.patterns.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.border),
              _PatternRow(
                row: card.patterns[i],
                colors: colors,
                title: patternTitle(l10n, card.patterns[i]),
                subtitle: patternSubtitle(l10n, card.patterns[i]),
                tag: tagFor(l10n, card.patterns[i].tag),
                icon: domainIcon(card.patterns[i].domain),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: FamilyPatternsKeys.timelineLink(card.id),
                onPressed: onTimeline,
                child: Text(timelineLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({
    required this.row,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
  });

  final FamilyPatternRow row;
  final FamilyColors colors;
  final String title;
  final String? subtitle;
  final (String label, TagVariant variant) tag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: FamilyPatternsKeys.patternRow(row.id),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.p700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tag(label: tag.$1, variant: tag.$2),
        ],
      ),
    );
  }
}
