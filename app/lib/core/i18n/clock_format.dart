/// How a wall clock is written in this app — and the only place that decides it.
///
/// A time is a number, so it wears the digits this family chose for every other number
/// ([formatAppIntPadded] in `numeral_format.dart`). And it follows the device's own 24-hour
/// setting, because a parent whose phone reads 22:00 must not find their quiet hours written
/// "10:00 م" by an app that guessed.
///
/// Before this file, each screen formatted a clock by hand — `DateFormat.Hm(locale)` in the chat
/// screens, `padLeft(2, '0')` in the safe-zone editor — so the same 22:00 could appear as `22:00`,
/// as `١٠:٠٠ م`, or as `10:00 PM` depending on which screen you were standing on, and the family's
/// digit choice was silently ignored by all of them. Those hand-rolled formatters are the second
/// truth this file exists to close; screens adopt it as they are touched (§٥ of
/// `docs/real_platform/08_FAMILY_CUSTOMIZATION_PROGRAMME.md`).
///
/// The meridiem words come from the message catalog, never from a hard-coded "AM"/"ص" here: a
/// string that skips the catalog is a string a family cannot translate.
library;

import 'package:flutter/material.dart';

import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/i18n/numeral_format.dart';

/// [time] as this family reads clocks: their digits, their hour cycle, their meridiem words.
String formatFamilyClock(BuildContext context, TimeOfDay time) {
  final twentyFour =
      MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
  final minutes = formatAppIntPadded(time.minute);
  if (twentyFour) {
    return '${formatAppIntPadded(time.hour)}:$minutes';
  }
  final l10n = AppLocalizations.of(context);
  final displayHour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final meridiem = time.hour < 12 ? l10n.settingsClockAm : l10n.settingsClockPm;
  return '$displayHour:$minutes $meridiem';
}

/// A time the family has not chosen yet, said out loud instead of faked with a plausible default.
///
/// Callers that show an unset window must not print `00:00` — a screen that invents a time is how
/// a parent ends up saving a quiet hour they never picked.
String formatFamilyClockOrUnset(BuildContext context, TimeOfDay? time) {
  if (time != null) return formatFamilyClock(context, time);
  return AppLocalizations.of(context).notificationPrefsTimeUnset;
}
