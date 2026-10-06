import 'dart:convert';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/foundation_gate/child_context_api_client.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_creation_api_client.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
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
const _createdFamilyBody =
    '{"family":{"id":"$_familyId","displayName":"Synthetic family"}}';
const _noFamiliesBody = '{"families":[]}';

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
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
            postResponse: const FoundationGateHttpResponse(
              statusCode: 201,
              body: _createdFamilyBody,
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
    'main runtime creates a family through the real contract and re-discovers it',
    () async {
      final identity = FakeIdentity(subject: 'firebase-subject');
      final discoveryTransport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: _familyBody),
      );
      final familyCreationTransport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
        postResponse: const FoundationGateHttpResponse(
          statusCode: 201,
          body: _createdFamilyBody,
        ),
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: familyCreationTransport,
        ),
      );
      addTearDown(runtime.dispose);

      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);
      await identitySource.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );

      final result = await runtime.createFamily(
        displayName: 'Synthetic family',
        idempotencyKey: _idempotencyKey,
      );

      expect(result.isCreated, isTrue);
      expect(result.familyId, _familyId);
      expect(result.displayName, 'Synthetic family');
      expect(
        familyCreationTransport.postedUri.toString(),
        'https://staging.example.test/v1/families',
      );
      expect(jsonDecode(familyCreationTransport.postedBody!), {
        'displayName': 'Synthetic family',
      });
      expect(
        familyCreationTransport.postedHeaders!['authorization'],
        startsWith('Bearer '),
      );
      expect(
        familyCreationTransport.postedHeaders!['idempotency-key'],
        _idempotencyKey,
      );
      // Re-discovery ran again after the confirmed create.
      expect(
        discoveryTransport.requestedUri.toString(),
        contains('/v1/me/families'),
      );
    },
  );

  test(
    'main runtime maps a 503 family-creation failure to an explicit outcome',
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
                body: _familyBody,
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
            postResponse: const FoundationGateHttpResponse(
              statusCode: 503,
              body: '',
            ),
          ),
        ),
      );
      addTearDown(runtime.dispose);

      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);
      await identitySource.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );

      final result = await runtime.createFamily(
        displayName: 'Synthetic family',
        idempotencyKey: _idempotencyKey,
      );

      expect(result.isCreated, isFalse);
      expect(result.outcome, FamilyCreationOutcome.serviceUnavailable);
    },
  );

  test(
    'family-create 401 clears every published authority projection',
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
                body: _familyBody,
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
            postResponse: const FoundationGateHttpResponse(
              statusCode: 401,
              body: '',
            ),
          ),
        ),
      );
      addTearDown(runtime.dispose);

      final signedIn = await runtime.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );
      expect(signedIn.isRemoteAuthoritative, isTrue);
      await runtime.loadRoster(FamilyId(_familyId));
      await runtime.loadDevices(FamilyId(_familyId));
      expect(runtime.rosterValue.isAuthoritative, isTrue);
      expect(runtime.deviceValue.origin, RuntimeDataOrigin.remoteAuthoritative);

      final result = await runtime.createFamily(
        displayName: 'Synthetic family',
        idempotencyKey: _idempotencyKey,
      );

      expect(result.outcome, FamilyCreationOutcome.unauthenticated);
      expect(runtime.phase, FoundationGatePhase.sessionInvalid);
      expect(runtime.identityValue.isRemoteAuthoritative, isFalse);
      expect(runtime.rosterValue.isAuthoritative, isFalse);
      expect(runtime.deviceValue.origin, RuntimeDataOrigin.unavailable);
      expect(identity.signOutCalls, 1);
    },
  );

  test(
    'a brand-new account with no family can create its first family and is selected into it',
    () async {
      final identity = FakeIdentity(subject: 'firebase-subject');
      // Discovery is empty until the family exists, then returns it.
      final discoveryTransport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: _noFamiliesBody,
        ),
      );
      final familyCreationTransport = FakeTransport(
        const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
        postResponse: const FoundationGateHttpResponse(
          statusCode: 201,
          body: _createdFamilyBody,
        ),
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: familyCreationTransport,
        ),
      );
      addTearDown(runtime.dispose);

      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);
      final afterSignUp = await identitySource.signUp(
        email: 'new-guardian@example.test',
        password: 'synthetic-password',
      );

      // Signed in, but honestly without a family context yet.
      expect(identity.signUpCalls, 1);
      expect(afterSignUp.isRemoteAuthoritative, isFalse);
      expect(identitySource.needsFamilyCreation, isTrue);
      expect(identitySource.hasAuthenticatedPrincipal, isTrue);

      // The server now knows the family on the next discovery.
      discoveryTransport.response = const FoundationGateHttpResponse(
        statusCode: 200,
        body: _familyBody,
      );
      final result = await runtime.createFamily(
        displayName: 'Synthetic family',
        idempotencyKey: _idempotencyKey,
      );

      expect(
        result.isCreated,
        isTrue,
        reason: 'first family must be creatable',
      );
      expect(result.familyId, _familyId);
      expect(
        familyCreationTransport.postedHeaders!['authorization'],
        startsWith('Bearer '),
      );
      // Re-discovery selected the created family and identity became authoritative.
      expect(identitySource.needsFamilyCreation, isFalse);
      expect(identitySource.value.isRemoteAuthoritative, isTrue);
      expect(identitySource.value.familyId?.value, _familyId);
      expect(identitySource.value.isPrimaryOwner, isTrue);
    },
  );

  test('a signed-out runtime cannot create a family', () async {
    final identity = FakeIdentity(
      failure: const FoundationGateIdentityException(
        FoundationGateIdentityFailure.noSession,
      ),
    );
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );
    final familyCreationTransport = FakeTransport(
      const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
      postResponse: const FoundationGateHttpResponse(
        statusCode: 201,
        body: _createdFamilyBody,
      ),
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
              body: _noFamiliesBody,
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
          const FoundationGateHttpResponse(
            statusCode: 200,
            body: '{"devices":[]}',
          ),
        ),
      ),
      familyCreationApi: FamilyCreationApiClient(
        configuration: configuration,
        transport: familyCreationTransport,
      ),
    );
    addTearDown(runtime.dispose);

    final result = await runtime.createFamily(
      displayName: 'Synthetic family',
      idempotencyKey: _idempotencyKey,
    );

    expect(result.isCreated, isFalse);
    expect(result.outcome, FamilyCreationOutcome.unauthenticated);
    expect(
      familyCreationTransport.postedUri,
      isNull,
      reason: 'no request may leave the device without a principal',
    );
  });

  test(
    'a failed sign-up keeps the account unauthenticated and reports a safe reason',
    () async {
      final identity = FakeIdentity(
        failure: const FoundationGateIdentityException(
          FoundationGateIdentityFailure.emailAlreadyInUse,
        ),
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
            transport: FakeTransport(
              const FoundationGateHttpResponse(
                statusCode: 200,
                body: _noFamiliesBody,
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
          ),
        ),
      );
      addTearDown(runtime.dispose);

      final identitySource = MainAppFoundationIdentitySource(runtime);
      addTearDown(identitySource.dispose);
      final snapshot = await identitySource.signUp(
        email: 'taken@example.test',
        password: 'synthetic-password',
      );

      expect(snapshot.isRemoteAuthoritative, isFalse);
      expect(identitySource.phase, FoundationGatePhase.signInFailed);
      expect(
        identitySource.lastIdentityFailure,
        FoundationGateIdentityFailure.emailAlreadyInUse,
      );
      expect(identitySource.hasAuthenticatedPrincipal, isFalse);
      expect(identitySource.needsFamilyCreation, isFalse);
    },
  );

  test(
    'pairing reloads verification and uses the refreshed ID token claim',
    () async {
      final identity = FakeIdentity(
        subject: 'firebase-subject',
        token: 'stale-unverified-token',
      )..tokenAfterVerificationReload = 'fresh-verified-token';
      final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      );
      final deviceTransport = FakeTransport(
        const FoundationGateHttpResponse(
          statusCode: 200,
          body: '{"devices":[]}',
        ),
        postResponse: const FoundationGateHttpResponse(
          statusCode: 201,
          body:
              '{"pairing":{"id":"44444444-4444-4444-8444-444444444444","childId":"$_childId","deviceLabel":"Child phone","pairingCode":"482910","expiresAt":"2026-10-06T12:10:00.000Z"}}',
        ),
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
                body: _familyBody,
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
          transport: deviceTransport,
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
          ),
        ),
      );
      addTearDown(runtime.dispose);
      await runtime.signIn(
        email: 'guardian@example.test',
        password: 'synthetic-password',
      );

      final result = await runtime.createDevicePairing(
        familyId: FamilyId(_familyId),
        childId: ChildId(_childId),
        deviceLabel: 'Child phone',
        idempotencyKey: _idempotencyKey,
      );

      expect(result.isCreated, isTrue);
      expect(identity.verificationReloads, [true]);
      expect(
        deviceTransport.postedHeaders?['authorization'],
        'Bearer fresh-verified-token',
      );
    },
  );

  test('remote child context source preserves server failure taxonomy and authority', () async {
    final identity = FakeIdentity(subject: 'firebase-subject');
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );
    final contextTransport = FakeTransport(
      const FoundationGateHttpResponse(
        statusCode: 200,
        body: '{"child":{"id":"$_childId","displayName":"Synthetic child","ageYears":8,"avatarEmoji":"🧒","themeColor":"teal","version":1,"createdAt":"2026-10-03T10:00:00.000Z","updatedAt":"2026-10-03T10:00:00.000Z"},"setup":{"deviceState":"not_linked","deviceCount":0,"observedAt":"2026-10-07T09:00:00.000Z"},"permissionSnapshot":{"policyVersion":1,"role":"primary_guardian","scopes":["child.context.read","child.device_pairing.create"],"observedAt":"2026-10-07T09:00:00.000Z","expiresAt":"2026-10-07T09:05:00.000Z"}}',
      ),
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
            const FoundationGateHttpResponse(statusCode: 200, body: _rosterBody),
          ),
        ),
      ),
      deviceApi: FamilyDeviceApiClient(
        configuration: configuration,
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: '{"devices":[]}'),
        ),
      ),
      familyCreationApi: FamilyCreationApiClient(
        configuration: configuration,
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
        ),
      ),
      childContextApi: ChildContextApiClient(
        configuration: configuration,
        transport: contextTransport,
        clock: () => DateTime.parse('2026-10-07T09:01:00Z'),
      ),
    );
    addTearDown(runtime.dispose);
    await runtime.signIn(
      email: 'guardian@example.test',
      password: 'synthetic-password',
    );
    final source = RemoteFamilyChildContextSource(runtime);

    final ready = await source.load(
      familyId: FamilyId(_familyId),
      childId: ChildId(_childId),
    );
    expect(ready.isReady, isTrue);
    expect(ready.context?.displayName, 'Synthetic child');
    expect(ready.context?.permissionSnapshot.role, FamilyChildContextRole.primaryGuardian);

    contextTransport.response = const FoundationGateHttpResponse(
      statusCode: 403,
      body: '{}',
    );
    final denied = await source.load(
      familyId: FamilyId(_familyId),
      childId: ChildId(_childId),
    );
    expect(denied.failure, FamilyChildContextFailure.accessDenied);

    contextTransport.response = const FoundationGateHttpResponse(
      statusCode: 401,
      body: '{}',
    );
    final invalidSession = await source.load(
      familyId: FamilyId(_familyId),
      childId: ChildId(_childId),
    );
    expect(invalidSession.failure, FamilyChildContextFailure.sessionInvalid);
    expect(runtime.phase, FoundationGatePhase.sessionInvalid);
    expect(runtime.identityValue.authority, IdentityAuthority.unavailable);
  });

  test(
    'e-mail verification is surfaced to the pairing UI and can be re-sent (Owner C1)',
    () async {
      final identity = FakeIdentity(subject: 'firebase-subject')
        ..emailVerified = false;
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
                body: _familyBody,
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
            const FoundationGateHttpResponse(
              statusCode: 200,
              body: '{"devices":[]}',
            ),
          ),
        ),
        familyCreationApi: FamilyCreationApiClient(
          configuration: configuration,
          transport: FakeTransport(
            const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
          ),
        ),
      );
      addTearDown(runtime.dispose);
      final devices = RemoteFamilyDeviceSource(runtime);
      addTearDown(devices.dispose);

      expect(await devices.isEmailVerified(), isFalse);
      expect(await devices.sendEmailVerification(), isTrue);
      expect(identity.verificationEmailsSent, 1);

      identity.emailVerified = true;
      expect(await devices.isEmailVerified(reload: true), isTrue);

      // Signed-out provider: never reports verified, never throws to the UI.
      identity.failure = const FoundationGateIdentityException(
        FoundationGateIdentityFailure.noSession,
      );
      expect(await devices.isEmailVerified(), isFalse);
      expect(await devices.sendEmailVerification(), isFalse);
    },
  );
}
