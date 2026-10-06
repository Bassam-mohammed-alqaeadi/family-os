import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_context_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
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
    'server roster card forwards its exact child UUID into the context read',
    (tester) async {
      final familyId = FamilyId(_familyId);
      final childId = ChildId(_childId);
      final contextSource = _RecordingContextSource();
      final runtime = AppRuntime(
        identity: _IdentitySource(
          IdentitySnapshot(
            authority: IdentityAuthority.remoteAuthoritative,
            accountId: AccountId('guardian-subject'),
            familyId: familyId,
            role: AppRole.father,
            isPrimaryOwner: true,
          ),
        ),
        roster: _RosterSource(
          FamilyRosterSnapshot(
            familyId: familyId,
            origin: RuntimeDataOrigin.remoteAuthoritative,
            observedAt: DateTime.now().toUtc(),
            children: [
              FamilyRosterChild(
                childId: childId,
                displayName: 'Amani',
                ageYears: 8,
                avatarEmoji: '🦁',
                themeColor: 'purple',
              ),
            ],
          ),
        ),
        childContext: contextSource,
      );
      addTearDown(runtime.dispose);
      final router = GoRouter(
        initialLocation: '/scr-fat-012',
        routes: [
          GoRoute(
            path: '/scr-fat-012',
            builder: (_, _) => const ChildrenListScreen(),
          ),
          GoRoute(
            path: '/scr-fat-013',
            builder: (_, state) => RemoteChildContextScreen(
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
            theme: buildFamilyTheme(),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ChildrenListKeys.childRow(_childId)), findsOneWidget);
      await tester.tap(find.byKey(ChildrenListKeys.childRow(_childId)));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/scr-fat-013');
      expect(router.state.uri.queryParameters['childId'], _childId);
      expect(contextSource.requestedFamilyId, familyId);
      expect(contextSource.requestedChildId, childId);
      expect(find.byKey(RemoteChildContextKeys.ready), findsOneWidget);
      expect(find.text('Amani'), findsOneWidget);
    },
  );
}

final class _IdentitySource extends ChangeNotifier implements IdentitySource {
  _IdentitySource(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

final class _RosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  _RosterSource(this._value);

  final FamilyRosterSnapshot _value;

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async => _value;
}

final class _RecordingContextSource implements FamilyChildContextSource {
  FamilyId? requestedFamilyId;
  ChildId? requestedChildId;

  @override
  Future<FamilyChildContextResult> load({
    required FamilyId familyId,
    required ChildId childId,
  }) async {
    requestedFamilyId = familyId;
    requestedChildId = childId;
    final observedAt = DateTime.now().toUtc();
    return FamilyChildContextResult.ready(
      FamilyChildContext(
        familyId: familyId,
        childId: childId,
        displayName: 'Amani',
        ageYears: 8,
        avatarEmoji: '🦁',
        themeColor: 'purple',
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
