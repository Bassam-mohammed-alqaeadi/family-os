import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/progress_bar.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/shared_onboarding/create_account_screen.dart';

void main() {
  testWidgets('weak password shows amber strength path', (tester) async {
    await _pumpCreateAccount(tester);

    await tester.enterText(
      find.byKey(const Key('create_account_password')),
      'abc',
    );
    await tester.pump();

    expect(find.text('قصيرة — زدها'), findsOneWidget);
    final bar = tester.widget<ProgressBar>(
      find.byKey(const Key('create_account_strength_bar')),
    );
    expect(bar.fillColor, FamilyColors.defaults.amber);
    expect(bar.value, closeTo(0.27, 0.001));
  });

  testWidgets('mismatch passwords keep submit disabled', (tester) async {
    var created = 0;
    await _pumpCreateAccount(tester, onCreated: () => created++);

    await tester.enterText(
      find.byKey(const Key('create_account_email')),
      'abdullah@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('create_account_password')),
      'password1',
    );
    await tester.enterText(
      find.byKey(const Key('create_account_confirm')),
      'password2',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('create_account_submit')));
    await tester.pump();
    expect(created, 0);
  });

  testWidgets('valid form navigates to /scr-shr-007', (tester) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-shr-002',
      routes: [
        GoRoute(
          path: '/scr-shr-002',
          builder: (context, state) => const CreateAccountScreen(),
        ),
        GoRoute(
          path: '/scr-shr-007',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-SHR-007',
            title: 'اختيار الوضع',
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

    await tester.enterText(
      find.byKey(const Key('create_account_email')),
      'abdullah@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('create_account_password')),
      'password1',
    );
    await tester.enterText(
      find.byKey(const Key('create_account_confirm')),
      'password1',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('create_account_submit')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-shr-007');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-SHR-007'), findsWidgets);
  });
}

Future<void> _pumpCreateAccount(
  WidgetTester tester, {
  VoidCallback? onCreated,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: CreateAccountScreen(onCreated: onCreated),
    ),
  );
  await tester.pumpAndSettle();
}
