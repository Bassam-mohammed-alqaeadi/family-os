// The guardian's control surface, split into cards a parent can actually operate
// (SCR-FAT-032 · screen-time polish wave).
//
// These widgets are deliberately dumb: they take strings the panel resolved from ARB and
// callbacks that go to the server, and they paint. That is what makes the polish safe to ship —
// the state machine, the idempotency keys and the "the server answered, so this is the truth"
// rules all stay in `screen_time_server_panel.dart`, where the existing acceptance tests pin
// them, and a card cannot quietly invent a number behind a parent's back.
//
// Two rules this file keeps without exception:
//
//   * no indeterminate progress indicators. A `CircularProgressIndicator` with a null value
//     repaints forever, and every test in this feature settles the tree with `pumpAndSettle`.
//     The in-flight state is therefore *words* — which is also what a parent needs to read;
//   * every control answers to `enabled`, and `enabled == false` means `onPressed: null` on
//     the widget itself, because the panel's read-only rule is that single check and a card
//     may not add a second, softer one (a greyed button that still writes is a bug waiting).
import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/app_card.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/foundation_gate/family_screen_time_api_client.dart';

/// Quick and custom extra minutes, beside the number they change.
///
/// The three presets stay exactly the three the contract already answers for; the custom field
/// opens a sheet rather than pretending a text box on a card is a safe way to type a number
/// while a child is waiting.
class ScreenTimeExtensionCard extends StatelessWidget {
  const ScreenTimeExtensionCard({
    super.key,
    required this.title,
    required this.hint,
    required this.presets,
    required this.customLabel,
    required this.onGrant,
    required this.onCustom,
    required this.enabled,
    this.busyLabel,
  });

  final String title;
  final String hint;

  /// Minutes → the words for that button, already localized (e.g. "+15 دقيقة").
  final Map<int, String> presets;
  final String customLabel;
  final void Function(int minutes) onGrant;
  final VoidCallback onCustom;
  final bool enabled;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return _PanelCard(
      cardKey: const Key('screen_time_server_quick_grant_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          if (busyLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              busyLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.tealDeep,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in presets.entries)
                OutlinedButton(
                  key: Key('screen_time_server_quick_grant_${entry.key}'),
                  onPressed: enabled ? () => onGrant(entry.key) : null,
                  child: Text(entry.value),
                ),
              OutlinedButton.icon(
                key: const Key('screen_time_server_custom_grant'),
                onPressed: enabled ? onCustom : null,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(customLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The instant lock, with the answer it got.
///
/// The button label is the panel's, and so is the sentence: what appears after a press is the
/// server's reply, never the intent. The `since` line is only ever the server's own `lockedAt`
/// formatted — this card has no clock of its own, and no claim to make about a phone.
class ScreenTimeLockControlCard extends StatelessWidget {
  const ScreenTimeLockControlCard({
    super.key,
    required this.title,
    required this.stateLine,
    required this.buttonLabel,
    required this.live,
    required this.enabled,
    required this.onToggle,
    this.sinceLine,
    this.confirmedLabel,
    this.busyLabel,
    this.releaseNote,
  });

  final String title;
  final String stateLine;
  final String buttonLabel;
  final bool live;
  final bool enabled;
  final VoidCallback onToggle;
  final String? sinceLine;
  final String? confirmedLabel;
  final String? busyLabel;
  final String? releaseNote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final accent = live ? colors.coral : colors.teal600;
    return _PanelCard(
      cardKey: const Key('screen_time_server_lock_card'),
      backgroundColor: live ? colors.coral100 : null,
      borderColor: live ? colors.coral : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                live ? Icons.lock : Icons.lock_open,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.3,
                  ),
                ),
              ),
              if (confirmedLabel != null && live) ...[
                const SizedBox(width: 6),
                _StatusPill(label: confirmedLabel!, color: accent),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stateLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.4,
            ),
          ),
          if (sinceLine != null) ...[
            const SizedBox(height: 4),
            Text(
              sinceLine!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.4,
              ),
            ),
          ],
          if (busyLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              busyLabel!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.tealDeep,
                height: 1.4,
              ),
            ),
          ],
          if (releaseNote != null) ...[
            const SizedBox(height: 4),
            Text(
              releaseNote!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 10),
          PrimaryBtn(
            key: const Key('screen_time_server_lock_button'),
            label: buttonLabel,
            variant: live ? PrimaryBtnVariant.teal : PrimaryBtnVariant.coral,
            onPressed: enabled ? onToggle : null,
          ),
        ],
      ),
    );
  }
}

