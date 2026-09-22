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
import 'package:family_os/features/n15_calendar/family_calendar_models.dart';
import 'package:family_os/features/n15_calendar/family_calendar_repository.dart';

/// Widget keys for SCR-FAT-052 acceptance.
abstract final class FamilyCalendarKeys {
  static const screen = Key('family_calendar_screen');
  static const loading = Key('family_calendar_loading');
  static const empty = Key('family_calendar_empty');
  static const body = Key('family_calendar_body');
  static const headerCard = Key('family_calendar_header');
  static const monthGrid = Key('family_calendar_month');
  static const filterRow = Key('family_calendar_filters');
  static const eventsCard = Key('family_calendar_events');
  static const filterEmpty = Key('family_calendar_filter_empty');
  static const addEventCta = Key('family_calendar_add_event');
  static const observerHint = Key('family_calendar_observer');
  static const childLean = Key('family_calendar_child_lean');
  static const sosCta = Key('family_calendar_sos');
  static const sosIconCta = Key('family_calendar_sos_icon');

  static Key filterChip(String id) => Key('family_calendar_filter_$id');
  static Key eventRow(String id) => Key('family_calendar_event_$id');
  static Key dayCell(int day) => Key('family_calendar_day_$day');
}

/// SCR-FAT-052 — التقويم العائلي (family calendar).
///
/// Prototype FAT-052 · calendar wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · CTA → FAT-053 add event.
class FamilyCalendarScreen extends StatefulWidget {
  const FamilyCalendarScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1FamilyCalendarRepository].
  final FamilyCalendarRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may add events.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<FamilyCalendarScreen> createState() => _FamilyCalendarScreenState();
}

class _FamilyCalendarScreenState extends State<FamilyCalendarScreen> {
  late FamilyCalendarRepository _repo;
  late final SosFireService _sos;
  var _sosBusy = false;
  var _loading = true;
  FamilyCalendarSnapshot _snap = const FamilyCalendarSnapshot();
  FamilyCalendarFilter _filter = FamilyCalendarFilter.all;

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may add events (observer view-only).
  bool get _canAct {
    if (_role == AppRole.father) return true;
    if (_role == AppRole.mother) {
      return widget.motherLevel == MotherLevel.partner ||
          widget.motherLevel == MotherLevel.full;
    }
    return false;
  }

  List<FamilyCalendarEvent> get _filteredEvents {
    if (_filter == FamilyCalendarFilter.all) return _snap.events;
    return _snap.events
        .where((e) => _categoryForFilter(_filter) == e.category)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? stage1FamilyCalendarRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void didUpdateWidget(covariant FamilyCalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1FamilyCalendarRepository;
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
    AppToast.show(context, message: l10n.familyCalendarObserverBlocked);
  }

  void _onFilterTap(FamilyCalendarFilter filter) {
    // View action — observer may filter; only add is gated by [_canAct].
    setState(() => _filter = filter);
  }

  void _onAddEvent() {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    _go('SCR-FAT-053');
  }

  FamilyCalendarEventCategory _categoryForFilter(FamilyCalendarFilter filter) {
    return switch (filter) {
      FamilyCalendarFilter.din => FamilyCalendarEventCategory.din,
      FamilyCalendarFilter.occ => FamilyCalendarEventCategory.occ,
      FamilyCalendarFilter.sch => FamilyCalendarEventCategory.sch,
      FamilyCalendarFilter.act => FamilyCalendarEventCategory.act,
      FamilyCalendarFilter.all => FamilyCalendarEventCategory.din,
    };
  }

  String _whoName(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'one' => l10n.familyCalendarWhoOne,
      'two' => l10n.familyCalendarWhoTwo,
      'three' => l10n.familyCalendarWhoThree,
      'parents' => l10n.familyCalendarWhoParents,
      'everyone' => l10n.familyCalendarWhoEveryone,
      _ => l10n.familyCalendarWhoEveryone,
    };
  }

  String _eventTitle(AppLocalizations l10n, String titleKey) {
    return switch (titleKey) {
      'memorizationReview' => l10n.familyCalendarEventMemorizationReview,
      'swimPractice' => l10n.familyCalendarEventSwimPractice,
      'grandpaDinner' => l10n.familyCalendarEventGrandpaDinner,
      'quranTest' => l10n.familyCalendarEventQuranTest,
      'anniversary' => l10n.familyCalendarEventAnniversary,
      'dentalAppointment' => l10n.familyCalendarEventDentalAppointment,
      _ => l10n.familyCalendarEventMemorizationReview,
    };
  }

