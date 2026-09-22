import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/link_qr_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('shows instruction + QR semantics', (tester) async {
    await _pumpLinkQr(tester, mockToken: 'pair_abcd1234');

    expect(find.byKey(const Key('link_qr_instruction')), findsOneWidget);
    expect(
      find.textContaining('حمّل نفس التطبيق «عائلتي»'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('link_qr_visual')), findsOneWidget);
    expect(find.bySemanticsLabel('رمز الربط QR'), findsOneWidget);
    expect(find.text('اربط جهازه'), findsOneWidget);
    expect(find.text('٢ من ٣'), findsOneWidget);
    expect(find.byKey(const Key('link_qr_timer')), findsOneWidget);
    expect(find.textContaining('٤:٥٩'), findsOneWidget);

    await _settleTimers(tester);
  });

  testWidgets('primary → /scr-fat-005', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-004',
      routes: [
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => const LinkQrScreen(),
        ),
        GoRoute(
          path: '/scr-fat-005',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-005',
            title: 'شرح الصلاحيات',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
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
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('link_qr_continue')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-005');
    expect(find.text('SCR-FAT-005'), findsWidgets);
  });

  testWidgets('renew resets timer + toast', (tester) async {
    await _pumpLinkQr(
      tester,
      initialSeconds: 0,
      mockToken: 'pair_oldtoken',
    );

    expect(find.byKey(const Key('link_qr_expired')), findsOneWidget);
    final before = tester.widget<Text>(find.byKey(const Key('link_qr_token')));
    expect(before.data, 'pair_oldtoken');

    await tester.tap(find.byKey(const Key('link_qr_renew')));
    await tester.pump();

    expect(find.textContaining('وُلّد رمز جديد'), findsOneWidget);
    expect(find.byKey(const Key('link_qr_expired')), findsNothing);
    expect(find.byKey(const Key('link_qr_timer')), findsOneWidget);
    expect(find.textContaining('٤:٥٩'), findsOneWidget);

    final after = tester.widget<Text>(find.byKey(const Key('link_qr_token')));
    expect(after.data, isNot('pair_oldtoken'));
    expect(after.data, matches(RegExp(r'^pair_[a-f0-9]{8}$')));

    final continueBtn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('link_qr_continue')),
    );
    expect(continueBtn.onPressed, isNotNull);

    await _settleTimers(tester);
  });

  testWidgets('expired disables primary until renew', (tester) async {
    await _pumpLinkQr(
      tester,
      initialSeconds: 1,
      tickInterval: const Duration(milliseconds: 20),
    );

    var continueBtn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('link_qr_continue')),
    );
    expect(continueBtn.onPressed, isNotNull);

    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump();

    expect(find.byKey(const Key('link_qr_expired')), findsOneWidget);
    continueBtn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('link_qr_continue')),
    );
    expect(continueBtn.onPressed, isNull);

    await tester.tap(find.byKey(const Key('link_qr_continue')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('link_qr_renew')));
    await tester.pump();

    continueBtn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('link_qr_continue')),
    );
    expect(continueBtn.onPressed, isNotNull);

    await _settleTimers(tester);
  });

  testWidgets('ghost → /scr-fat-007', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-004',
      routes: [
        GoRoute(
          path: '/scr-fat-004',
          builder: (context, state) => const LinkQrScreen(),
        ),
        GoRoute(
          path: '/scr-fat-007',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-007',
            title: 'وضع التجربة',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
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
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('link_qr_trial')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-007');
    expect(find.text('SCR-FAT-007'), findsWidgets);
  });

  testWidgets('Rule 23 — no خالد in screen strings', (tester) async {
    await _pumpLinkQr(tester);

    expect(find.textContaining('خالد'), findsNothing);

    await _settleTimers(tester);
  });

  testWidgets('formatLinkQrCountdown eastern + western', (tester) async {
    expect(formatLinkQrCountdown(299, eastern: true), '٤:٥٩');
    expect(formatLinkQrCountdown(299, eastern: false), '4:59');
    expect(formatLinkQrCountdown(59, eastern: true), '٠:٥٩');
  });
}

Future<void> _settleTimers(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _pumpLinkQr(
  WidgetTester tester, {
  int initialSeconds = kLinkQrDefaultSeconds,
  Duration tickInterval = const Duration(seconds: 1),
  VoidCallback? onContinue,
  VoidCallback? onTrial,
  String? mockToken,
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
      home: LinkQrScreen(
        initialSeconds: initialSeconds,
        tickInterval: tickInterval,
        onContinue: onContinue,
        onTrial: onTrial,
        mockToken: mockToken,
      ),
    ),
  );
  await tester.pump();
}