/// Today's consumption, as the server counted it — per app, not per wish.
///
/// The bars are shares of the day the server reported. The app id is drawn as the handset
/// reported it, because a friendly label this build invented would be a second source of
/// truth; the app-rules sheet is where a display name arrives, with the rest of the record.
class ScreenTimeInsightsCard extends StatelessWidget {
  const ScreenTimeInsightsCard({
    super.key,
    required this.title,
    required this.usedLabel,
    required this.capLabel,
    required this.grantedLabel,
    required this.hint,
    required this.topLabel,
    required this.emptyLabel,
    required this.overCapLabel,
    required this.shareLabel,
    required this.minutesLabel,
    required this.unlimitedLabel,
    required this.usedMinutes,
    required this.capMinutes,
    required this.grantedMinutes,
    required this.usageByApp,
    this.onOpenApps,
    this.openAppsLabel,
  });

  final String title;
  final String usedLabel;
  final String capLabel;
  final String grantedLabel;
  final String hint;
  final String topLabel;
  final String emptyLabel;
  final String overCapLabel;
  final String Function(int minutes) shareLabel;
  final String Function(int minutes) minutesLabel;
  final String unlimitedLabel;
  final int usedMinutes;
  final int capMinutes;
  final int grantedMinutes;
  final List<FoundationGateAppUsage> usageByApp;
  final VoidCallback? onOpenApps;
  final String? openAppsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final total = capMinutes + grantedMinutes;
    final ranked = <FoundationGateAppUsage>[
      ...usageByApp.where((usage) => usage.usedMinutes > 0),
    ]..sort((a, b) => b.usedMinutes.compareTo(a.usedMinutes));
    final shown = ranked.length <= 4 ? ranked : ranked.sublist(0, 4);
    return _PanelCard(
      cardKey: const Key('screen_time_server_insights_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InsightStat(
                  label: usedLabel,
                  value: minutesLabel(usedMinutes),
                  tint: colors.p100,
                  ink: colors.p700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsightStat(
                  label: capLabel,
                  value: capMinutes > 0
                      ? minutesLabel(capMinutes)
                      : unlimitedLabel,
                  tint: colors.teal100,
                  ink: colors.tealDeep,
                ),
              ),
              if (grantedMinutes > 0) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _InsightStat(
                    label: grantedLabel,
                    value: minutesLabel(grantedMinutes),
                    tint: colors.amber100,
                    ink: colors.amberDeep,
                  ),
                ),
              ],
            ],
          ),
          if (total > 0 && usedMinutes > total) ...[
            const SizedBox(height: 8),
            Text(
              overCapLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.coral,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Text(
              emptyLabel,
              key: const Key('screen_time_server_insights_empty'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.ink2,
                height: 1.45,
              ),
            )
          else ...[
            Text(
              topLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.ink2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            for (final usage in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UsageRow(
                  name: usage.appId,
                  minutes: minutesLabel(usage.usedMinutes),
                  share: shareLabel(
                    total > 0
                        ? (usage.usedMinutes / total * 100).round()
                        : 0,
                  ),
                  fraction: total > 0
                      ? (usage.usedMinutes / total).clamp(0.0, 1.0)
                      : (usage.usedMinutes > 0 ? 1.0 : 0.0),
                  color: colors.p500,
                ),
              ),
          ],
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          if (onOpenApps != null && openAppsLabel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('screen_time_server_insights_open_apps'),
                onPressed: onOpenApps,
                icon: const Icon(Icons.apps, size: 18),
                label: Text(openAppsLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The week: which days school mode runs on, and the one bedtime window the family owns.
///
/// The day chips are a draft with a save button on purpose. `schoolDays` is a set, not a
/// switch, and writing seven times because a parent tapped seven chips would be seven
/// idempotency keys for one decision — and one more way to lose a race with another guardian.
class ScreenTimeWeekScheduleCard extends StatelessWidget {
  const ScreenTimeWeekScheduleCard({
    super.key,
    required this.title,
    required this.schoolModeLabel,
    required this.schoolRangeLine,
    required this.schoolDaysLabel,
    required this.weekdaysLabel,
    required this.weekendLabel,
    required this.dayLabels,
    required this.draftDays,
    required this.savedDays,
    required this.schoolEnabled,
    required this.bedtimeLabel,
    required this.bedtimeLine,
    required this.bedtimeHint,
    required this.weekendLabelLine,
    required this.weekendLine,
    required this.weekendPending,
    required this.bedtimeStartLabel,
    required this.bedtimeEndLabel,
    required this.weekendStartLabel,
    required this.weekendEndLabel,
    required this.saveLabel,
    required this.enabled,
    required this.onToggleDay,
    required this.onToggleSchoolMode,
    required this.onPickBedtimeStart,
    required this.onPickBedtimeEnd,
    required this.onPickWeekendStart,
    required this.onPickWeekendEnd,
    required this.onSaveDays,
    this.weekendWriteLine,
  });

  final String title;
  final String schoolModeLabel;
  final String schoolRangeLine;
  final String schoolDaysLabel;
  final String weekdaysLabel;
  final String weekendLabel;

  /// ISO weekday (Mon = 1 … Sun = 7) → the localized day name.
  final Map<int, String> dayLabels;

  /// The chips as the parent has them now, and as the server last said.
  final Set<int> draftDays;
  final List<int> savedDays;
  final bool schoolEnabled;
  final String bedtimeLabel;

  /// The weekday window the server stores today, already `21:30 – 06:30`.
  final String bedtimeLine;
  final String bedtimeHint;

  /// The heading the weekend row sits under, so the two windows read as a pair.
  final String weekendLabelLine;

  /// The weekend window when the extension carries one — and when it does not, the sentence
  /// that says the family's wish is not stored anywhere yet. Which of the two it is, the
  /// panel decides, because only the panel knows what the source answered.
  final String weekendLine;
  final bool weekendPending;
  final String bedtimeStartLabel;
  final String bedtimeEndLabel;
  final String weekendStartLabel;
  final String weekendEndLabel;

  /// The answer to the last weekend write, or null when nothing was written from this view.
  final String? weekendWriteLine;
  final String saveLabel;
  final bool enabled;
  final void Function(int weekday) onToggleDay;
  final ValueChanged<bool> onToggleSchoolMode;
  final VoidCallback onPickBedtimeStart;
  final VoidCallback onPickBedtimeEnd;
  final VoidCallback onPickWeekendStart;
  final VoidCallback onPickWeekendEnd;
  final VoidCallback onSaveDays;

  bool get _dirty {
    if (draftDays.length != savedDays.length) return true;
    for (final day in savedDays) {
      if (!draftDays.contains(day)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return _PanelCard(
      cardKey: const Key('screen_time_server_week_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('screen_time_server_school_toggle'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: schoolEnabled,
            onChanged: enabled ? onToggleSchoolMode : null,
            title: Text(schoolModeLabel),
            subtitle: Text(schoolRangeLine),
          ),
          const SizedBox(height: 6),
          _DayGroup(
            label: schoolDaysLabel,
            groupLabel: weekdaysLabel,
            days: const [1, 2, 3, 4, 5],
            dayLabels: dayLabels,
            selected: draftDays,
            enabled: enabled,
            onToggle: onToggleDay,
          ),
          const SizedBox(height: 6),
          _DayGroup(
            label: '',
            groupLabel: weekendLabel,
            days: const [6, 7],
            dayLabels: dayLabels,
            selected: draftDays,
            enabled: enabled,
            onToggle: onToggleDay,
          ),
          const SizedBox(height: 10),
          PrimaryBtn(
            key: const Key('screen_time_server_week_save'),
            label: saveLabel,
            variant: PrimaryBtnVariant.sec,
            onPressed: enabled && _dirty ? onSaveDays : null,
          ),
          const SizedBox(height: 12),
          Text(
            bedtimeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bedtimeLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.35,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: const Key('screen_time_server_bedtime_start'),
                  onPressed: enabled ? onPickBedtimeStart : null,
                  icon: const Icon(Icons.nights_stay, size: 16),
                  label: Text(bedtimeStartLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  key: const Key('screen_time_server_bedtime_end'),
                  onPressed: enabled ? onPickBedtimeEnd : null,
                  icon: const Icon(Icons.alarm, size: 16),
                  label: Text(bedtimeEndLabel),
                ),
              ),
            ],
          ),
          Text(
            bedtimeHint,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            weekendLabelLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          if (weekendPending) ...[
            const SizedBox(height: 4),
            _PendingNote(label: weekendLine),
          ] else
            Text(
              weekendLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
                height: 1.35,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: const Key('screen_time_server_weekend_bedtime_start'),
                  onPressed: enabled ? onPickWeekendStart : null,
                  icon: const Icon(Icons.weekend, size: 16),
                  label: Text(weekendStartLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  key: const Key('screen_time_server_weekend_bedtime_end'),
                  onPressed: enabled ? onPickWeekendEnd : null,
                  icon: const Icon(Icons.alarm, size: 16),
                  label: Text(weekendEndLabel),
                ),
              ),
            ],
          ),
          if (weekendWriteLine != null)
            Text(
              weekendWriteLine!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.tealDeep,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

/// The earned-minutes switch, with what each side of it means for today.
///
/// The row itself is the contract's `screen_time_server_earned_minutes_toggle`, unchanged in
/// type and in position; this card only adds the sentence that says which way the day's maths
/// goes. Nothing here wraps the row in a tappable surface, because a card that swallows the
/// tap would be a switch that appears broken.
class ScreenTimeEarnedMinutesCard extends StatelessWidget {
  const ScreenTimeEarnedMinutesCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.hint,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String preview;
  final String hint;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return _PanelCard(
      cardKey: const Key('screen_time_server_earned_minutes_card'),
      backgroundColor: value ? colors.mint100 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('screen_time_server_earned_minutes_toggle'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: enabled ? onChanged : null,
            title: Text(title),
            subtitle: Text(subtitle),
          ),
          Text(
            preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: value ? colors.mintInk : colors.ink2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// The door to the app-rules sheet, so the panel itself still loads with exactly one read.
class ScreenTimeAppsCard extends StatelessWidget {
  const ScreenTimeAppsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    required this.onOpen,
    this.summaryLine,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onOpen;
  final String? summaryLine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return _PanelCard(
      cardKey: const Key('screen_time_server_apps_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.apps, size: 18, color: colors.p600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
              height: 1.45,
            ),
          ),
          if (summaryLine != null) ...[
            const SizedBox(height: 6),
            Text(
              summaryLine!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.tealDeep,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          PrimaryBtn(
            key: const Key('screen_time_server_apps_open'),
            label: actionLabel,
            variant: PrimaryBtnVariant.sec,
            onPressed: enabled ? onOpen : null,
          ),
        ],
      ),
    );
  }
}

/// The daily cap, its quick picks, and the write that saves it.
///
/// The field and the save button stay on one line: `PrimaryBtn.fullWidth` means
/// `width: double.infinity`, and an infinite width inside a `Row` is a layout assertion, not
/// a wide button — which is why the quick picks live below the pair rather than beside it.
class ScreenTimeCapCard extends StatelessWidget {
  const ScreenTimeCapCard({
    super.key,
    required this.title,
    required this.fieldLabel,
    required this.controller,
    required this.errorText,
    required this.saveLabel,
    required this.presetsLabel,
    required this.presetMinutes,
    required this.presetLabel,
    required this.unlimitedLabel,
    required this.selectedMinutes,
    required this.enabled,
    required this.onSave,
    required this.onPickPreset,
  });

  final String title;
  final String fieldLabel;
  final TextEditingController controller;
  final String? errorText;
  final String saveLabel;
  final String presetsLabel;

  /// The quick picks, in minutes. `0` is the unlimited choice and is labelled
  /// [unlimitedLabel] rather than "0", because a parent choosing "no cap" is not choosing a
  /// number that a child could read as "no screen at all".
  final List<int> presetMinutes;
  final String Function(int minutes) presetLabel;
  final String unlimitedLabel;
  final int? selectedMinutes;
  final bool enabled;
  final VoidCallback onSave;
  final void Function(int minutes) onPickPreset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return _PanelCard(
      cardKey: const Key('screen_time_server_policy_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('screen_time_server_cap_field'),
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: fieldLabel,
                    errorText: errorText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // `Flexible`, so the field keeps its share and the button gives up width instead
              // of pushing the row past the card: at textScale 2.0 on a small phone the save
              // label wraps onto a second line rather than overflowing the card.
              Flexible(
                child: PrimaryBtn(
                  key: const Key('screen_time_server_cap_save'),
                  fullWidth: false,
                  label: saveLabel,
                  onPressed: enabled ? onSave : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            presetsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: colors.ink2,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in presetMinutes)
                _PresetChip(
                  key: Key('screen_time_server_cap_preset_$minutes'),
                  label: minutes == 0
                      ? unlimitedLabel
                      : presetLabel(minutes),
                  selected: selectedMinutes == minutes,
                  enabled: enabled,
                  onTap: () => onPickPreset(minutes),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ask for a number of minutes the presets do not cover.
///
/// Returns the minutes, or null when the parent closed the sheet. Validation happens before
/// anything is sent: an invalid number never reaches the server, and the field says why.
Future<int?> showScreenTimeCustomGrantSheet(
  BuildContext context, {
  required String title,
  required String helper,
  required String confirmLabel,
  required String invalidLabel,
  List<int> presets = const [5, 10, 15, 30, 45, 60],
  int initialMinutes = 15,
  int minimum = 1,
  int maximum = 240,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _CustomGrantSheet(
        title: title,
        helper: helper,
        confirmLabel: confirmLabel,
        invalidLabel: invalidLabel,
        presets: presets,
        initialMinutes: initialMinutes,
        minimum: minimum,
        maximum: maximum,
      ),
    ),
  );
}

class _CustomGrantSheet extends StatefulWidget {
  const _CustomGrantSheet({
    required this.title,
    required this.helper,
    required this.confirmLabel,
    required this.invalidLabel,
    required this.presets,
    required this.initialMinutes,
    required this.minimum,
    required this.maximum,
  });

  final String title;
  final String helper;
  final String confirmLabel;
  final String invalidLabel;
  final List<int> presets;
  final int initialMinutes;
  final int minimum;
  final int maximum;

  @override
  State<_CustomGrantSheet> createState() => _CustomGrantSheetState();
}

class _CustomGrantSheetState extends State<_CustomGrantSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initialMinutes}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null ||
        parsed < widget.minimum ||
        parsed > widget.maximum) {
      setState(() => _error = widget.invalidLabel);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('screen_time_server_custom_grant_field'),
              controller: _controller,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                helperText: widget.helper,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in widget.presets)
                  _PresetChip(
                    key: Key(
                      'screen_time_server_custom_grant_preset_$minutes',
                    ),
                    label: '+$minutes',
                    selected: false,
                    enabled: true,
                    onTap: () => setState(() => _controller.text = '$minutes'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            PrimaryBtn(
              key: const Key('screen_time_server_custom_grant_confirm'),
              label: widget.confirmLabel,
              variant: PrimaryBtnVariant.teal,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The card shell the panel's cards share — [AppCard], so the radius, the border and the
/// shadow come from the same tokens as the rest of the app.
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.cardKey,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  final Key cardKey;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: cardKey,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      // `AppCard` paints its surface in a `DecoratedBox`, and a `ListTile` looks for the
      // nearest Material to draw its background and tap splash on - without one here the
      // earned-minutes switch answers a tap with nothing visible, which Flutter reports as an
      // assertion. A transparent Material is the smallest honest fix: the ink lands, and the
      // card keeps the colour the theme gave it.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.35,
        ),
      ),
    );
  }
}

class _InsightStat extends StatelessWidget {
  const _InsightStat({
    required this.label,
    required this.value,
    required this.tint,
    required this.ink,
  });

  final String label;
  final String value;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radii.tcard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: colors.ink2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: ink,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.name,
    required this.minutes,
    required this.share,
    required this.fraction,
    required this.color,
  });

  final String name;
  final String minutes;
  final String share;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              minutes,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.35,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(radii.input / 4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          share,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.label,
    required this.groupLabel,
    required this.days,
    required this.dayLabels,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  /// The heading above the chips, or '' when a second group follows the first one.
  final String label;
  final String groupLabel;
  final List<int> days;
  final Map<int, String> dayLabels;
  final Set<int> selected;
  final bool enabled;
  final void Function(int weekday) onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.isEmpty ? groupLabel : '$label · $groupLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: colors.ink2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final day in days)
              _DayChip(
                key: Key('screen_time_server_day_chip_$day'),
                label: dayLabels[day] ?? '$day',
                selected: selected.contains(day),
                onTap: enabled ? () => onToggle(day) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Semantics(
      button: true,
      enabled: onTap != null,
      toggled: selected,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radii.pill),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? colors.p500 : colors.bg,
              borderRadius: BorderRadius.circular(radii.pill),
              border: Border.all(color: selected ? colors.p600 : colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? colors.surface : colors.ink2,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(radii.pill),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? colors.p100 : colors.p50,
                borderRadius: BorderRadius.circular(radii.pill),
                border: Border.all(
                  color: selected ? colors.p500 : colors.p100,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 34,
                  minWidth: 44,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.p700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A line that says "the contract cannot hold this yet", in the panel's own amber.
///
/// This is not a stub notice and not an apology: it is the panel telling a parent which wish
/// is currently stored where, so the wish is not mistaken for a setting that was ignored.
class _PendingNote extends StatelessWidget {
  const _PendingNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.amber100,
        borderRadius: BorderRadius.circular(radii.banner),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: colors.amberDeep),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.amberDeep,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