  String _eventWhen(AppLocalizations l10n, String whenKey) {
    return switch (whenKey) {
      'todayAfterMaghrib' => l10n.familyCalendarWhenTodayAfterMaghrib,
      'today430pm' => l10n.familyCalendarWhenToday430pm,
      'today730pm' => l10n.familyCalendarWhenToday730pm,
      'tuesday' => l10n.familyCalendarWhenTuesday,
      'thursday26' => l10n.familyCalendarWhenThursday26,
      'thursday10am' => l10n.familyCalendarWhenThursday10am,
      _ => l10n.familyCalendarWhenTuesday,
    };
  }

  String _categoryIcon(FamilyCalendarEventCategory cat) {
    return switch (cat) {
      FamilyCalendarEventCategory.din => '🕌',
      FamilyCalendarEventCategory.occ => '🎂',
      FamilyCalendarEventCategory.sch => '🏫',
      FamilyCalendarEventCategory.act => '⚽',
    };
  }

  String _filterLabel(AppLocalizations l10n, FamilyCalendarFilter filter) {
    return switch (filter) {
      FamilyCalendarFilter.all => l10n.familyCalendarFilterAll,
      FamilyCalendarFilter.din => l10n.familyCalendarFilterDin,
      FamilyCalendarFilter.occ => l10n.familyCalendarFilterOcc,
      FamilyCalendarFilter.sch => l10n.familyCalendarFilterSch,
      FamilyCalendarFilter.act => l10n.familyCalendarFilterAct,
    };
  }

  String _eventsHeading(AppLocalizations l10n) {
    return switch (_filter) {
      FamilyCalendarFilter.all => l10n.familyCalendarEventsHeadingAll,
      FamilyCalendarFilter.din => l10n.familyCalendarEventsHeadingDin,
      FamilyCalendarFilter.occ => l10n.familyCalendarEventsHeadingOcc,
      FamilyCalendarFilter.sch => l10n.familyCalendarEventsHeadingSch,
      FamilyCalendarFilter.act => l10n.familyCalendarEventsHeadingAct,
    };
  }

  String _monthTitle(AppLocalizations l10n, String monthTitleKey) {
    return switch (monthTitleKey) {
      'sep2026' => l10n.familyCalendarMonthSep2026,
      _ => l10n.familyCalendarMonthSep2026,
    };
  }

