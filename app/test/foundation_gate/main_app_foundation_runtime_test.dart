import 'dart:convert';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

import 'foundation_gate_test_fakes.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';
const _idempotencyKey = '33333333-3333-4333-8333-333333333333';
const _familyBody =
    '{"families":[{"id":"$_familyId","displayName":"Synthetic family","role":"primary_guardian"}]}';
const _emptyRosterBody = '{"children":[]}';
const _rosterBody =
    '{"children":[{"id":"$_childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"teal","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}]}';
const _createdChildBody =
    '{"child":{"id":"$_childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"teal","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}}';

void main() {
  test('main runtime exposes only remote family authority and passes presentation fields to the server', () async {
    final identity = FakeIdentity(subject: 'firebase-subject');
    final discoveryTransport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: _familyBody),
    );
    final rosterTransport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: _emptyRosterBody),
    )..postResponse = const FoundationGateHttpResponse(
        statusCode: 201,
        body: _createdChildBody,
      );
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );
    final runtime = MainAppFoundationRuntime(
      identity: identity,
      controller: FoundationGateSessionController(
        identity: identity,
        discoveryApi: FamilyDiscoveryApiClient(
          configuration: configuration,
          transport: discoveryTransport,
        ),
        rosterApi: ChildrenRosterApiClient(
          configuration: configuration,
          transport: rosterTransport,
        ),
      ),
    );
    addTearDown(runtime.dispose);

    final identitySource = MainAppFoundationIdentitySource(runtime);
    final rosterSource = RemoteFamilyRosterSource(runtime);
    final childProfiles = RemoteFamilyChildProfileSource(runtime);
    addTearDown(identitySource.dispose);
    addTearDown(rosterSource.dispose);

    final snapshot = await identitySource.signIn(
      email: 'guardian@example.test',
      password: 'synthetic-password',
    );
    expect(snapshot.authority, IdentityAuthority.remoteAuthoritative);
    expect(snapshot.accountId?.value, 'firebase-subject');
    expect(snapshot.familyId?.value, _familyId);
    expect(snapshot.isPrimaryOwner, isTrue);

    final roster = await rosterSource.load(FamilyId(_familyId));
    expect(roster.isAuthoritative, isTrue);
    expect(roster.children, isEmpty);

    rosterTransport.response = const FoundationGateHttpResponse(
      statusCode: 200,
      body: _rosterBody,
    );
    final result = await childProfiles.create(
      familyId: FamilyId(_familyId),
      idempotencyKey: _idempotencyKey,
      draft: const FamilyChildProfileDraft(
        displayName: 'Synthetic child',
        ageYears: 8,
        avatarEmoji: '🧒',
        themeColor: 'teal',
      ),
    );

    expect(result.childId, _childId);
    expect(jsonDecode(rosterTransport.postedBody!), {
      'displayName': 'Synthetic child',
      'ageYears': 8,
      'avatarEmoji': '🧒',
      'themeColor': 'teal',
    });
    expect(rosterSource.value.children.single.avatarEmoji, '🧒');
    expect(rosterSource.value.children.single.themeColor, 'teal');
  });
}
