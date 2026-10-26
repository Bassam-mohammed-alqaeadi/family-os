// الطابع العائلة · الغرفة ٢ — the authority, and the states a guardian is told about.
//
// The rule this file holds is the one that separates a real system from a decoration: the
// authority never manufactures an answer. Every state below is either the spine's own reply or a
// sentence about why there is none — and nothing is filled in with the app's defaults behind a
// family's back, with one deliberate exception the last two tests pin: the digits.
//
// That exception is the point of the whole programme. A switch with no engine behind it is the
// decoration this repo refuses to ship, so these tests assert the family's stored choice reaches
// the one reader every number in the app passes through, and that it is forgotten when the session
// that carried it ends.
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/i18n/numeral_format.dart';
import 'package:family_os/features/n12_devices/family_customization_server_authority.dart';
import 'support/family_customization_fake_server.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';

void main() {
  tearDown(() {
    FamilyCustomizationAuthority.bind(null);
    AppNumerals.clearFamilyChoice();
  });

  test('with no family selected nothing is asked, and the reason is a value', () async {
    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine, familyId: null);

    final answer = await authority.read();
    expect(answer.status, FamilyCustomizationStatus.notConfigured);
    expect(answer.profile, isNull);
    expect(spine.calls, isEmpty,
        reason: 'there is nobody to ask, so asking would be theatre');

    final write = await authority.write(
      expectedVersion: 0,
      weekStartDay: FamilyCustomizationDay.thursday,
      idempotencyKey: 'key',
    );
    expect(write.status, FamilyCustomizationStatus.notConfigured);
    expect(spine.calls, isEmpty);
  });

  test('an empty token is not a session', () async {
    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine, idToken: () async => '   ');

    expect((await authority.read()).status,
        FamilyCustomizationStatus.notConfigured);
    expect(spine.calls, isEmpty);
  });

  test('a stored profile reads as the family’s own, and a default reads as a default', () async {
    final stored = familyCustomizationAuthorityFor(
      FamilyCustomizationFakeSpine(stored: true),
    );
    final storedAnswer = await stored.read();
    expect(storedAnswer.isReady, isTrue);
    expect(storedAnswer.profile!.isFamilyChosen, isTrue);
    expect(storedAnswer.profile!.weekStartDay, FamilyCustomizationDay.sunday);

    final fresh = familyCustomizationAuthorityFor(
      FamilyCustomizationFakeSpine(),
    );
    final freshAnswer = await fresh.read();
    expect(freshAnswer.profile!.isFamilyChosen, isFalse);
    expect(freshAnswer.profile!.version, 0);
  });

  test('the family’s digits reach the one reader every number uses', () async {
    expect(AppNumerals.isEastern, isFalse,
        reason: 'before a family is asked, the app’s own default stands');
    expect(formatAppInt(84), '84');

    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine);
    final written = await authority.write(
      expectedVersion: 0,
      numerals: FamilyNumeralSystem.eastern,
      idempotencyKey: 'digits-1',
    );

    expect(written.isReady, isTrue);
    expect(spine.numerals, 'eastern');
    expect(AppNumerals.isEastern, isTrue,
        reason: 'a knob no engine reads is decoration; this one changes what the app prints');
    expect(formatAppInt(84), '٨٤');
    expect(formatAppNumber(9.5), '٩.٥');
  });

  test('a read applies the stored choice too, so a second guardian sees the same digits', () async {
    final spine = FamilyCustomizationFakeSpine();
    final writer = familyCustomizationAuthorityFor(spine);
    await writer.write(
      expectedVersion: 0,
      numerals: FamilyNumeralSystem.eastern,
      idempotencyKey: 'digits-2',
    );

    AppNumerals.clearFamilyChoice();
    expect(formatAppInt(84), '84');

    final reader = familyCustomizationAuthorityFor(spine);
    final answer = await reader.read();
    expect(answer.profile!.numerals, FamilyNumeralSystem.eastern);
    expect(formatAppInt(84), '٨٤');
  });

  test('signing out of the family forgets its digits with it', () async {
    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine);
    await authority.write(
      expectedVersion: 0,
      numerals: FamilyNumeralSystem.eastern,
      idempotencyKey: 'digits-3',
    );
    expect(AppNumerals.isEastern, isTrue);

    FamilyCustomizationAuthority.bind(authority);
    FamilyCustomizationAuthority.bind(null);
    expect(AppNumerals.isEastern, isFalse,
        reason: 'a handset must not keep one family’s choice for the next one to sign in');
    expect(formatAppInt(84), '84');
  });

  test('a stale version comes back named, so the screen reads again instead of insisting', () async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    final authority = familyCustomizationAuthorityFor(spine);

    final answer = await authority.write(
      expectedVersion: 0, // the row is at 3; this screen read it before somebody else wrote
      weekStartDay: FamilyCustomizationDay.wednesday,
      idempotencyKey: 'stale-1',
    );
    expect(answer.status, FamilyCustomizationStatus.refused);
    expect(answer.refusal, FamilyCustomizationRefusal.staleVersion);
    expect(answer.profile, isNull,
        reason: 'the draft on screen was never stored, and must not be shown as if it were');
    expect(spine.weekStartDay, 'sun', reason: 'the family’s real row is untouched');
  });

  test('a co-guardian is told which of the two it is', () async {
    final spine = FamilyCustomizationFakeSpine(isPrimaryGuardian: false);
    final authority = familyCustomizationAuthorityFor(spine);

    final read = await authority.read();
    expect(read.isReady, isTrue, reason: 'any active guardian of this family reads its profile');

    final write = await authority.write(
      expectedVersion: 0,
      weekStartDay: FamilyCustomizationDay.wednesday,
      idempotencyKey: 'co-1',
    );
    expect(write.status, FamilyCustomizationStatus.refused);
    expect(write.refusal, FamilyCustomizationRefusal.notPrimaryGuardian);
  });

  test('the week cannot be emptied here either, and the words keep their own reason', () async {
    final spine = FamilyCustomizationFakeSpine();
    final authority = familyCustomizationAuthorityFor(spine);

    final noRest = await authority.write(
      expectedVersion: 0,
      restDays: const <FamilyCustomizationDay>[],
      idempotencyKey: 'floor-1',
    );
    expect(noRest.refusal, FamilyCustomizationRefusal.noRestDay);

    final longWord = await authority.write(
      expectedVersion: 0,
      labels: const {
        FamilyGuardianLabelKey.father: 'أب رحيم جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      },
      idempotencyKey: 'floor-2',
    );
    expect(longWord.refusal, FamilyCustomizationRefusal.wordRefused);
  });

  test('nobody answering is unreachable; an answer nobody can read is unreadable', () async {
    final silence = FamilyCustomizationFakeSpine()..failure = _ClosedSocket();
    expect((await familyCustomizationAuthorityFor(silence).read()).status,
        FamilyCustomizationStatus.unreachable);

    final nonsense = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"profile":{"weekStartDay":"mon"}}',
      );
    expect((await familyCustomizationAuthorityFor(nonsense).read()).status,
        FamilyCustomizationStatus.unreadable);

    final refused = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 403,
        body: '{"error":{"code":"forbidden","message":"no"}}',
      );
    expect((await familyCustomizationAuthorityFor(refused).read()).status,
        FamilyCustomizationStatus.accessDenied);

    final expired = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 401,
        body: '{"error":{"code":"unauthenticated","message":"no"}}',
      );
    expect((await familyCustomizationAuthorityFor(expired).read()).status,
        FamilyCustomizationStatus.notConfigured,
        reason: 'a session that lapsed is not a family that vanished');
  });

  test('a refusal with no reason is said as silence, not guessed at', () async {
    final spine = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 400,
        body: '{"error":{"code":"something_this_build_has_no_word_for"}}',
      );
    final answer = await familyCustomizationAuthorityFor(spine).write(
      expectedVersion: 0,
      weekStartDay: FamilyCustomizationDay.tuesday,
      idempotencyKey: 'unexplained-1',
    );
    expect(answer.status, FamilyCustomizationStatus.refused);
    expect(answer.refusal, FamilyCustomizationRefusal.unexplained);
  });
}

/// A socket that closed: no status, no body, nobody answered.
class _ClosedSocket implements Exception {}
