import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/i18n/numeral_format.dart';

/// VX-B3 · the family's own digits.
///
/// This file used to be the gate for a different decision: Western digits everywhere, for every
/// family (OD-05). The owner opened that choice on 2026-10-26, so the law this file holds is now
/// the narrower and more important one — there is exactly one road from a family's answer to what
/// their screens draw, and everything still looks the same to a family that never chose anything.
///
/// Two things would break this and neither is caught by a widget test: a screen that formats a
/// number beside this file, and a build that reads an unset policy as "eastern". Both are pinned
/// below.
void main() {
  tearDown(AppNumerals.clearFamilyChoice);

  test('a family that chose nothing sees the app’s own default: Western', () {
    expect(formatAppInt(84), '84');
    expect(formatAppNumber(9.5), '9.5');
    expect(formatAppInt(0), '0');
    expect(AppNumerals.system, AppNumeralSystem.western);
  });

  test('the stored choice is what changes the digits — and nothing else', () {
    AppNumerals.applyFamilyChoice(AppNumeralSystem.eastern);
    expect(formatAppInt(84), '٨٤');
    expect(formatAppNumber(9.5), '٩.٥', reason: 'the separator is not a digit');
    expect(formatAppInt(1024), '١٠٢٤');

    AppNumerals.applyFamilyChoice(AppNumeralSystem.western);
    expect(formatAppInt(84), '84');
  });

  test('an unknown word on the wire never becomes a third renderer', () {
    expect(AppNumeralSystem.parse('eastern'), AppNumeralSystem.eastern);
    // A value this build has no renderer for falls back to the default rather than being guessed
    // at — the server will not store one, so this is about a build that is older than the field.
    expect(AppNumeralSystem.parse('arabic-indic'), AppNumeralSystem.western);
    expect(AppNumeralSystem.parse(null), AppNumeralSystem.western);
  });

  test('input is normalised whether or not the family writes in Eastern digits', () {
    expect(toWesternDigits('٨٤٪'), '84٪');
    expect(toWesternDigits('١ س ٤٦ د'), '1 س 46 د');
    expect(toWesternDigits('9:30'), '9:30');
    AppNumerals.applyFamilyChoice(AppNumeralSystem.eastern);
    expect(toWesternDigits('٩٩'), '99',
        reason: 'parsing a keypad is not a rendering decision');
  });

  test('the preview writer is explicit, so a choice can be shown before it is made', () {
    expect(toEasternDigits(14), '١٤');
    expect(formatAppInt(14), '14',
        reason: 'showing both options must not change the family’s own answer');
  });
}
