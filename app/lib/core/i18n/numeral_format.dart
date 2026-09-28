/// VX-B3 · D5 — Western digits everywhere (Owner OD-05).
///
/// Arabic UI still uses Arabic copy; numerals stay 0–9 (not Eastern ٠–٩).
library;

/// Formats [value] with Western digits only (no Eastern Arabic-Indic digits).
String formatAppNumber(num value) => value.toString();

/// Formats a non-negative int with Western digits.
String formatAppInt(int value) => value.toString();

/// Converts any Eastern Arabic-Indic digits in [raw] to Western 0–9.
String toWesternDigits(String raw) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final code in raw.runes) {
    final ch = String.fromCharCode(code);
    final i = eastern.indexOf(ch);
    buf.write(i < 0 ? ch : '$i');
  }
  return buf.toString();
}

/// @deprecated Prefer [formatAppInt] — Eastern digits are no longer used (D5).
String toEasternDigits(int value) => formatAppInt(value);
