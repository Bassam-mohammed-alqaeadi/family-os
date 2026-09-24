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
import 'package:family_os/features/n07_advisor/weekly_report_models.dart';
import 'package:family_os/features/n07_advisor/weekly_report_repository.dart';

abstract final class WeeklyReportKeys {
  static const screen = Key('weekly_report_screen');
  static const loading = Key('weekly_report_loading');
  static const empty = Key('weekly_report_empty');
  static const body = Key('weekly_report_body');
  static const settingsCard = Key('weekly_report_settings');
  static const whenCta = Key('weekly_report_when');
  static const styleCta = Key('weekly_report_style');
  static const recommendCard = Key('weekly_report_recommend');
  static const applyCta = Key('weekly_report_apply');
  static const deferCta = Key('weekly_report_defer');
  static const metrics = Key('weekly_report_metrics');
  static const emailBanner = Key('weekly_report_email');
  static const observerHint = Key('weekly_report_observer');
  static const childLean = Key('weekly_report_child_lean');
  static const sosIconCta = Key('weekly_report_sos_icon');

  static Key includeChip(String id) => Key('weekly_report_inc_$id');
  static Key section(String id) => Key('weekly_report_sec_$id');
}

/// SCR-FAT-073 — التقرير الأسبوعي بتوصية.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final WeeklyReportRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late WeeklyReportRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _busy = false;
  WeeklyReportSnapshot _snap = const WeeklyReportSnapshot();

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
    _repo = widget.repository ?? stage1WeeklyReportRepository;
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
    await _sos.fire(childId: 'family');
    if (!mounted) return;
    setState(() => _sosBusy = false);
    context.push(screenPath('SCR-FAT-018'));
  }

  void _go(String id) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(id);
      return;
    }
    context.push(screenPath(id));
  }

  void _blocked(AppLocalizations l10n) {
    AppToast.show(context, message: l10n.weeklyReportObserverBlocked);
  }

  Future<void> _toggleWhen() async {
    if (!_canAct) {
      _blocked(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.toggleWhen();
    if (!mounted) return;
    setState(() => _snap = snap);
    AppToast.show(
      context,
      message: AppLocalizations.of(
        context,
      ).weeklyReportWhenToast(_whenLabel(AppLocalizations.of(context))),
    );
  }

  Future<void> _toggleStyle() async {
    if (!_canAct) {
      _blocked(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.toggleStyle();
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _toggleInclude(String id) async {
    if (!_canAct) {
      _blocked(AppLocalizations.of(context));
      return;
    }
    final snap = await _repo.toggleInclude(id);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blocked(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final snap = await _repo.applyRecommendation();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(context, message: l10n.weeklyReportApplyToast);
  }

  Future<void> _defer() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blocked(l10n);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final snap = await _repo.deferRecommendation();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _busy = false;
    });
    AppToast.show(context, message: l10n.weeklyReportDeferToast);
  }

  String _whenLabel(AppLocalizations l10n) => switch (_snap.whenKey) {
    'saturdayEvening' => l10n.weeklyReportWhenSaturday,
    _ => l10n.weeklyReportWhenFriday,
  };

  String _styleLabel(AppLocalizations l10n) => switch (_snap.styleKey) {
    'brief' => l10n.weeklyReportStyleBrief,
    _ => l10n.weeklyReportStyleDetailed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Scaffold(
      key: WeeklyReportKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.weeklyReportTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: WeeklyReportKeys.sosIconCta,
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
    if (_isChild || !_isParent) {
      return AppEmptyState(
        key: WeeklyReportKeys.childLean,
        title: l10n.weeklyReportChildLeanTitle,
        message: l10n.weeklyReportChildLeanMessage,
        actionLabel: l10n.weeklyReportSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }
    if (_loading) {
      return Center(
        key: WeeklyReportKeys.loading,
        child: Semantics(
          label: l10n.weeklyReportLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_snap.isEmpty) {
      return AppEmptyState(
        key: WeeklyReportKeys.empty,
        title: l10n.weeklyReportEmptyTitle,
        message: l10n.weeklyReportEmptyMessage,
        actionLabel: l10n.weeklyReportEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final inc = _snap.include;

    return SingleChildScrollView(
      key: WeeklyReportKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: WeeklyReportKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.weeklyReportObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          DecoratedBox(
            key: WeeklyReportKeys.settingsCard,
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
                      Text(
                        l10n.weeklyReportSettingsHeading,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      const Spacer(),
                      Tag(
                        label: l10n.weeklyReportSettingsTag,
                        variant: TagVariant.p,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    emoji: '🕐',
                    title: l10n.weeklyReportWhenLabel,
                    value: _whenLabel(l10n),
                    ctaKey: WeeklyReportKeys.whenCta,
                    cta: l10n.weeklyReportChangeCta,
                    onTap: _toggleWhen,
                    colors: colors,
                  ),
                  _SettingsRow(
                    emoji: '📄',
                    title: l10n.weeklyReportStyleLabel,
                    value: _styleLabel(l10n),
                    ctaKey: WeeklyReportKeys.styleCta,
                    cta: l10n.weeklyReportToggleCta,
                    onTap: _toggleStyle,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in [
                        ('screen', l10n.weeklyReportIncScreen, inc.screen),
                        ('places', l10n.weeklyReportIncPlaces, inc.places),
                        ('wins', l10n.weeklyReportIncWins, inc.wins),
                        ('quran', l10n.weeklyReportIncQuran, inc.quran),
                        ('watch', l10n.weeklyReportIncWatch, inc.watch),
                      ])
                        Semantics(
                          button: true,
                          label: e.$2,
                          child: InkWell(
                            key: WeeklyReportKeys.includeChip(e.$1),
                            onTap: () => _toggleInclude(e.$1),
                            borderRadius: BorderRadius.circular(20),
                            child: Tag(
                              label: e.$3 ? '✓ ${e.$2}' : e.$2,
                              variant: e.$3 ? TagVariant.g : TagVariant.t,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            key: WeeklyReportKeys.recommendCard,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radii.card),
              border: Border.all(color: colors.teal, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.weeklyReportRecommendHeading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.weeklyReportRecommendBody(l10n.weeklyReportChildOne),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_snap.recommendationApplied &&
                      !_snap.recommendationDeferred) ...[
                    PrimaryBtn(
                      key: WeeklyReportKeys.applyCta,
                      label: l10n.weeklyReportApplyCta,
                      variant: PrimaryBtnVariant.teal,
                      onPressed: _busy || !_canAct ? null : _apply,
                    ),
                    const SizedBox(height: 8),
                    PrimaryBtn(
                      key: WeeklyReportKeys.deferCta,
                      label: l10n.weeklyReportDeferCta,
                      variant: PrimaryBtnVariant.ghost,
                      onPressed: _busy || !_canAct ? null : _defer,
                    ),
                  ] else
                    Text(
                      _snap.recommendationApplied
                          ? l10n.weeklyReportAppliedBanner
                          : l10n.weeklyReportDeferredBanner,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.mintInk,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            key: WeeklyReportKeys.metrics,
            children: [
              Expanded(
                child: _MetricCard(
                  label: l10n.weeklyReportMetricLearn,
                  value: l10n.weeklyReportLearnDelta(_snap.learnDeltaPercent),
                  colors: colors,
                  radii: radii,
                  positive: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: l10n.weeklyReportMetricSleep,
                  value: l10n.weeklyReportSleepDelta(
                    _snap.sleepDeltaMinutes.abs(),
                  ),
                  colors: colors,
                  radii: radii,
                  positive: false,
                ),
              ),
            ],
          ),
          if (inc.screen) ...[
            const SizedBox(height: 10),
            _SectionCard(
              key: WeeklyReportKeys.section('screen'),
              title: l10n.weeklyReportSecScreenTitle,
              body: l10n.weeklyReportSecScreenBody,
              colors: colors,
              radii: radii,
            ),
          ],
          if (inc.places) ...[
            const SizedBox(height: 10),
            _SectionCard(
              key: WeeklyReportKeys.section('places'),
              title: l10n.weeklyReportSecPlacesTitle,
              body: l10n.weeklyReportSecPlacesBody,
              colors: colors,
              radii: radii,
            ),
          ],
          if (inc.wins) ...[
            const SizedBox(height: 10),
            _SectionCard(
              key: WeeklyReportKeys.section('wins'),
              title: l10n.weeklyReportSecWinsTitle,
              body: l10n.weeklyReportSecWinsBody(
                l10n.weeklyReportChildOne,
                l10n.weeklyReportChildTwo,
                l10n.weeklyReportChildThree,
              ),
              colors: colors,
              radii: radii,
            ),
          ],
          if (inc.quran) ...[
            const SizedBox(height: 10),
            _SectionCard(
              key: WeeklyReportKeys.section('quran'),
              title: l10n.weeklyReportSecQuranTitle,
              body: l10n.weeklyReportSecQuranBody,
              colors: colors,
              radii: radii,
            ),
          ],
          if (inc.watch) ...[
            const SizedBox(height: 10),
            _SectionCard(
              key: WeeklyReportKeys.section('watch'),
              title: l10n.weeklyReportSecWatchTitle,
              body: l10n.weeklyReportSecWatchBody,
              colors: colors,
              radii: radii,
            ),
          ],
          const SizedBox(height: 10),
          BannerNote(
            key: WeeklyReportKeys.emailBanner,
            variant: BannerVariant.t,
            message: l10n.weeklyReportEmailBanner,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.emoji,
    required this.title,
    required this.value,
    required this.ctaKey,
    required this.cta,
    required this.onTap,
    required this.colors,
  });

  final String emoji;
  final String title;
  final String value;
  final Key ctaKey;
  final String cta;
  final VoidCallback onTap;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
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
                    color: colors.ink,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            key: ctaKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Tag(label: cta, variant: TagVariant.t),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.colors,
    required this.radii,
    required this.positive,
  });

  final String label;
  final String value;
  final FamilyColors colors;
  final FamilyRadii radii;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: positive ? colors.teal : colors.amberInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.body,
    required this.colors,
    required this.radii,
  });

  final String title;
  final String body;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
