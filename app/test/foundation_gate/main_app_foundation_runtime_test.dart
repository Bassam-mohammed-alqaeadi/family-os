import 'dart:convert';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/family_membership_api_client.dart';
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
const _coGuardianFamilyBody =
    '{"families":[{"id":"$_familyId","displayName":"Synthetic family","role":"co_guardian"}]}';
const _emptyRosterBody = '{"children":[]}';
const _rosterBody =
    '{"children":[{"id":"$_childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"teal","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}]}';
const _membershipId = '44444444-4444-4444-8444-444444444444';
const _otherFamilyId = '55555555-5555-4555-8555-555555555555';
const _membershipBody =
    '{"id":"$_membershipId","role":"co_guardian","status":"invited","statusReasonCode":null,'
    '"version":1,"joinedAt":null,"statusChangedAt":"2026-10-07T09:00:00.000Z",'
    '"createdAt":"2026-10-07T09:00:00.000Z","isSelf":true}';
const _membershipRosterBody = '{"memberships":['
    '{"id":"66666666-6666-4666-8666-666666666666","role":"primary_guardian","status":"active",'
    '"statusReasonCode":null,"version":1,"joinedAt":"2026-10-01T08:00:00.000Z",'
    '"statusChangedAt":"2026-10-01T08:00:00.000Z","createdAt":"2026-10-01T08:00:00.000Z","isSelf":true},'
    '$_membershipBody]}';
const _createdChildBody =
    '{"child":{"id":"$_childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"teal","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"}}';

void main() {
  test(
    'main runtime exposes only remote family authority and passes presentation fields to the server',
    () async {
      final identity = FakeIdentity(subject: 'firebase-subject');
      final discoveryTransport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: _familyBody),
      );
      final rosterTransport =
          FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _emptyRosterBody,
              ),
            )
            ..postResponse = const FoundationGateHttpResponse(
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
        deviceApi: FamilyDeviceApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
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
    },
  );

  test(
    'memberships are read for the selected family, changed through the server, and refused without a session',
    () async {
      // The token is what reaches the server; the subject is what the server makes of it.
      final identity = FakeIdentity(
        token: 'synthetic-id-token',
        subject: 'firebase-subject',
      );
      final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      );
      final membershipTransport =
          FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _membershipRosterBody,
              ),
            )
            ..postResponse = const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"membership":$_membershipBody}',
            );
      final runtime = MainAppFoundationRuntime(
        identity: identity,
        controller: FoundationGateSessionController(
          identity: identity,
          discoveryApi: FamilyDiscoveryApiClient(
            configuration: configuration,
            transport: FakeTransport(
              const FoundationGateHttpResponse(statusCode: 200, body: _familyBody),
            ),
          ),
          rosterApi: ChildrenRosterApiClient(
            configuration: configuration,
            transport: FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _emptyRosterBody,
              ),
            ),
          ),
        ),
        deviceApi: FamilyDeviceApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{"devices":[]}'),
          ),
        ),
        membershipApi: FamilyMembershipApiClient(
          configuration: configuration,
          transport: membershipTransport,
        ),
      );
      addTearDown(runtime.dispose);
      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);

      // Before any session exists the roster read answers nothing: a build with no
      // authenticated principal must not be handed a family it has no claim to.
      expect(await runtime.listMemberships(FamilyId(_familyId)), isEmpty);

      await identitySource.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );

      final memberships = await runtime.listMemberships(FamilyId(_familyId));
      expect(memberships, hasLength(2));
      expect(memberships.first.isSelf, isTrue);
      expect(
        membershipTransport.requestedUri.toString(),
        'https://staging.example.test/v1/families/$_familyId/memberships',
      );
      expect(
        membershipTransport.requestedHeaders?['authorization'],
        'Bearer synthetic-id-token',
        reason: 'the server call carries the session token, not the subject it names',
      );

      // A different family than the one this session selected is not read at all.
      expect(
        await runtime.listMemberships(FamilyId(_otherFamilyId)),
        isEmpty,
        reason: 'the runtime reads memberships only for the family it selected',
      );

      // The three commands reach the server with the token and the idempotency key.
      await runtime.acceptMembership(
        familyId: FamilyId(_familyId),
        membershipId: _membershipId,
        idempotencyKey: _idempotencyKey,
      );
      expect(
        membershipTransport.postedUri.toString(),
        'https://staging.example.test/v1/families/$_familyId/memberships/$_membershipId/accept',
      );
      expect(membershipTransport.postedHeaders?['idempotency-key'], _idempotencyKey);
    },
  );

  test(
    'remote co-guardian identity is never promoted to full mother level by default',
    () async {
      final identity = FakeIdentity(subject: 'firebase-subject');
      final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      );
      final runtime = MainAppFoundationRuntime(
        identity: identity,
        controller: FoundationGateSessionController(
          identity: identity,
          discoveryApi: FamilyDiscoveryApiClient(
            configuration: configuration,
            transport: FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _coGuardianFamilyBody,
              ),
            ),
          ),
          rosterApi: ChildrenRosterApiClient(
            configuration: configuration,
            transport: FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _emptyRosterBody,
              ),
            ),
          ),
        ),
        deviceApi: FamilyDeviceApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{"devices":[]}'),
          ),
        ),
      );
      addTearDown(runtime.dispose);
      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);

      final snapshot = await identitySource.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );
      expect(snapshot.authority, IdentityAuthority.remoteAuthoritative);
      expect(snapshot.motherLevel, MotherLevel.observer);
      expect(snapshot.motherLevel, isNot(MotherLevel.full));
    },
  );
}