  Color _colorForKey(FamilyColors colors, String colorKey) {
    return switch (colorKey) {
      'purple' => colors.p500,
      'sky' => colors.sky,
      'mint' => colors.mint,
      'amber' => colors.amber,
      'lavender' => colors.p400,
      _ => colors.p500,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: FamilyCalendarKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.familyCalendarTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: FamilyCalendarKeys.sosIconCta,
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
        key: FamilyCalendarKeys.childLean,
        title: l10n.familyCalendarChildLeanTitle,
        message: l10n.familyCalendarChildLeanMessage,
        actionLabel: l10n.familyCalendarSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: FamilyCalendarKeys.loading,
        child: Semantics(
          label: l10n.familyCalendarLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: FamilyCalendarKeys.empty,
        title: l10n.familyCalendarEmptyTitle,
        message: l10n.familyCalendarEmptyMessage,
        actionLabel: l10n.familyCalendarEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final filtered = _filteredEvents;

    return SingleChildScrollView(
      key: FamilyCalendarKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: FamilyCalendarKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.familyCalendarObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          _HeaderCard(l10n: l10n, colors: colors, radii: radii),
          const SizedBox(height: 12),
          _MonthGridCard(
            l10n: l10n,
            colors: colors,
            radii: radii,
            month: _snap.month,
            events: _snap.events,
            monthTitle: _monthTitle(l10n, _snap.month.monthTitleKey),
            colorForKey: (key) => _colorForKey(colors, key),
          ),
          const SizedBox(height: 12),
          Wrap(
            key: FamilyCalendarKeys.filterRow,
            spacing: 6,
            runSpacing: 6,
            children: FamilyCalendarFilter.values.map((filter) {
              final selected = _filter == filter;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: FamilyCalendarKeys.filterChip(filter.name),
                  onTap: () => _onFilterTap(filter),
                  borderRadius: BorderRadius.circular(radii.pill),
                  child: Tag(
                    label: _filterLabel(l10n, filter),
                    variant: selected ? TagVariant.p : TagVariant.t,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            key: FamilyCalendarKeys.eventsCard,
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
                    _eventsHeading(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      key: FamilyCalendarKeys.filterEmpty,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.familyCalendarFilterEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink2,
                        ),
                      ),
                    )
                  else
                    for (final event in filtered)
                      _EventRow(
                        rowKey: FamilyCalendarKeys.eventRow(event.id),
                        title: _eventTitle(l10n, event.titleKey),
                        subtitle:
                            '${_eventWhen(l10n, event.whenKey)} · ${_whoName(l10n, event.whoNameKey)} · ${_categoryIcon(event.category)}',
                        color: _colorForKey(colors, event.colorKey),
                        colors: colors,
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: FamilyCalendarKeys.addEventCta,
            label: l10n.familyCalendarAddEventCta,
            onPressed: _onAddEvent,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.l10n,
    required this.colors,
    required this.radii,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final FamilyRadii radii;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: FamilyCalendarKeys.headerCard,
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
              l10n.familyCalendarHijriDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.familyCalendarGregorianDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PrayerChip(label: l10n.familyCalendarPrayerFajr, colors: colors),
                _PrayerChip(label: l10n.familyCalendarPrayerDhuhr, colors: colors),
                _PrayerChip(label: l10n.familyCalendarPrayerAsr, colors: colors),
                _PrayerChip(
                  label: l10n.familyCalendarPrayerMaghrib,
                  colors: colors,
                ),
                _PrayerChip(label: l10n.familyCalendarPrayerIsha, colors: colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({required this.label, required this.colors});

  final String label;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: colors.ink2,
        ),
      ),
    );
  }
}

class _MonthGridCard extends StatelessWidget {
  const _MonthGridCard({
    required this.l10n,
    required this.colors,
    required this.radii,
    required this.month,
    required this.events,
    required this.monthTitle,
    required this.colorForKey,
  });

  final AppLocalizations l10n;
  final FamilyColors colors;
  final FamilyRadii radii;
  final FamilyCalendarMonthGrid month;
  final List<FamilyCalendarEvent> events;
  final String monthTitle;
  final Color Function(String colorKey) colorForKey;

  @override
  Widget build(BuildContext context) {
    final weekdays = [
      l10n.familyCalendarWeekdaySun,
      l10n.familyCalendarWeekdayMon,
      l10n.familyCalendarWeekdayTue,
      l10n.familyCalendarWeekdayWed,
      l10n.familyCalendarWeekdayThu,
      l10n.familyCalendarWeekdayFri,
      l10n.familyCalendarWeekdaySat,
    ];

    return DecoratedBox(
      key: FamilyCalendarKeys.monthGrid,
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
              monthTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final day in weekdays)
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.ink2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                // Prototype: `const d = x - 6` with firstDayOffset 6.
                final day = index - month.firstDayOffset;
                if (day < 1 || day > month.daysInMonth) {
                  return const SizedBox.shrink();
                }
                final isToday = day == month.todayDay;
                final hasEvent = month.eventDays.contains(day);
                FamilyCalendarEvent? event;
                for (final e in events) {
                  if (e.day == day) {
                    event = e;
                    break;
                  }
                }
                final dotColor = isToday
                    ? colors.surface
                    : (event != null
                          ? colorForKey(event.colorKey)
                          : colors.p500);

                return _DayCell(
                  cellKey: FamilyCalendarKeys.dayCell(day),
                  day: day,
                  isToday: isToday,
                  hasEvent: hasEvent,
                  dotColor: dotColor,
                  colors: colors,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cellKey,
    required this.day,
    required this.isToday,
    required this.hasEvent,
    required this.dotColor,
    required this.colors,
  });

  final Key cellKey;
  final int day;
  final bool isToday;
  final bool hasEvent;
  final Color dotColor;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: cellKey,
      decoration: BoxDecoration(
        color: isToday ? colors.p500 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? colors.surface : colors.ink,
            ),
          ),
          if (hasEvent)
            Positioned(
              bottom: 3,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.rowKey,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.colors,
  });

  final Key rowKey;
  final String title;
  final String subtitle;
  final Color color;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.ink2,
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
