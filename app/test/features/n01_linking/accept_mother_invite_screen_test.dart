import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';

void main() {
  tearDown(AppToast.dismiss);

  testWidgets('shows injected inviter + family names', (tester) async {
    await _pumpScreen(tester, inviterName: 'سامي', familyName: 'عائلة سامي');

    expect(
      find.textContaining('سامي يدعوك للانضمام إلى «عائلة سامي»'),
      findsOneWidget,
    );
    expect(find.textContaining('عبدالله'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);
    expect(find.textContaining('خالد'), findsNothing);
  });

  testWidgets('empty names → generic ARB fallbacks (Rule 23)', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.textContaining('ولي الأمر يدعوك للانضمام إلى «العائلة»'),
      findsOneWidget,
    );
    expect(find.textContaining('عبدالله'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.text('مستواك: مشاركة'), findsOneWidget);
    expect(
      find.textContaining('ترين كل شيء · توافقين على الطلبات'),
      findsOneWidget,
    );
    expect(find.text('حقوقك الثابتة'), findsOneWidget);
  });

  testWidgets('accept sets mother role + toast + → /scr-fat-028', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-fat-009',
      routes: [
        GoRoute(
          path: '/scr-fat-009',
          builder: (context, state) => AcceptMotherInviteScreen(
            inviterName: 'سامي',
            familyName: 'عائلة سامي',
            inviteeFirstName: 'سارة',
            roleController: role,
          ),
        ),
        GoRoute(
          path: '/scr-fat-028',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-028',
            title: 'إعداد الطوارئ',
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

    expect(role.value, AppRole.father);

    await tester.tap(find.byKey(const Key('accept_mother_invite_accept')));
    await tester.pump();

    expect(role.value, AppRole.mother);
    expect(
      find.textContaining(
        'أهلًا سارة — أنتِ الآن شريكة التوجيه بمستوى «مشاركة»',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('نوال'), findsNothing);

    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-028');
    expect(find.byType(PlaceholderScreen), findsOneWidget);

    await _settleTimers(tester);
  });

  testWidgets('decline → toast + /scr-shr-001', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-009',
      routes: [
        GoRoute(
          path: '/scr-fat-009',
          builder: (context, state) => const AcceptMotherInviteScreen(
            inviterName: 'سامي',
            familyName: 'عائلة سامي',
          ),
        ),
        GoRoute(
          path: '/scr-shr-001',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-SHR-001',
            title: 'شاشة الترحيب',
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

    await tester.tap(find.byKey(const Key('accept_mother_invite_decline')));
    await tester.pump();

    expect(find.textContaining('تبقى الدعوة صالحة أسبوعًا'), findsOneWidget);
    expect(find.textContaining('سامي يستطيع تذكيرك'), findsOneWidget);
    expect(find.textContaining('عبدالله'), findsNothing);

    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-001');
    expect(find.byType(PlaceholderScreen), findsOneWidget);

    await _settleTimers(tester);
  });

  testWidgets('accept without invitee uses generic welcome toast', (
    tester,
  ) async {
    final role = RoleController(AppRole.father);
    final router = GoRouter(
      initialLocation: '/scr-fat-009',
      routes: [
        GoRoute(
          path: '/scr-fat-009',
          builder: (context, state) => AcceptMotherInviteScreen(
            inviterName: 'سامي',
            familyName: 'عائلة سامي',
            roleController: role,
          ),
        ),
        GoRoute(
          path: '/scr-fat-028',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-028',
            title: 'إعداد الطوارئ',
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

    await tester.tap(find.byKey(const Key('accept_mother_invite_accept')));
    await tester.pump();

    expect(
      find.textContaining('أهلًا — أنتِ الآن شريكة التوجيه بمستوى «مشاركة»'),
      findsOneWidget,
    );
    expect(find.textContaining('نوال'), findsNothing);
    expect(role.value, AppRole.mother);

    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-028');

    await _settleTimers(tester);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  String inviterName = '',
  String familyName = '',
  String inviteeFirstName = '',
  VoidCallback? onAccept,
  VoidCallback? onDecline,
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
      home: AcceptMotherInviteScreen(
        inviterName: inviterName,
        familyName: familyName,
        inviteeFirstName: inviteeFirstName,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _settleTimers(WidgetTester tester) async {
  AppToast.dismiss();
  await tester.pump(const Duration(milliseconds: 2600));
}
