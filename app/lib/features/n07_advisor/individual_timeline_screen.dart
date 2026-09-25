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
import 'package:family_os/features/n07_advisor/individual_timeline_models.dart';
import 'package:family_os/features/n07_advisor/individual_timeline_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

/// Widget keys for SCR-FAT-063 acceptance.
abstract final class IndividualTimelineKeys {
  static const screen = Key('individual_timeline_screen');
  static const loading = Key('individual_timeline_loading');
  static const empty = Key('individual_timeline_empty');
  static const body = Key('individual_timeline_body');
  static const insightCard = Key('individual_timeline_insight');
  static const todayHeading = Key('individual_timeline_today');
  static const todayThread = Key('individual_timeline_thread');
  static const discussCta = Key('individual_timeline_discuss');
  static const observerHint = Key('individual_timeline_observer');
  static const childLean = Key('individual_timeline_child_lean');
  static const sosIconCta = Key('individual_timeline_sos_icon');

  static Key stop(String id) => Key('individual_timeline_stop_$id');
}

/// SCR-FAT-063 — الخط الزمني للفرد (individual timeline).
///
/// Prototype FAT-063 · S-AIC-012/013/016 · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · empty → FAT-003 · read-heavy parent view.
class IndividualTimelineScreen extends StatefulWidget {
  const IndividualTimelineScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1IndividualTimelineRepository].
  final IndividualTimelineRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full same read view.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<IndividualTimelineScreen> createState() =>
      _IndividualTimelineScreenState();
}

class _IndividualTimelineScreenState extends State<IndividualTimelineScreen> {
  late IndividualTimelineRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  IndividualTimelineSnapshot _snap = const IndividualTimelineSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may act on insight CTA.
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
    _repo = widget.repository ?? Stage1ReportsRuntime.individualTimeline;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant IndividualTimelineScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1ReportsRuntime.individualTimeline;
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
    AppToast.show(context, message: l10n.individualTimelineObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    return switch (_snap.nameKey) {
      'childOne' => l10n.individualTimelineChildOne,
      'childTwo' => l10n.individualTimelineChildTwo,
      'childThree' => l10n.individualTimelineChildThree,
      _ => l10n.individualTimelineChildOne,
    };
  }

  String _insightBadge(AppLocalizations l10n, String badgeKey) {
    return switch (badgeKey) {
      'crossDomainLink' => l10n.individualTimelineInsightBadgeCrossDomain,
      _ => l10n.individualTimelineInsightBadgeCrossDomain,
    };
  }

  String _patternText(AppLocalizations l10n, String patternKey) {
    return switch (patternKey) {
      'footballSleepStudy' => l10n.individualTimelinePatternFootballSleepStudy,
      _ => l10n.individualTimelinePatternFootballSleepStudy,
    };
  }

  String _suggestionText(AppLocalizations l10n, String suggestionKey) {
    return switch (suggestionKey) {
      'testsAfterPractice' => l10n.individualTimelineSuggestionTestsAfterPractice,
      _ => l10n.individualTimelineSuggestionTestsAfterPractice,
    };
  }

  String _privacyNote(AppLocalizations l10n, String privacyKey) {
    return switch (privacyKey) {
      'triDomainUnique' => l10n.individualTimelinePrivacyTriDomainUnique,
      _ => l10n.individualTimelinePrivacyTriDomainUnique,
    };
  }

  String _stopTitle(AppLocalizations l10n, IndividualTimelineStop stop) {
    return switch (stop.titleKey) {
      'schoolModeActive' => l10n.individualTimelineStopSchoolModeActive,
      'finishedFractionsReview' =>
        l10n.individualTimelineStopFinishedFractionsReview,
      'arrivedSchoolMessage' => l10n.individualTimelineStopArrivedSchoolMessage,
      'lateSleep' => l10n.individualTimelineStopLateSleep,
      _ => l10n.individualTimelineStopSchoolModeActive,
    };
  }

  String _stopTime(AppLocalizations l10n, IndividualTimelineStop stop) {
    return switch (stop.timeKey) {
      'since7am' => l10n.individualTimelineTimeSince7am,
      'at840am' => l10n.individualTimelineTimeAt840am,
      'at714am' => l10n.individualTimelineTimeAt714am,
      'at1110pmYesterday' => l10n.individualTimelineTimeAt1110pmYesterday,
      _ => l10n.individualTimelineTimeSince7am,
    };
  }

