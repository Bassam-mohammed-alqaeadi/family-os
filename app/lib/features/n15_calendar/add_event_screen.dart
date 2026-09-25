import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/role_controller.dart';
import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/data/stage1_row_vocabulary.dart';
import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/identity/identity_scope.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/features/n15_calendar/add_event_models.dart';
import 'package:family_os/features/n15_calendar/add_event_repository.dart';
import 'package:family_os/features/n15_calendar/calendar_ux_bridge.dart';

/// Widget keys for SCR-FAT-053 acceptance.
abstract final class AddEventKeys {
  static const screen = Key('add_event_screen');
  static const loading = Key('add_event_loading');
  static const empty = Key('add_event_empty');
  static const body = Key('add_event_body');
  static const titleField = Key('add_event_title_field');
  static const categorySection = Key('add_event_category');
  static const categoryDin = Key('add_event_cat_din');
  static const categoryOcc = Key('add_event_cat_occ');
  static const categorySch = Key('add_event_cat_sch');
  static const categoryAct = Key('add_event_cat_act');
  static const calendarSection = Key('add_event_calendar');
  static const calendarHijri = Key('add_event_cal_hijri');
  static const calendarGregorian = Key('add_event_cal_gregorian');
  static const dateField = Key('add_event_date');
  static const timeSection = Key('add_event_time');
  static const timeMaghrib = Key('add_event_time_maghrib');
  static const timeIsha = Key('add_event_time_isha');
  static const timeSpecific = Key('add_event_time_specific');
  static const placeField = Key('add_event_place');
  static const reminderSection = Key('add_event_reminder');
  static const whoSection = Key('add_event_who');
  static const weeklySwitch = Key('add_event_weekly');
  static const saveCta = Key('add_event_save');
  static const observerHint = Key('add_event_observer');
  static const childLean = Key('add_event_child_lean');
  static const sosIconCta = Key('add_event_sos_icon');
}

