/// The app's digits, and the one place a family's own choice is applied to them.
///
/// This file used to carry a rule instead of a reader: Western digits everywhere, decided once for
/// every family (owner decision OD-05). The owner reversed that on 2026-10-26, so the rule is now
/// what a family stored: [AppNumerals] holds their answer, [formatAppInt] and [formatAppNumber]
/// write through it, and nothing else in the app decides how a number looks. A screen that typed
/// its own digits, or called a formatter that bypassed this file, would be a second truth about
/// one family's choice — which is the failure this whole file exists to prevent.
///
/// The default stays Western, so a family that never opened the screen sees exactly what it has
/// always seen. Eastern digits arrive through the family's stored profile, not through a patch.
library;

/// How a family wants its numbers written. The two words are the server's, and the spine allows
/// no third: [AppNumerals] exists so the app has exactly as many renderers as it has values.
enum AppNumeralSystem {
  western('western'),
  eastern('eastern');

  const AppNumeralSystem(this.wire);

  final String wire;

  static AppNumeralSystem parse(Object? value) => values.firstWhere(
    (system) => system.wire == value,
    orElse: () => western,
  );
}

/// The family's answer, held in one place for the whole build.
///
/// Written by exactly one caller: the authority that reads the family's profile off the spine. It
/// is not written by a screen, a toggle, or a local default, and a build with no server leaves it
/// at [AppNumeralSystem.western] because nobody was asked.
abstract final class AppNumerals {
  static AppNumeralSystem _system = AppNumeralSystem.western;

  static AppNumeralSystem get system => _system;

  static bool get isEastern => _system == AppNumeralSystem.eastern;

  /// Apply what this family stored. Called when the spine answers, and after a save.
  static void applyFamilyChoice(AppNumeralSystem value) => _system = value;

  /// The state a signed-out or serverless build must be in: nothing was chosen, so the app's own
  /// default is what stands.
  static void clearFamilyChoice() => _system = AppNumeralSystem.western;
}

const String _easternDigits = '٠١٢٣٤٥٦٧٨٩';

String _mapDigits(String western, {required bool toEastern}) {
  final buf = StringBuffer();
  for (final code in western.runes) {
    final ch = String.fromCharCode(code);
    if (toEastern) {
      final index = ch.codeUnitAt(0) - '0'.codeUnitAt(0);
      buf.write(index >= 0 && index <= 9 ? _easternDigits[index] : ch);
    } else {
      final index = _easternDigits.indexOf(ch);
      buf.write(index < 0 ? ch : '$index');
    }
  }
  return buf.toString();
}

/// Formats [value] in the digits this family chose (Western when they chose nothing).
String formatAppNumber(num value) =>
    _mapDigits(value.toString(), toEastern: AppNumerals.isEastern);

/// Formats [value] in the digits this family chose (Western when they chose nothing).
String formatAppInt(int value) =>
    _mapDigits(value.toString(), toEastern: AppNumerals.isEastern);

/// [value] padded to [width] digits, in the digits this family chose.
///
/// Padding happens on Western digits first, so a family reading `٠٧` gets the leading zero in
/// *their* digits — `formatAppInt(7).padLeft(2, '0')` would hang a Western `0` in front of an
/// Eastern `٧`, which is the mistake this exists to prevent. Clocks and dates are the callers.
String formatAppIntPadded(int value, {int width = 2}) {
  final digits = value.abs().toString().padLeft(width, '0');
  return _mapDigits(
    value < 0 ? '-$digits' : digits,
    toEastern: AppNumerals.isEastern,
  );
}

/// Converts any Eastern Arabic-Indic digits in [raw] to Western 0–9.
///
/// This is the input direction, and it does not consult a family's choice: a field that received
/// `١٢` from a keypad or from an old screenshot is parsed as the number twelve whether or not
/// the family wants their screens written in Eastern digits.
String toWesternDigits(String raw) => _mapDigits(raw, toEastern: false);

/// Writes [value] in Eastern Arabic-Indic digits whatever this family chose.
///
/// One legitimate use: the choice card shows a family what each option looks like *before* they
/// pick it, so both renderings have to be drawable at once. Anything else that wants digits in
/// the family's own shape calls [formatAppInt] instead.
String toEasternDigits(int value) => _mapDigits(
  value.toString(),
  toEastern: true,
);