  String _stopDetail(AppLocalizations l10n, String? detailKey) {
    return switch (detailKey) {
      'score90' => l10n.individualTimelineDetailScore90,
      'late40minBaseline' => l10n.individualTimelineDetailLate40minBaseline,
      _ => '',
    };
  }

  String _stopEmoji(IndividualTimelineStopKind kind) {
    return switch (kind) {
      IndividualTimelineStopKind.schoolMode => '🏫',
      IndividualTimelineStopKind.studyComplete => '📚',
      IndividualTimelineStopKind.childMessage => '💬',
      IndividualTimelineStopKind.sleep => '🌙',
    };
  }

  String _stopSubtitle(AppLocalizations l10n, IndividualTimelineStop stop) {
    final time = _stopTime(l10n, stop);
    final detail = _stopDetail(l10n, stop.detailKey);
    if (detail.isEmpty) return time;
    return '$time · $detail';
  }

  void _onDiscussSuggestion() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.individualTimelineDiscussToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final childName = _childName(l10n);

    return Scaffold(
      key: IndividualTimelineKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        elevation: 0,
        foregroundColor: colors.ink,
        title: Text(
          l10n.individualTimelineTitle(childName),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: IndividualTimelineKeys.sosIconCta,
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
      body: SafeArea(child: _buildBody(context, l10n, colors, childName)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    FamilyColors colors,
    String childName,
  ) {
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: IndividualTimelineKeys.childLean,
        title: l10n.individualTimelineChildLeanTitle,
        message: l10n.individualTimelineChildLeanMessage,
        actionLabel: l10n.individualTimelineSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: IndividualTimelineKeys.loading,
        child: Semantics(
          label: l10n.individualTimelineLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: IndividualTimelineKeys.empty,
        title: l10n.individualTimelineEmptyTitle,
        message: l10n.individualTimelineEmptyMessage,
        actionLabel: l10n.individualTimelineEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final insight = _snap.insight;

    return SingleChildScrollView(
      key: IndividualTimelineKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: IndividualTimelineKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.individualTimelineObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          if (insight != null) ...[
            _InsightCard(
              colors: colors,
              radii: radii,
              l10n: l10n,
              badge: _insightBadge(l10n, insight.badgeKey),
              pattern: _patternText(l10n, insight.patternKey),
              suggestion: _suggestionText(l10n, insight.suggestionKey),
              privacyNote: _privacyNote(l10n, insight.privacyNoteKey),
              onDiscuss: _onDiscussSuggestion,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            key: IndividualTimelineKeys.todayHeading,
            l10n.individualTimelineTodayHeading,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: IndividualTimelineKeys.todayThread,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  for (var i = 0; i < _snap.todayStops.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _TimelineStopRow(
                      stop: _snap.todayStops[i],
                      colors: colors,
                      title: _stopTitle(l10n, _snap.todayStops[i]),
                      subtitle: _stopSubtitle(l10n, _snap.todayStops[i]),
                      emoji: _stopEmoji(_snap.todayStops[i].kind),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.badge,
    required this.pattern,
    required this.suggestion,
    required this.privacyNote,
    required this.onDiscuss,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final String badge;
  final String pattern;
  final String suggestion;
  final String privacyNote;
  final VoidCallback onDiscuss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: IndividualTimelineKeys.insightCard,
      decoration: BoxDecoration(
        color: colors.p50,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.p100),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Tag(label: badge, variant: TagVariant.p),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                  height: 1.75,
                ),
                children: [
                  TextSpan(
                    text: l10n.individualTimelinePatternLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: pattern),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                            height: 1.55,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.individualTimelineSuggestionLabel,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: suggestion),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              privacyNote,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryBtn(
              key: IndividualTimelineKeys.discussCta,
              label: l10n.individualTimelineDiscussCta,
              onPressed: onDiscuss,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStopRow extends StatelessWidget {
  const _TimelineStopRow({
    required this.stop,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  final IndividualTimelineStop stop;
  final FamilyColors colors;
  final String title;
  final String subtitle;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final accent = stop.isNow ? colors.p500 : colors.ink2;

    return Semantics(
      container: true,
      label: '$title · $subtitle',
      child: Row(
        key: IndividualTimelineKeys.stop(stop.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: stop.isNow ? colors.p500 : colors.border,
                  shape: BoxShape.circle,
                  border: stop.isNow
                      ? Border.all(color: colors.p700, width: 2)
                      : null,
                ),
              ),
              if (stop.isNow)
                Container(
                  width: 2,
                  height: 18,
                  color: colors.p100,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 18)),
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
                    color: stop.isNow ? colors.p700 : colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
