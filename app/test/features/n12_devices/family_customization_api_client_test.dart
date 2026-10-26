// الطابع العائلة · الغرفة ٢ — the client that carries a family's answer, and nothing else.
//
// The defects this file exists to catch are the ones a lenient parser ships with:
//
//   * a rest-day list accepted in any order, so two screens disagree about which days are stored;
//   * an unknown word on the wire folded into the default, so a family that chose «eastern» is told
//     they never did;
//   * a fifth label key or a blank one rendered as though it were a word the app agreed to show;
//   * a refusal flattened into "failed", which is the difference between a guardian who can act and
//     one who cannot.
//
// Every assertion is against what the client *returns*, not against how it was written: the fake
// spine stores, so a round trip here is a round trip through the same laws the real one enforces.
import 'package:flutter_test/flutter_test.dart';

import 'support/family_customization_fake_server.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

void main() {
  test('a family that never wrote a profile reads as the app’s default, and says so', () async {
    final spine = FamilyCustomizationFakeSpine();
    final profile = await familyCustomizationClientFor(
      spine,
    ).readProfile(familyId: familyCustomizationFamilyId, idToken: 'token');

    expect(profile.version, 0);
    expect(profile.weekStartDay, FamilyCustomizationDay.monday);
    expect(profile.restDays, [
      FamilyCustomizationDay.friday,
      FamilyCustomizationDay.saturday,
    ]);
    expect(profile.numerals, FamilyNumeralSystem.western);
    expect(profile.labels, isEmpty);
    expect(profile.updatedAt, isNull);
    expect(profile.updatedByMembershipId, isNull);
    expect(profile.isFamilyChosen, isFalse,
        reason: 'a default shown as a decision is the lie this flag exists to prevent');
    expect(spine.calls, ['GET $familyCustomizationPath']);
    expect(spine.lastHeaders!['authorization'], 'Bearer token');
    expect(spine.lastHeaders!['accept'], 'application/json');
  });

  test('the week a family chose is read back in its own order, with the grid rotated to it', () async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    final client = familyCustomizationClientFor(spine);
    final profile = await client.readProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
    );

    expect(profile.weekStartDay, FamilyCustomizationDay.sunday);
    expect(profile.restDays, [FamilyCustomizationDay.friday]);
    expect(profile.isRest(FamilyCustomizationDay.friday), isTrue);
    expect(profile.isRest(FamilyCustomizationDay.saturday), isFalse);
    expect(profile.isFamilyChosen, isTrue);
    expect(profile.updatedAt, isNotNull);
    expect(profile.updatedByMembershipId, familyCustomizationMembershipId);
    expect(
      profile.weekOrder.map((day) => day.wire).toList(),
      ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
      reason: 'a grid must not hardcode Monday to know where this family’s week starts',
    );
    expect(
      FamilyCustomizationDay.friday.indexFrom(profile.weekStartDay),
      5,
    );
  });

  test('a write sends only what changed, at the version it read', () async {
    final spine = FamilyCustomizationFakeSpine();
    final profile = await familyCustomizationClientFor(spine).updateProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
      idempotencyKey: 'key-1',
      expectedVersion: 0,
      weekStartDay: FamilyCustomizationDay.thursday,
    );

    expect(spine.lastBody, {
      'expectedVersion': 0,
      'weekStartDay': 'thu',
    });
    expect(spine.lastHeaders!['idempotency-key'], 'key-1');
    expect(spine.lastHeaders!['content-type'], 'application/json');
    expect(profile.weekStartDay, FamilyCustomizationDay.thursday);
    // The days nobody typed stay where the family left them, because the list replaces only when
    // it is sent at all.
    expect(profile.restDays, [FamilyCustomizationDay.friday, FamilyCustomizationDay.saturday]);
    expect(profile.version, 1);
  });

  test('a rest-day list is sent canonically and read only canonically', () async {
    final spine = FamilyCustomizationFakeSpine();
    await familyCustomizationClientFor(spine).updateProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
      idempotencyKey: 'key-2',
      expectedVersion: 0,
      restDays: const [FamilyCustomizationDay.sunday, FamilyCustomizationDay.wednesday],
    );
    expect(spine.lastBody!['restDays'], ['sun', 'wed']);

    // A spine that answered out of order is a spine this client disagrees with, and the honest
    // answer is a defect report — not a silent re-sort that hides the drift.
    final outOfOrder = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 200,
        body:
            '{"profile":{"version":1,"weekStartDay":"mon","numerals":"western","restDays":["sat","fri"],'
            '"guardianLabels":{},"updatedAt":null,"updatedByMembershipId":null,"source":"family"}}',
      );
    await expectLater(
      familyCustomizationClientFor(outOfOrder).readProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('the family’s own digits round trip through the same two words the database allows', () async {
    final spine = FamilyCustomizationFakeSpine();
    final client = familyCustomizationClientFor(spine);
    final chosen = await client.updateProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
      idempotencyKey: 'key-3',
      expectedVersion: 0,
      numerals: FamilyNumeralSystem.eastern,
    );
    expect(chosen.numerals, FamilyNumeralSystem.eastern);
    expect(spine.numerals, 'eastern');

    final reread = await client.readProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
    );
    expect(reread.numerals, FamilyNumeralSystem.eastern,
        reason: 'the choice belongs to the family, not to the screen that made it');
  });

  test('an emptied word is sent as null, because dropping it is a decision', () async {
    final spine = FamilyCustomizationFakeSpine(stored: true);
    final client = familyCustomizationClientFor(spine);
    final before = await client.readProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
    );
    expect(before.labelFor(FamilyGuardianLabelKey.father), 'بابا');

    final after = await client.updateProfile(
      familyId: familyCustomizationFamilyId,
      idToken: 'token',
      idempotencyKey: 'key-4',
      expectedVersion: before.version,
      labels: const {FamilyGuardianLabelKey.father: null},
    );
    expect(after.labels, isEmpty);
    expect(spine.labels, isEmpty);
    expect(spine.lastBody!['labels'], {'father': null});
  });

  test('a change that changes nothing is refused before it is sent', () async {
    final spine = FamilyCustomizationFakeSpine();
    await expectLater(
      familyCustomizationClientFor(spine).updateProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
        idempotencyKey: 'key-5',
        expectedVersion: 0,
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(spine.calls, isEmpty,
        reason: 'a spinner for a request that must be refused is a guardian’s time spent for nothing');
  });

  test('a stale version and a forbidden writer keep their own names', () async {
    final stale = FamilyCustomizationFakeSpine();
    await expectLater(
      familyCustomizationClientFor(stale).updateProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
        idempotencyKey: 'key-6',
        expectedVersion: 9,
        weekStartDay: FamilyCustomizationDay.wednesday,
      ),
      throwsA(
        isA<FoundationGateApiException>()
            .having((e) => e.failure, 'failure', FoundationGateApiFailure.conflict)
            .having((e) => e.serverCode, 'serverCode', 'customization_stale_version')
            .having((e) => e.statusCode, 'statusCode', 409),
      ),
    );

    final notPrimary = FamilyCustomizationFakeSpine(isPrimaryGuardian: false);
    await expectLater(
      familyCustomizationClientFor(notPrimary).updateProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
        idempotencyKey: 'key-7',
        expectedVersion: 0,
        weekStartDay: FamilyCustomizationDay.wednesday,
      ),
      throwsA(
        isA<FoundationGateApiException>()
            .having((e) => e.failure, 'failure', FoundationGateApiFailure.accessDenied)
            .having(
              (e) => e.serverCode,
              'serverCode',
              'customization_primary_guardian_required',
            ),
      ),
    );
    expect(notPrimary.weekStartDay, 'mon',
        reason: 'a refused write must not have moved the family’s row');
  });

  test('the week cannot be emptied, and the refusal is named not shrug', () async {
    final spine = FamilyCustomizationFakeSpine();
    await expectLater(
      familyCustomizationClientFor(spine).updateProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
        idempotencyKey: 'key-8',
        expectedVersion: 0,
        restDays: const <FamilyCustomizationDay>[],
      ),
      throwsA(
        isA<FoundationGateApiException>()
            .having((e) => e.failure, 'failure', FoundationGateApiFailure.invalidInput)
            .having((e) => e.serverCode, 'serverCode', 'customization_rest_day_required'),
      ),
    );
  });

  test('a word this app has no renderer or no floor for is a defect, not an empty string', () async {
    Future<void> refuses(String profileJson) async {
      final spine = FamilyCustomizationFakeSpine()
        ..forced = FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"profile":$profileJson}',
        );
      await expectLater(
        familyCustomizationClientFor(spine).readProfile(
          familyId: familyCustomizationFamilyId,
          idToken: 'token',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (e) => e.failure,
            'failure',
            FoundationGateApiFailure.invalidResponse,
          ),
        ),
      );
    }

    await refuses(
      '{"version":1,"weekStartDay":"mon","numerals":"arabic-indic","restDays":["fri"],'
      '"guardianLabels":{},"updatedAt":null,"updatedByMembershipId":null,"source":"family"}',
    );
    await refuses(
      '{"version":1,"weekStartDay":"friday","numerals":"western","restDays":["fri"],'
      '"guardianLabels":{},"updatedAt":null,"updatedByMembershipId":null,"source":"family"}',
    );
    await refuses(
      '{"version":1,"weekStartDay":"mon","numerals":"western","restDays":["fri"],'
      '"guardianLabels":{"uncle":"عمو"},"updatedAt":null,"updatedByMembershipId":null,"source":"family"}',
    );
    await refuses(
      '{"version":1,"weekStartDay":"mon","numerals":"western","restDays":["fri"],'
      '"guardianLabels":{"father":" "},"updatedAt":null,"updatedByMembershipId":null,"source":"family"}',
    );
    await refuses('{"version":0}');
  });

  test('a status with no profile is a refusal, and a body that is not JSON is unreadable', () async {
    final unreachable = FamilyCustomizationFakeSpine()
      ..failure = const SocketException();
    await expectLater(
      familyCustomizationClientFor(unreachable).readProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.networkUnavailable,
        ),
      ),
    );

    final garbage = FamilyCustomizationFakeSpine()
      ..forced = const FoundationGateHttpResponse(
        statusCode: 200,
        body: 'not json at all',
      );
    await expectLater(
      familyCustomizationClientFor(garbage).readProfile(
        familyId: familyCustomizationFamilyId,
        idToken: 'token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (e) => e.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });
}

/// A closed socket, for the one state no HTTP status carries.
class SocketException implements Exception {
  const SocketException();
}