/// SCR-FAT-053 — إضافة حدث (add family calendar event).
///
/// Prototype FAT-053 · calendar wave · Rule 12/23 · mother levels ·
/// mock-first · ARB · P-4 SOS · CTA → FAT-052 calendar on save.
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({
    super.key,
    this.repository,
    this.sosFire,
    this.roleOverride,
    this.motherLevel = MotherLevel.partner,
    this.onSos,
    this.onNavigate,
  });

  /// Rule 25 seam — null → [stage1AddEventRepository].
  final AddEventRepository? repository;

  /// P-4 SOS seam — null → [stage1SosFireService].
  final SosFireService? sosFire;

  /// Test seam — when set, ignores [CurrentRole].
  final AppRole? roleOverride;

  /// Mother authority — observer view-only; partner/full may save.
  final MotherLevel motherLevel;

  final VoidCallback? onSos;

  /// Test seam — intercepts navigation by screen id.
  final void Function(String screenId)? onNavigate;

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  late AddEventRepository _repo;
  late final SosFireService _sos;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _placeCtrl;
  var _sosBusy = false;
  var _loading = true;
  var _saveBusy = false;
  AddEventSnapshot _snap = const AddEventSnapshot();
  AddEventDraft _draft = const AddEventDraft();

  AppRole get _role {
    final override = widget.roleOverride;
    if (override != null) return override;
    return CurrentRole.maybeNotifierOf(context)?.value ?? AppRole.father;
  }

  bool get _isChild => _role == AppRole.child;

  bool get _isParent => _role == AppRole.father || _role == AppRole.mother;

  bool get _isObserverMother =>
      _role == AppRole.mother && widget.motherLevel == MotherLevel.observer;

  /// Father always; mother partner/full may save (prototype §7).
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
    _repo = widget.repository ?? stage1AddEventRepository;
    _sos = widget.sosFire ?? stage1SosFireService;
    _titleCtrl = TextEditingController();
    _placeCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AddEventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repo = widget.repository ?? stage1AddEventRepository;
      _load();
    }
  }

  /// The real save path, unless a test injects a repository.
  Future<AddEventRepository> _resolveRepo() async {
    final injected = widget.repository;
    if (injected != null) return injected;
    final identity = CurrentIdentity.maybeOf(context);
    final familyId = identity?.activeFamilyId.value ?? '';
    final accountId = identity?.account.id.value;
    await Stage1CalendarRuntime.ensureOpen();
    return Stage1CalendarRuntime.addEvent(
      familyId: familyId,
      createdByAccount: accountId,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final resolved = await _resolveRepo();
    if (!mounted) return;
    _repo = resolved;
    final snap = await _repo.load();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final seededTitle = snap.draft.title.trim().isEmpty
        ? l10n.addEventDefaultTitleSample
        : snap.draft.title;
    _titleCtrl.text = seededTitle;
    _placeCtrl.text = snap.draft.place;
    setState(() {
      _snap = snap;
      _draft = snap.draft.copyWith(title: seededTitle);
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
    AppToast.show(context, message: l10n.addEventObserverBlocked);
  }

  String _whoLabel(AppLocalizations l10n, String nameKey) {
    return switch (nameKey) {
      'childOne' => l10n.addEventWhoChildOne,
      'childTwo' => l10n.addEventWhoChildTwo,
      'childThree' => l10n.addEventWhoChildThree,
      'mother' => l10n.addEventWhoMother,
      'everyone' => l10n.addEventWhoEveryone,
      // A real event may name a fourth child or the parents: show the stored
      // value instead of a different person.
      _ => nameKey.isEmpty ? l10n.addEventWhoChildOne : nameKey,
    };
  }

  String _dateDisplay(AppLocalizations l10n) {
    return switch (_draft.dateDisplayKey) {
      'hijriSample' => l10n.addEventDateHijriSample,
      'gregorianSample' => l10n.addEventDateGregorianSample,
      _ => l10n.addEventDateHijriSample,
    };
  }

  String _dateConversion(AppLocalizations l10n) {
    return switch (_draft.dateConversionKey) {
      'gregorianSample' => l10n.addEventDateConversionSample,
      _ => l10n.addEventDateConversionSample,
    };
  }

  void _onCalendarType(AddEventCalendarType type) {
    if (_draft.calendarType == type) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _draft = _draft.copyWith(calendarType: type));
    AppToast.show(
      context,
      message: type == AddEventCalendarType.hijri
          ? l10n.addEventCalendarHijriToast
          : l10n.addEventCalendarGregorianToast,
    );
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    if (!_canAct) {
      _blockedToast(l10n);
      return;
    }
    if (_saveBusy) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, message: l10n.addEventTitleEmptyToast);
      return;
    }
    setState(() => _saveBusy = true);
    final draft = _draft.copyWith(
      title: title,
      place: _placeCtrl.text.trim(),
    );
    final snap = await _repo.saveEvent(draft);
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _draft = snap.draft;
      _saveBusy = false;
    });
    AppToast.show(
      context,
      message: l10n.addEventSavedToast(
        title,
        _whoLabel(l10n, draft.whoNameKey),
      ),
    );
    _go('SCR-FAT-052');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;

    return Scaffold(
      key: AddEventKeys.screen,
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        title: Text(
          l10n.addEventTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.ink,
          ),
        ),
        actions: [
          IconButton(
            key: AddEventKeys.sosIconCta,
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
        key: AddEventKeys.childLean,
        title: l10n.addEventChildLeanTitle,
        message: l10n.addEventChildLeanMessage,
        actionLabel: l10n.addEventSosCta,
        onAction: _sosBusy ? null : _openSos,
      );
    }

    if (_loading) {
      return Center(
        key: AddEventKeys.loading,
        child: Semantics(
          label: l10n.addEventLoadingSemantics,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_snap.isEmpty) {
      return AppEmptyState(
        key: AddEventKeys.empty,
        title: l10n.addEventEmptyTitle,
        message: l10n.addEventEmptyMessage,
        actionLabel: l10n.addEventEmptyCta,
        onAction: () => _go('SCR-FAT-003'),
      );
    }

    final radii = Theme.of(context).extension<FamilyRadii>()!;

    return SingleChildScrollView(
      key: AddEventKeys.body,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isObserverMother) ...[
            BannerNote(
              key: AddEventKeys.observerHint,
              variant: BannerVariant.a,
              message: l10n.addEventObserverHint,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.addEventTitleLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: AddEventKeys.titleField,
            controller: _titleCtrl,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
            decoration: InputDecoration(
              hintText: l10n.addEventTitleHint,
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
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            colors: colors,
            radii: radii,
            title: l10n.addEventCategoryHeading,
            childKey: AddEventKeys.categorySection,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CategoryChip(
                  key: AddEventKeys.categoryDin,
                  label: l10n.addEventCategoryDin,
                  icon: '🕌',
                  selected: _draft.category == AddEventCategory.din,
                  colors: colors,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(
                      category: AddEventCategory.din,
                    ),
                  ),
                ),
                _CategoryChip(
                  key: AddEventKeys.categoryOcc,
                  label: l10n.addEventCategoryOcc,
                  icon: '🎂',
                  selected: _draft.category == AddEventCategory.occ,
                  colors: colors,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(
                      category: AddEventCategory.occ,
                    ),
                  ),
                ),
                _CategoryChip(
                  key: AddEventKeys.categorySch,
                  label: l10n.addEventCategorySch,
                  icon: '🏫',
                  selected: _draft.category == AddEventCategory.sch,
                  colors: colors,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(
                      category: AddEventCategory.sch,
                    ),
                  ),
                ),
                _CategoryChip(
                  key: AddEventKeys.categoryAct,
                  label: l10n.addEventCategoryAct,
                  icon: '⚽',
                  selected: _draft.category == AddEventCategory.act,
                  colors: colors,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(
                      category: AddEventCategory.act,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            colors: colors,
            radii: radii,
            title: l10n.addEventDateHeading,
            childKey: AddEventKeys.calendarSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ToggleBtn(
                        key: AddEventKeys.calendarHijri,
                        label: l10n.addEventCalendarHijri,
                        selected: _draft.calendarType == AddEventCalendarType.hijri,
                        colors: colors,
                        onTap: () => _onCalendarType(AddEventCalendarType.hijri),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleBtn(
                        key: AddEventKeys.calendarGregorian,
                        label: l10n.addEventCalendarGregorian,
                        selected:
                            _draft.calendarType == AddEventCalendarType.gregorian,
                        colors: colors,
                        onTap: () =>
                            _onCalendarType(AddEventCalendarType.gregorian),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  key: AddEventKeys.dateField,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateDisplay(l10n),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateConversion(l10n),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.addEventTimeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            key: AddEventKeys.timeSection,
            spacing: 6,
            runSpacing: 6,
            children: [
              _TimeChip(
                key: AddEventKeys.timeMaghrib,
                label: l10n.addEventTimeAfterMaghrib,
                selected: _draft.timeOption == AddEventTimeOption.afterMaghrib,
                colors: colors,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(
                    timeOption: AddEventTimeOption.afterMaghrib,
                  ),
                ),
              ),
              _TimeChip(
                key: AddEventKeys.timeIsha,
                label: l10n.addEventTimeAfterIsha,
                selected: _draft.timeOption == AddEventTimeOption.afterIsha,
                colors: colors,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(
                    timeOption: AddEventTimeOption.afterIsha,
                  ),
                ),
              ),
              _TimeChip(
                key: AddEventKeys.timeSpecific,
                label: l10n.addEventTimeSpecific,
                selected: _draft.timeOption == AddEventTimeOption.specific,
                colors: colors,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(
                    timeOption: AddEventTimeOption.specific,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addEventPlaceLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: AddEventKeys.placeField,
            controller: _placeCtrl,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
            decoration: InputDecoration(
              hintText: l10n.addEventPlaceHint,
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
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addEventReminderLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<AddEventReminder>(
            key: AddEventKeys.reminderSection,
            initialValue: _draft.reminder,
            decoration: InputDecoration(
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
                vertical: 4,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: AddEventReminder.atTime,
                child: Text(l10n.addEventReminderAtTime),
              ),
              DropdownMenuItem(
                value: AddEventReminder.fifteenMin,
                child: Text(l10n.addEventReminderFifteenMin),
              ),
              DropdownMenuItem(
                value: AddEventReminder.oneHour,
                child: Text(l10n.addEventReminderOneHour),
              ),
              DropdownMenuItem(
                value: AddEventReminder.oneDay,
                child: Text(l10n.addEventReminderOneDay),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _draft = _draft.copyWith(reminder: v));
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addEventWhoLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: AddEventKeys.whoSection,
            initialValue: _draft.whoNameKey,
            decoration: InputDecoration(
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
                vertical: 4,
              ),
            ),
            // The family's real children, by ordinal, then the shared lanes.
            items: [
              for (var i = 0; i < _snap.children.length; i++)
                Stage1RowVocabulary.childKeyFor(i),
              'mother',
              'everyone',
            ].map((key) {
              return DropdownMenuItem(
                value: key,
                child: Text(_whoLabel(l10n, key)),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _draft = _draft.copyWith(whoNameKey: v));
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: AddEventKeys.weeklySwitch,
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.addEventWeeklyRepeat,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            value: _draft.weeklyRepeat,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(weeklyRepeat: v)),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            key: AddEventKeys.saveCta,
            label: l10n.addEventSaveCta,
            onPressed: _saveBusy ? null : _onSave,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.colors,
    required this.radii,
    required this.title,
    required this.childKey,
    required this.child,
  });

  final FamilyColors colors;
  final FamilyRadii radii;
  final String title;
  final Key childKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            KeyedSubtree(key: childKey, child: child),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.mint : colors.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.mint : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            '$icon $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? colors.mintInk : colors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.mint : colors.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.mint : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.mintInk : colors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final FamilyColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.p100 : colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.p500 : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.p700 : colors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
