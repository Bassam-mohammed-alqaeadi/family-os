import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Local mirror of the generator's rules for the committed l10n source.
///
/// `flutter gen-l10n` is the only writer of `app_localizations*.dart`, and CI refuses a diff
/// between those files and the generator's output. That gate is correct and it is also nine
/// minutes away: this environment has no Flutter, so a hand-written key that is right in
/// substance but wrong in shape costs a push and a wait to learn something a parser can see
/// in a second.
///
/// The two rules here were read off the generated files rather than guessed. Over the 6636
/// plain messages in both languages, exactly these hold:
///
///   * every message in the ARB files is declared in the abstract class and implemented in
///     both language files, and the two ARB files carry the same key set;
///   * a plain message is written on one line when `  String get key => 'value';` is at most
///     80 units wide, and split after `=>` when it is wider - counting as Dart counts, in
///     UTF-16 code units, so an emoji costs two.
///
/// Messages with placeholders take shapes this file does not model (an int parameter, an ICU
/// plural branch), so for those it asserts presence and leaves the rest to the generator's
/// own gate. That is a deliberate limit, stated rather than hidden: a checker that guessed at
/// shapes it has not seen would fail good code.
void main() {
  final appRoot = _appRoot();
  final arb = <String, Map<String, String>>{
    'ar': _messages(File('${appRoot.path}/lib/core/i18n/app_ar.arb')),
    'en': _messages(File('${appRoot.path}/lib/core/i18n/app_en.arb')),
  };
  final abstractSource = File(
    '${appRoot.path}/lib/core/i18n/app_localizations.dart',
  ).readAsStringSync();

  test('both ARB files carry the same messages', () {
    final ar = arb['ar']!.keys.toSet();
    final en = arb['en']!.keys.toSet();
    expect(
      ar.difference(en),
      isEmpty,
      reason: 'a message the template has and the translation lacks is untranslatable',
    );
    expect(
      en.difference(ar),
      isEmpty,
      reason: 'a message the translation has and the template lacks is unreachable',
    );
  });

  test('every message is declared in the abstract class and implemented twice', () {
    final missingAbstract = <String>[];
    final missingLanguage = <String, List<String>>{};
    for (final entry in arb['ar']!.keys) {
      if (!abstractSource.contains(entry)) missingAbstract.add(entry);
    }
    for (final language in arb.keys) {
      final source = File(
        '${appRoot.path}/lib/core/i18n/app_localizations_$language.dart',
      ).readAsStringSync();
      final missing = <String>[];
      for (final entry in arb[language]!.keys) {
        if (!source.contains(entry)) missing.add(entry);
      }
      missingLanguage[language] = missing;
    }
    expect(missingAbstract, isEmpty, reason: 'declared in the abstract class');
    for (final language in missingLanguage.keys) {
      expect(
        missingLanguage[language],
        isEmpty,
        reason: 'implemented in app_localizations_$language.dart',
      );
    }
  });

  test('every plain message is on one line at 80 units, and split when wider', () {
    final wrong = <String>[];
    for (final language in arb.keys) {
      final source = File(
        '${appRoot.path}/lib/core/i18n/app_localizations_$language.dart',
      ).readAsStringSync();
      for (final entry in arb[language]!.entries) {
        final value = entry.value;
        // Placeholders and multi-line messages take shapes this rule does not describe.
        if (value.contains('{') || value.contains('\n')) continue;
        // Leading or trailing space would not survive the literal verbatim.
        if (value.trim() != value) continue;

        final singleLine = "  String get ${entry.key} => '${_escape(value)}';";
        final fits = _dartWidth(singleLine) <= 80;
        final oneLine = source.contains('$singleLine\n');
        final twoLine = source.contains(
          '  String get ${entry.key} =>\n      \'${_escape(value)}\';\n',
        );
        if (fits && !oneLine) {
          wrong.add(
            '$language: ${entry.key} is ${_dartWidth(singleLine)} units wide and must stay '
            'on one line',
          );
        }
        if (!fits && !twoLine) {
          wrong.add(
            '$language: ${entry.key} is ${_dartWidth(singleLine)} units wide and must be '
            'split after =>',
          );
        }
      }
    }
    expect(
      wrong,
      isEmpty,
      reason:
          'the generator writes these lines; a hand-written copy has to match it\n'
          '${wrong.join('\n')}',
    );
  });
}

/// The message map of one ARB file, without the `@key` metadata entries.
Map<String, String> _messages(File file) {
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return <String, String>{
    for (final entry in decoded.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
}

/// How the generator escapes a message into a single-quoted Dart literal.
///
/// Read off the generated files: a backslash is doubled, a single quote and a double quote
/// are both escaped. The double quote does not have to be - the literal is single-quoted -
/// but the generator escapes it, so a hand-written line has to as well.
String _escape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll("'", "\\'")
    .replaceAll('"', '\\"');

/// Dart's own measure: a string's length is its UTF-16 code units, so an emoji is two.
int _dartWidth(String line) => line.codeUnits.length;

Directory _appRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 4; i++) {
    final marker = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    final arb = File(
      '${dir.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}core${Platform.pathSeparator}i18n'
      '${Platform.pathSeparator}app_ar.arb',
    );
    if (marker.existsSync() && arb.existsSync()) return dir;
    final nested = Directory('${dir.path}${Platform.pathSeparator}app');
    if (File(
      '${nested.path}${Platform.pathSeparator}pubspec.yaml',
    ).existsSync()) {
      return nested;
    }
    dir = dir.parent;
  }
  fail('could not locate the app package root (pubspec.yaml + ARB files)');
}
