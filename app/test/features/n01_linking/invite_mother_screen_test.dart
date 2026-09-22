import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/components/tag.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/invite_mother_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('empty email disables CTA; Rule 23 — no prefilled email / خالد', (
    tester,
  ) async {
    var sent = 0;
    await _pumpScreen(tester, onInviteSent: () => sent++);

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('invite_mother_email')),
    );
    expect(emailField.controller!.text, isEmpty);
    expect(find.text('nawal@example.com'), findsNothing);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('invite_mother_submit')),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(find.byKey(const Key('invite_mother_submit')));
    await tester.pump();
    expect(sent, 0);
  });

  testWidgets('default level is مشاركة with recommended tag', (tester) async {
    await _pumpScreen(tester);

    final partner = find.byKey(const Key('invite_mother_level_partner'));
    expect(partner, findsOneWidget);
    expect(
      find.descendant(of: partner, matching: find.text('●')),
      findsOneWidget,
    );
    expect(find.text('مشاركة'), findsOneWidget);
    expect(find.text('موصى به'), findsOneWidget);
    expect(find.byType(Tag), findsOneWidget);

    final observer = find.byKey(const Key('invite_mother_level_observer'));
    expect(
      find.descendant(of: observer, matching: find.text('○')),
      findsOneWidget,
    );
  });

  testWidgets('select كاملة updates selection marker', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const Key('invite_mother_level_full')));
    await tester.pump();

    final full = find.byKey(const Key('invite_mother_level_full'));
    expect(
      find.descendant(of: full, matching: find.text('●')),
      findsOneWidget,
    );
    final partner = find.byKey(const Key('invite_mother_level_partner'));
    expect(
      find.descendant(of: partner, matching: find.text('○')),
      findsOneWidget,
    );
  });

  testWidgets('send → toast with local-part + level; navigates /scr-fat-027', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-008',
      routes: [
        GoRoute(
          path: '/scr-fat-008',
          builder: (context, state) => const InviteMotherScreen(),
        ),
        GoRoute(
          path: '/scr-fat-027',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-027',
            title: 'أعضاء العائلة',
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

    await tester.enterText(
      find.byKey(const Key('invite_mother_email')),
      'sara@example.com',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('invite_mother_level_full')));
    await tester.pump();

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('invite_mother_submit')),
    );
    expect(btn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('invite_mother_submit')));
    await tester.pump();

    expect(
      find.textContaining('أُرسلت الدعوة إلى sara بمستوى «كاملة»'),
      findsOneWidget,
    );
    expect(find.textContaining('نوال'), findsNothing);

    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-027');
    expect(find.byType(PlaceholderScreen), findsOneWidget);

    await _settleTimers(tester);
  });

  testWidgets('banner + intro copy present', (tester) async {
    await _pumpScreen(tester);

    expect(find.byKey(const Key('invite_mother_banner')), findsOneWidget);
    expect(find.textContaining('حقوق لا تخضع للتدرّج'), findsOneWidget);
    expect(
      find.textContaining('تطمئن معك على الأبناء'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  VoidCallback? onInviteSent,
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
      home: InviteMotherScreen(onInviteSent: onInviteSent),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleTimers(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pump(const Duration(milliseconds: 2600));
}
