import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_repository.dart';
import 'package:family_os/features/shared_onboarding/device_user_switch_screen.dart';

/// Parametric seed only — no person names in lib (Rule 12/23).
List<DeviceUserProfile> _seedProfiles() => const [
      DeviceUserProfile(
        id: 'local_father',
        displayName: 'Parent A',
        role: AppRole.father,
        monogram: 'A',
      ),
      DeviceUserProfile(
        id: 'local_mother',
        displayName: 'Parent B',
        role: AppRole.mother,
        monogram: 'B',
        motherLevel: MotherLevel.partner,
        avatarColorHex: '#FF8FA3',
      ),
    ];

void main() {
  testWidgets('Rule 23 empty default + add CTA', (tester) async {
    final emptyRepo = InMemoryDeviceUserSwitchRepository();
    await _pump(tester, repository: emptyRepo);
    expect(find.byKey(DeviceUserSwitchKeys.empty), findsOneWidget);
    expect(find.byKey(DeviceUserSwitchKeys.addAccount), findsOneWidget);
  });

  testWidgets('lists seeded profiles; active tagged', (tester) async {
    final seeded = InMemoryDeviceUserSwitchRepository(
      profiles: _seedProfiles(),
    );
    await _pump(tester, repository: seeded, role: AppRole.father);
    expect(find.byKey(DeviceUserSwitchKeys.list), findsOneWidget);
    expect(
      find.byKey(DeviceUserSwitchKeys.row('local_father')),
      findsOneWidget,
    );
    expect(
      find.byKey(DeviceUserSwitchKeys.row('local_mother')),
      findsOneWidget,
    );
    expect(find.text('نشط'), findsOneWidget);
    expect(find.textContaining('Parent A'), findsOneWidget);
    expect(find.text('Parent B'), findsOneWidget);
    expect(find.text('دخول ←'), findsOneWidget);
  });

  testWidgets('error with retry recovers to list', (tester) async {
    final repo = InMemoryDeviceUserSwitchRepository(failLoad: true);
    await _pump(tester, repository: repo);
    expect(find.byKey(DeviceUserSwitchKeys.error), findsOneWidget);

    repo.failLoad = false;
    repo.seed(_seedProfiles());
    await tester.tap(find.textContaining('إعادة'));
    await tester.pumpAndSettle();
    expect(find.byKey(DeviceUserSwitchKeys.list), findsOneWidget);
  });

  testWidgets('loading shows while load awaits', (tester) async {
    final gate = Completer<void>();
    final repo = _GatedRepo(gate.future, _seedProfiles());
    await _pump(tester, repository: repo, settle: false);
    await tester.pump();
    expect(find.byKey(DeviceUserSwitchKeys.loading), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(DeviceUserSwitchKeys.list), findsOneWidget);
  });

  testWidgets('child RoleGuard lean — no switch list', (tester) async {
    final repo = InMemoryDeviceUserSwitchRepository(
      profiles: _seedProfiles(),
    );
    await _pump(
      tester,
      repository: repo,
      role: AppRole.child,
      roleOverride: AppRole.child,
    );
    expect(find.byKey(DeviceUserSwitchKeys.childLean), findsOneWidget);
    expect(find.byKey(DeviceUserSwitchKeys.list), findsNothing);
  });

  testWidgets('switch mother → password confirm → role + navigate',
      (tester) async {
    final role = RoleController(AppRole.father);
    DeviceUserProfile? switched;
    final repo = InMemoryDeviceUserSwitchRepository(
      profiles: _seedProfiles(),
    );
    final router = GoRouter(
      initialLocation: '/scr-shr-008',
      routes: [
        GoRoute(
          path: '/scr-shr-008',
          builder: (context, state) => DeviceUserSwitchScreen(
            repository: repo,
            onSwitched: (p) {
              switched = p;
              context.go('/scr-fat-010');
            },
          ),
        ),
        GoRoute(
          path: '/scr-fat-010',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-010',
            title: 'لوحة اليوم',
          ),
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      role.dispose();
    });

    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
        child: MaterialApp.router(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
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

    await tester.tap(find.byKey(DeviceUserSwitchKeys.row('local_mother')));
    await tester.pumpAndSettle();
    expect(find.byKey(DeviceUserSwitchKeys.confirmDialog), findsOneWidget);

    await tester.enterText(
      find.byKey(DeviceUserSwitchKeys.confirmPassword),
      'mock-pass',
    );
    await tester.tap(find.byKey(DeviceUserSwitchKeys.confirmSubmit));
    await tester.pumpAndSettle();

    expect(role.value, AppRole.mother);
    expect(switched?.id, 'local_mother');
    expect(router.state.uri.path, '/scr-fat-010');
  });

  testWidgets('add account CTA fires seam', (tester) async {
    var added = false;
    final repo = InMemoryDeviceUserSwitchRepository(
      profiles: _seedProfiles(),
    );
    await _pump(
      tester,
      repository: repo,
      onAddAccount: () => added = true,
    );
    await tester.tap(find.byKey(DeviceUserSwitchKeys.addAccount));
    await tester.pumpAndSettle();
    expect(added, isTrue);
  });

  testWidgets('confirm cancel leaves role unchanged', (tester) async {
    final role = RoleController(AppRole.father);
    final repo = InMemoryDeviceUserSwitchRepository(
      profiles: _seedProfiles(),
    );
    addTearDown(role.dispose);
    await tester.pumpWidget(
      CurrentRole(
        notifier: role,
        child: MaterialApp(
          theme: buildFamilyTheme(),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DeviceUserSwitchScreen(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DeviceUserSwitchKeys.row('local_mother')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DeviceUserSwitchKeys.confirmCancel));
    await tester.pumpAndSettle();

    expect(role.value, AppRole.father);
    expect(find.byKey(DeviceUserSwitchKeys.confirmDialog), findsNothing);
  });
}

final class _GatedRepo implements DeviceUserSwitchRepository {
  _GatedRepo(this._gate, this._profiles);

  final Future<void> _gate;
  final List<DeviceUserProfile> _profiles;

  @override
  Future<List<DeviceUserProfile>> listProfiles() async {
    await _gate;
    return List.unmodifiable(_profiles);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required DeviceUserSwitchRepository repository,
  AppRole role = AppRole.father,
  AppRole? roleOverride,
  VoidCallback? onAddAccount,
  bool settle = true,
}) async {
  final controller = RoleController(role);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    CurrentRole(
      notifier: controller,
      child: MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: DeviceUserSwitchScreen(
          repository: repository,
          roleOverride: roleOverride,
          onAddAccount: onAddAccount,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
