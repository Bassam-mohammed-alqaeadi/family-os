import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';
import 'package:family_os/features/n02_day/children_list_screen.dart';
import 'package:family_os/features/n02_day/remote_child_context_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _childId = '22222222-2222-4222-8222-222222222222';

void main() {
  testWidgets(
    'new child keeps its exact server UUID through roster and context navigation',
    (tester) async {
      final server = _FlowServer();
      final contextSource = _RecordingContextSource(server);
      final runtime = AppRuntime(
        identity: _IdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.remoteAuthoritative,
            accountId: AccountId('guardian-subject'),
            familyId: FamilyId(_familyId),
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        childProfiles: _CreateSource(server),
        roster: _CreatedRosterSource(server),
        childContext: contextSource,
      );
      addTearDown(runtime.dispose);

      late final GoRouter router;
      router = GoRouter(
        initialLocation: '/scr-fat-003',
        routes: [
          GoRoute(
            path: '/scr-fat-003',
            builder: (context, state) => const AddChildScreen(),
          ),
          GoRoute(
            path: '/scr-fat-004',
            builder: (context, state) => const Scaffold(body: Text('pairing')),
          ),
          GoRoute(
            path: '/scr-fat-012',
            builder: (context, state) => const ChildrenListScreen(),
          ),
          GoRoute(
            path: '/scr-fat-013',
            builder: (context, state) => RemoteChildContextScreen(
              childId: state.uri.queryParameters['childId'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        AppScope(
          runtime: runtime,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildFamilyTheme(),
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(AddChildKeys.name), ' Amani ');
      await tester.pump();
      final submit = find.byKey(AddChildKeys.submit);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(server.createCalls, 1);
      expect(server.familyId?.value, _familyId);
      expect(server.draft?.displayName, 'Amani');
      expect(router.state.uri.path, '/scr-fat-004');
      expect(router.state.uri.queryParameters['childId'], _childId);

      // Pairing completion returns to the authoritative roster in the real
      // flow. The roster source reads the child created immediately above.
      router.go('/scr-fat-012');
      await tester.pumpAndSettle();

      final childCard = find.byKey(ChildrenListKeys.childRow(_childId));
      expect(childCard, findsOneWidget);
      await tester.tap(childCard);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/scr-fat-013');
      expect(router.state.uri.queryParameters['childId'], _childId);
      expect(contextSource.calls, hasLength(1));
      expect(contextSource.calls.single.familyId.value, _familyId);
      expect(contextSource.calls.single.childId.value, _childId);
      expect(find.text('Amani'), findsOneWidget);
    },
  );
}

final class _FlowServer {
  int createCalls = 0;
  FamilyId? familyId;
  FamilyChildProfileDraft? draft;
}

final class _CreateSource implements FamilyChildProfileSource {
  _CreateSource(this.server);

  final _FlowServer server;

  @override
  Future<FamilyChildProfileCreateResult> create({
    required FamilyId familyId,
    required FamilyChildProfileDraft draft,
    required String idempotencyKey,
  }) async {
    server
      ..createCalls += 1
      ..familyId = familyId
      ..draft = draft;
    return const FamilyChildProfileCreateResult.created(childId: _childId);
  }

  @override
  void dispose() {}
}

final class _CreatedRosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  _CreatedRosterSource(this.server);

  final _FlowServer server;
  FamilyRosterSnapshot _value = const FamilyRosterSnapshot.unavailable();

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async {
    final draft = server.draft;
    if (draft == null || server.familyId != familyId) {
      _value = const FamilyRosterSnapshot.unavailable();
    } else {
      _value = FamilyRosterSnapshot(
        familyId: familyId,
        origin: RuntimeDataOrigin.remoteAuthoritative,
        observedAt: DateTime.now().toUtc(),
        children: [
          FamilyRosterChild(
            childId: ChildId(_childId),
            displayName: draft.displayName,
            ageYears: draft.ageYears,
            avatarEmoji: draft.avatarEmoji,
            themeColor: draft.themeColor,
          ),
        ],
      );
    }
    notifyListeners();
    return _value;
  }
}

final class _RecordingContextSource implements FamilyChildContextSource {
  _RecordingContextSource(this.server);

  final _FlowServer server;
  final List<({FamilyId familyId, ChildId childId})> calls = [];

  @override
  Future<FamilyChildContextResult> load({
    required FamilyId familyId,
    required ChildId childId,
  }) async {
    calls.add((familyId: familyId, childId: childId));
    final draft = server.draft!;
    final observedAt = DateTime.now().toUtc();
    return FamilyChildContextResult.ready(
      FamilyChildContext(
        familyId: familyId,
        childId: childId,
        displayName: draft.displayName,
        ageYears: draft.ageYears,
        avatarEmoji: draft.avatarEmoji,
        themeColor: draft.themeColor,
        version: 1,
        createdAt: observedAt,
        updatedAt: observedAt,
        deviceState: FamilyChildDeviceSetupState.notLinked,
        deviceCount: 0,
        observedAt: observedAt,
        permissionSnapshot: PermissionSnapshotV1(
          policyVersion: 1,
          role: FamilyChildContextRole.primaryGuardian,
          scopes: const {
            FamilyChildPermissionScope.read,
            FamilyChildPermissionScope.createDevicePairing,
          },
          observedAt: observedAt,
          expiresAt: observedAt.add(const Duration(minutes: 5)),
        ),
      ),
    );
  }

  @override
  void dispose() {}
}

final class _IdentitySource extends ChangeNotifier
    implements IdentitySource {
  _IdentitySource(this._value);

  IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;

  @override
  Future<void> recoverSession() async {}

  @override
  void setValueForTesting(IdentitySnapshot snapshot) {
    _value = snapshot;
    notifyListeners();
  }
}
