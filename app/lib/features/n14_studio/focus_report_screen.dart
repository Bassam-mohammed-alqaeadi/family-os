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
import 'package:family_os/features/n14_studio/focus_report_models.dart';
import 'package:family_os/features/n14_studio/focus_report_repository.dart';
import 'package:family_os/features/n07_advisor/reports_ux_bridge.dart';

/// Widget keys for SCR-FAT-051 acceptance.
abstract final class FocusReportKeys {
  static const screen = Key('focus_report_screen');
  static const loading = Key('focus_report_loading');
  static const empty = Key('focus_report_empty');
  static const body = Key('focus_report_body');
  static const weeklyCard = Key('focus_report_weekly');
  static const advisorCard = Key('focus_report_advisor');
  static const praiseCta = Key('focus_report_praise');
  static const rewardCta = Key('focus_report_reward');
  static const praiseSent = Key('focus_report_praise_sent');
  static const scheduleCard = Key('focus_report_schedule');
  static const addScheduleCta = Key('focus_report_add_schedule');
  static const observerHint = Key('focus_report_observer');
  static const childLean = Key('focus_report_child_lean');
  static const sosCta = Key('focus_report_sos');
  static const sosIconCta = Key('focus_report_sos_icon');

  static Key scheduleRow(String id) => Key('focus_report_sched_$id');
  static Key scheduleSwitch(String id) => Key('focus_report_swt_$id');
}

/// SCR-FAT-051 — تقرير وجلسات التركيز (focus report and sessions).
///
/// Prototype FAT-051 · S-EDU-046 · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · minutes-only (ع-١) · empty → FAT-003.
class FocusReportScreen extends StatefulWidget {
  const FocusReportScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1FocusReportRepository].
  final FocusReportRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may praise/reward/toggle.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<FocusReportScreen> createState() => _FocusReportScreenState();
}

