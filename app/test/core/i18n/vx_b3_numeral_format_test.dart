import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/i18n/numeral_format.dart';

/// VX-B3 · D5 — Western digits everywhere.
void main() {
  test('formatAppInt / formatAppNumber emit Western digits', () {
    expect(formatAppInt(84), '84');
    expect(formatAppNumber(9.5), '9.5');
    expect(formatAppInt(0), '0');
  });

  test('toWesternDigits converts Eastern Arabic-Indic digits', () {
    expect(toWesternDigits('٨٤٪'), '84٪');
    expect(toWesternDigits('١ س ٤٦ د'), '1 س 46 د');
    expect(toWesternDigits('9:30'), '9:30');
  });

  test('deprecated toEasternDigits aliases Western (D5)', () {
    expect(toEasternDigits(14), '14');
  });
}
