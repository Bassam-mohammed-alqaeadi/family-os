import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_models.dart';
import 'package:family_os/features/n03_screen_time/child_usage_report_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

/// Widget keys for SCR-FAT-069 acceptance.
abstract final class ChildUsageReportKeys {
  static const screen = Key('child_usage_report_screen');
  static const loading = Key('child_usage_report_loading');
  static const empty = Key('child_usage_report_empty');
  static const body = Key('child_usage_report_body');
  static const weekCard = Key('child_usage_report_week');
  static const categoriesCard = Key('child_usage_report_categories');
  static const retentionBanner = Key('child_usage_report_retention');
  static const childLean = Key('child_usage_report_child_lean');
  static const sosIconCta = Key('child_usage_report_sos_icon');
  static const sosCta = Key('child_usage_report_sos');

  static Key category(String id) => Key('child_usage_report_cat_$id');
  static Key dayBar(int index) => Key('child_usage_report_day_$index');
}

/// SCR-FAT-069 — تقرير استخدام الابن (child usage report).
///
/// Prototype FAT-069 · S-SEC-050…052 · 30-day retention honesty ·
/// Rule 12/23 · mother levels (view) · mock-first · P-4 SOS · empty → FAT-003.
class ChildUsageReportScreen extends StatefulWidget {
  const ChildUsageReportScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  final ChildUsageReportRepository? repository;
  final SosFireService? sosFire;
  final AppRole? roleOverride;
  final MotherLevel motherLevel;
  final VoidCallback? onSos;
  final void Function(String screenId)? onNavigate;

  @override
  State<ChildUsageReportScreen> createState() => _ChildUsageReportScreenState();
}

class _ChildUsageReportScreenState extends State<ChildUsageReportScreen> {
  late ChildUsageReportRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  ChildUsageReportSnapshot _snap = const ChildUsageReportSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? Stage1ReportsRuntime.usageReport;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant ChildUsageReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1ReportsRuntime.usageReport;
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

  String _childName(AppLocalizations l10n) {
    return switch (_snap.childNameKey) {
      'childOne' => l10n.childUsageReportChildOne,
      'childTwo' => l10n.childUsageReportChildTwo,
      'childThree' => l10n.childUsageReportChildThree,
      _ => l10n.childUsageReportChildOne,
    };
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'learning' => l10n.childUsageReportCatLearning,
      'games' => l10n.childUsageReportCatGames,
      'chat' => l10n.childUsageReportCatChat,
      _ => l10n.childUsageReportCatGames,
    };
  }

  String _categoryEmoji(String key) {
    return switch (key) {
      'learning' => '📚',
      'games' => '🎮',
      'chat' => '💬',
      _ => '⏱',
    };
  }

  String _dayLabel(AppLocalizations l10n, int index) {
    final labels = [
      l10n.childUsageReportDaySat,
      l10n.childUsageReportDaySun,
      l10n.childUsageReportDayMon,
      l10n.childUsageReportDayTue,
      l10n.childUsageReportDayWed,
      l10n.childUsageReportDayThu,
      l10n.childUsageReportDayFri,
    ];
    if (index < 0 || index >= labels.length) return '';
    return labels[index];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: ChildUsageReportKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.childUsageReportTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: ChildUsageReportKeys.sosIconCta,
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
        key: ChildUsageReportKeys.childLean,
        title: l10n.childUsageReportChildLeanTitle,
        message: l10n.childUsageReportChildLeanMessage,
        actionLabel: l10n.childUsageReportSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: ChildUsageReportKeys.loading,
        child: Semantics(
          label: l10n.childUsageReportLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: ChildUsageReportKeys.empty,
        title: l10n.childUsageReportEmptyTitle,
        message: l10n.childUsageReportEmptyMessage,
        actionLabel: l10n.childUsageReportEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final childName = _childName(l10n);

    return SingleChildScrollView(
      key: ChildUsageReportKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.childUsageReportHeading(childName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _WeekCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            hours: _snap.weekHours,
            minutes: _snap.weekMinutes,
            dayHeights: _snap.dayHeights,
            dayLabel: (i) => _dayLabel(l10n, i),
          ),
          const SizedBox(height: 10),
          _CategoriesCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            categories: _snap.categories,
            labelOf: (k) => _categoryLabel(l10n, k),
            emojiOf: _categoryEmoji,
          ),
          const SizedBox(height: 10),
          BannerNote(
            key: ChildUsageReportKeys.retentionBanner,
            variant: BannerVariant.t,
            message: l10n.childUsageReportRetentionBanner(_snap.retentionDays),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.hours,
    required this.minutes,
    required this.dayHeights,
    required this.dayLabel,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final int hours;
  final int minutes;
  final List<int> dayHeights;
  final String Function(int) dayLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildUsageReportKeys.weekCard,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Text(
              l10n.childUsageReportThisWeek,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.childUsageReportWeekTotal(hours, minutes),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.p600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < dayHeights.length; i++)
                    Expanded(
                      child: Padding(
                        key: ChildUsageReportKeys.dayBar(i),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (dayHeights[i] / 100).clamp(0.08, 1),
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [colors.p400, colors.p600],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < dayHeights.length; i++)
                  Expanded(
                    child: Text(
                      dayLabel(i),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.ink2,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.categories,
    required this.labelOf,
    required this.emojiOf,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<UsageCategoryRow> categories;
  final String Function(String) labelOf;
  final String Function(String) emojiOf;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ChildUsageReportKeys.categoriesCard,
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
            Text(
              l10n.childUsageReportWhereHeading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final cat in categories)
              Padding(
                key: ChildUsageReportKeys.category(cat.id),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Semantics(
                  label:
                      '${labelOf(cat.labelKey)} ${cat.hours.toStringAsFixed(0)}h',
                  child: Row(
                    children: [
                      Text(
                        emojiOf(cat.labelKey),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.childUsageReportCatHours(
                                labelOf(cat.labelKey),
                                cat.hours.round(),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.ink,
                              ),
                            ),
                            if (cat.giftMinutes) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.childUsageReportGiftNote,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.mintInk,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: cat.progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: colors.p50,
                            color: cat.giftMinutes ? colors.mint : colors.p500,
                          ),
                        ),
                      ),
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