class _FocusReportScreenState extends State<FocusReportScreen> {
  late FocusReportRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  var _actionBusy = false;
  FocusReportSnapshot _snap = const FocusReportSnapshot();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may praise, reward, and toggle schedules.
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
    _repo = widget.repository ?? Stage1ReportsRuntime.focusReport;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant FocusReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? Stage1ReportsRuntime.focusReport;
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
    AppToast.show(context, message: l10n.focusReportObserverBlocked);
  }

  String _childName(AppLocalizations l10n) {
    final key = _snap.child?.nameKey;
    return switch (key) {
      'one' => l10n.focusReportChildOne,
      'two' => l10n.focusReportChildTwo,
      'three' => l10n.focusReportChildThree,
      _ => l10n.focusReportChildOne,
    };
  }

  String _scheduleName(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'afternoonStudy' => l10n.focusReportScheduleAfternoonStudy,
      _ => l10n.focusReportScheduleAfternoonStudy,
    };
  }

  String _scheduleTime(AppLocalizations l10n, String timeKey) {
    return switch (timeKey) {
      'afternoonSlot' => l10n.focusReportScheduleAfternoonSlot,
      _ => l10n.focusReportScheduleAfternoonSlot,
    };
  }

  String _scheduleDays(AppLocalizations l10n, String daysKey) {
    return switch (daysKey) {
      'schoolDays' => l10n.focusReportScheduleSchoolDays,
      _ => l10n.focusReportScheduleSchoolDays,
    };
  }

  String _blockedApps(AppLocalizations l10n, List<String> keys) {
    return keys
        .map(
          (k) => switch (k) {
            'youtube' => l10n.focusReportBlockedYoutube,
            'games' => l10n.focusReportBlockedGames,
            _ => l10n.focusReportBlockedGames,
          },
        )
        .join(l10n.focusReportBlockedJoiner);
  }

  String _advisorTitle(AppLocalizations l10n, FocusAdvisorNote note) {
    return switch (note.titleKey) {
      'selfDiscipline' => l10n.focusReportAdvisorTitleSelfDiscipline,
      _ => l10n.focusReportAdvisorTitleSelfDiscipline,
    };
  }

  String _advisorBody(AppLocalizations l10n, FocusAdvisorNote note) {
    return switch (note.bodyKey) {
      'scienceResist' => l10n.focusReportAdvisorBodyScienceResist(_childName(l10n)),
      _ => l10n.focusReportAdvisorBodyScienceResist(_childName(l10n)),
    };
  }

  String _praiseQuote(AppLocalizations l10n, String? quoteKey) {
    return switch (quoteKey) {
      'resistDistraction' => l10n.focusReportPraiseQuoteResistDistraction,
      _ => l10n.focusReportPraiseQuoteResistDistraction,
    };
  }

  Future<void> _onSendPraise() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_actionBusy || _snap.advisorNote?.praiseSent == true) return;
    setState(() => _actionBusy = true);
    final snap = await _repo.sendPraise();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _actionBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.focusReportPraiseSentToast(_childName(l10n)),
    );
  }

  Future<void> _onReward() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    final snap = await _repo.rewardSelfDiscipline();
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _actionBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.focusReportRewardToast(
        _childName(l10n),
        snap.rewardMinutes,
      ),
    );
  }

  Future<void> _onToggleSchedule(FocusScheduleItem item, bool value) async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    final snap = await _repo.toggleSchedule(item.id, value);
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  void _onAddSchedule() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    AppToast.show(context, message: l10n.focusReportAddScheduleToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FocusReportKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.focusReportTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FocusReportKeys.sosIconCta,
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
        key: FocusReportKeys.childLean,
        title: l10n.focusReportChildLeanTitle,
        message: l10n.focusReportChildLeanMessage,
        actionLabel: l10n.focusReportSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: FocusReportKeys.loading,
        child: Semantics(
          label: l10n.focusReportLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FocusReportKeys.empty,
        title: l10n.focusReportEmptyTitle,
        message: l10n.focusReportEmptyMessage,
        actionLabel: l10n.focusReportEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final childName = _childName(l10n);
    final weekly = _snap.weeklySummary!;
    final advisor = _snap.advisorNote!;

    return SingleChildScrollView(
      key: FocusReportKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: FocusReportKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.focusReportObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.focusReportHeading(childName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _WeeklySummaryCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            summary: weekly,
          ),
          const SizedBox(height: 10),
          _AdvisorCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            childName: childName,
            note: advisor,
            rewardMinutes: _snap.rewardMinutes,
            title: _advisorTitle(l10n, advisor),
            body: _advisorBody(l10n, advisor),
            praiseQuote: advisor.praiseQuoteKey != null
                ? _praiseQuote(l10n, advisor.praiseQuoteKey)
                : null,
            onPraise: _actionBusy ? null : _onSendPraise,
            onReward: _actionBusy ? null : _onReward,
          ),
          const SizedBox(height: 10),
          _ScheduleCard(
            colors: colors,
            radii: radii,
            l10n: l10n,
            schedules: _snap.schedules,
            canEdit: _canAct,
            scheduleName: _scheduleName,
            scheduleTime: _scheduleTime,
            scheduleDays: _scheduleDays,
            blockedApps: _blockedApps,
            childName: (key) => switch (key) {
              'one' => l10n.focusReportChildOne,
              'two' => l10n.focusReportChildTwo,
              'three' => l10n.focusReportChildThree,
              _ => l10n.focusReportChildOne,
            },
            onToggle: _onToggleSchedule,
            onAddSchedule: _onAddSchedule,
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.summary,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final FocusWeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final hours = summary.totalDurationMinutes ~/ 60;
    final mins = summary.totalDurationMinutes % 60;
    final goalComplete =
        summary.goalStatus == FocusReportGoalStatus.complete;

    return DecoratedBox(
      key: FocusReportKeys.weeklyCard,
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
              children: [
                Text(
                  l10n.focusReportWeeklyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
                const Spacer(),
                Tag(
                  label: goalComplete
                      ? l10n.focusReportGoalComplete
                      : l10n.focusReportGoalInProgress,
                  variant: TagVariant.g,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${summary.sessionsCount}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: colors.p600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.focusReportSessionsLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.focusReportWeeklyMeta(
                hours,
                mins,
                summary.longestSessionMinutes,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
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

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.childName,
    required this.note,
    required this.rewardMinutes,
    required this.title,
    required this.body,
    required this.praiseQuote,
    required this.onPraise,
    required this.onReward,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final String childName;
  final FocusAdvisorNote note;
  final int rewardMinutes;
  final String title;
  final String body;
  final String? praiseQuote;
  final VoidCallback? onPraise;
  final VoidCallback? onReward;

  @override
  Widget build(BuildContext context) {
    final praiseSent = note.praiseSent;
    final borderColor = praiseSent ? colors.mint : colors.p400;

    return DecoratedBox(
      key: FocusReportKeys.advisorCard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.p50, colors.p100.withValues(alpha: 0.65)],
        ),
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧠', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: colors.p700,
                              ),
                            ),
                          ),
                          Tag(
                            label: praiseSent
                                ? l10n.focusReportPraiseSentTag
                                : l10n.focusReportPraiseNewTag,
                            variant: praiseSent ? TagVariant.g : TagVariant.a,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (praiseSent && praiseQuote != null)
              DecoratedBox(
                key: FocusReportKeys.praiseSent,
                decoration: BoxDecoration(
                  color: colors.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.mint),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💌', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.focusReportPraiseDeliveredLabel(childName),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: colors.mintInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '«$praiseQuote»',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.mintInk,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      key: FocusReportKeys.praiseCta,
                      label: l10n.focusReportPraiseCta,
                      variant: PrimaryBtnVariant.sec,
                      onPressed: onPraise,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryBtn(
                      key: FocusReportKeys.rewardCta,
                      label: l10n.focusReportRewardCta(rewardMinutes),
                      variant: PrimaryBtnVariant.mint,
                      onPressed: onReward,
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.colors,
    required this.radii,
    required this.l10n,
    required this.schedules,
    required this.canEdit,
    required this.scheduleName,
    required this.scheduleTime,
    required this.scheduleDays,
    required this.blockedApps,
    required this.childName,
    required this.onToggle,
    required this.onAddSchedule,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final AppLocalizations l10n;
  final List<FocusScheduleItem> schedules;
  final bool canEdit;
  final String Function(AppLocalizations, String) scheduleName;
  final String Function(AppLocalizations, String) scheduleTime;
  final String Function(AppLocalizations, String) scheduleDays;
  final String Function(AppLocalizations, List<String>) blockedApps;
  final String Function(String) childName;
  final Future<void> Function(FocusScheduleItem, bool) onToggle;
  final VoidCallback onAddSchedule;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: FocusReportKeys.scheduleCard,
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
                  l10n.focusReportScheduleHeading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const Spacer(),
                Tag(
                  label: l10n.focusReportScheduleOwnerTag,
                  variant: TagVariant.p,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in schedules)
              _ScheduleRow(
                item: item,
                colors: colors,
                title:
                    '${scheduleName(l10n, item.nameKey)} — ${childName(item.childNameKey)}',
                subtitle: l10n.focusReportScheduleMeta(
                  scheduleTime(l10n, item.timeKey),
                  scheduleDays(l10n, item.daysKey),
                  blockedApps(l10n, item.blockedAppKeys),
                ),
                enabled: canEdit,
                onChanged: (v) => onToggle(item, v),
              ),
            const SizedBox(height: 8),
            PrimaryBtn(
              key: FocusReportKeys.addScheduleCta,
              label: l10n.focusReportAddScheduleCta,
              variant: PrimaryBtnVariant.sec,
              onPressed: onAddSchedule,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.focusReportScheduleFootnote(childName('one')),
              style: TextStyle(
                fontSize: 11.5,
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

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.item,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  final FocusScheduleItem item;
  final FamilyColors colors;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Padding(
        key: FocusReportKeys.scheduleRow(item.id),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              key: FocusReportKeys.scheduleSwitch(item.id),
              value: item.enabled,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: colors.mint,
            ),
          ],
        ),
      ),
    );
  }
}
