import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/foundation_gate/children_roster_api_client.dart';
import 'package:family_os/foundation_gate/family_creation_api_client.dart';
import 'package:family_os/foundation_gate/family_device_api_client.dart';
import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_session_controller.dart';
import 'package:family_os/foundation_gate/main_app_foundation_runtime.dart';

import '../../foundation_gate/foundation_gate_test_fakes.dart';

export '../../foundation_gate/foundation_gate_test_fakes.dart';

const kTestFamilyId = '11111111-1111-4111-8111-111111111111';
const kFamiliesBody =
    '{"families":[{"id":"$kTestFamilyId","displayName":"Synthetic family","role":"primary_guardian"}]}';
const kNoFamiliesBody = '{"families":[]}';
const kEmptyRosterBody = '{"children":[]}';

/// A real [MainAppFoundationRuntime] wired to fakes: the screens under test
/// exercise the genuine sign-in / sign-up orchestration.
class OnboardingHost {
  OnboardingHost({
    required this.identity,
    String discoveryBody = kFamiliesBody,
    int discoveryStatus = 200,
    FakeTransport? deviceTransport,
  }) : devices =
           deviceTransport ??
           FakeTransport(
             const FoundationGateHttpResponse(
               statusCode: 200,
               body: '{"devices":[]}',
             ),
           ),
       discovery = FakeTransport(
         FoundationGateHttpResponse(
           statusCode: discoveryStatus,
           body: discoveryBody,
         ),
       ),
       roster = FakeTransport(
         const FoundationGateHttpResponse(
           statusCode: 200,
           body: kEmptyRosterBody,
         ),
       ) {
    final configuration = FoundationGateConfiguration.fromStagingApiOrigin(
      Uri.parse('https://staging.example.test'),
    );
    runtime = MainAppFoundationRuntime(
      identity: identity,
      controller: FoundationGateSessionController(
        identity: identity,
        discoveryApi: FamilyDiscoveryApiClient(
          configuration: configuration,
          transport: discovery,
        ),
        rosterApi: ChildrenRosterApiClient(
          configuration: configuration,
          transport: roster,
        ),
      ),
      deviceApi: FamilyDeviceApiClient(
        configuration: configuration,
        transport: devices,
      ),
      familyCreationApi: FamilyCreationApiClient(
        configuration: configuration,
        transport: FakeTransport(
          const FoundationGateHttpResponse(statusCode: 200, body: '{}'),
        ),
      ),
    );
    identitySource = MainAppFoundationIdentitySource(runtime);
    appRuntime = AppRuntime(
      identity: identitySource,
      devices: RemoteFamilyDeviceSource(runtime),
      guardianSignOut: runtime.signOut,
    );
  }

  final FakeIdentity identity;
  final FakeTransport discovery;
  final FakeTransport roster;
  final FakeTransport devices;
  late final MainAppFoundationRuntime runtime;
  late final MainAppFoundationIdentitySource identitySource;
  late final AppRuntime appRuntime;

  void dispose() {
    // AppRuntime disposes its identity source.
    appRuntime.dispose();
    runtime.dispose();
  }
}

/// Static identity source for screens that need an already-selected family.
class StaticIdentitySource extends ValueNotifier<IdentitySnapshot>
    implements IdentitySource {
  StaticIdentitySource(super.value);

  @override
  Future<IdentitySnapshot> refresh() async => value;
}

/// Recording child-profile source; resolves when [complete] is called when
/// [manual] is true, otherwise immediately with [result].
class RecordingChildProfileSource implements FamilyChildProfileSource {
  RecordingChildProfileSource({required this.result, this.manual = false});

  FamilyChildProfileCreateResult result;
  final bool manual;
  final List<
    ({String familyId, String idempotencyKey, FamilyChildProfileDraft draft})
  >
  calls = [];
  final List<Completer<FamilyChildProfileCreateResult>> _pending = [];

  @override
  Future<FamilyChildProfileCreateResult> create({
    required familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) {
    calls.add((
      familyId: familyId.value,
      idempotencyKey: idempotencyKey,
      draft: draft,
    ));
    if (!manual) return Future.value(result);
    final completer = Completer<FamilyChildProfileCreateResult>();
    _pending.add(completer);
    return completer.future;
  }

  void complete([FamilyChildProfileCreateResult? value]) {
    for (final c in _pending) {
      if (!c.isCompleted) c.complete(value ?? result);
    }
    _pending.clear();
  }

  @override
  void dispose() {}
}

GoRoute placeholderRoute(String path, String id) => GoRoute(
  path: path,
  builder: (context, state) => PlaceholderScreen(screenId: id, title: id),
);

Future<GoRouter> pumpWithRouter(
  WidgetTester tester, {
  required AppRuntime? runtime,
  required String initialLocation,
  required List<GoRoute> routes,
  Locale locale = const Locale('ar'),
  bool settle = true,
}) async {
  // Tall phone viewport so whole forms are laid out without scrolling.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  addTearDown(router.dispose);
  Widget app = MaterialApp.router(
    theme: buildFamilyTheme(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
  if (runtime != null) app = AppScope(runtime: runtime, child: app);
  await tester.pumpWidget(app);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return router;
}

/// Scrolls the onboarding list until [finder] is built and visible, then taps.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}
