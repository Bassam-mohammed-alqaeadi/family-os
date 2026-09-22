import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';
import 'package:family_os/features/n01_linking/create_family_screen.dart';

void main() {
  testWidgets('empty name disables submit; no sample default in field', (
    tester,
  ) async {
    var created = 0;
    await _pumpCreateFamily(tester, onCreated: () => created++);

    final nameField = tester.widget<TextField>(
      find.byKey(const Key('create_family_name')),
    );
    expect(nameField.controller!.text, isEmpty);
    expect(find.text('عائلة عبدالله'), findsNothing);

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('create_family_submit')),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pump();
    expect(created, 0);
  });

  testWidgets('trial banner text is present', (tester) async {
    await _pumpCreateFamily(tester);

    expect(find.byKey(const Key('create_family_trial_banner')), findsOneWidget);
    expect(
      find.textContaining('تبدأ تجربتك المجانية الكاملة الآن'),
      findsOneWidget,
    );
    expect(find.textContaining('الاستغاثة والسلامة'), findsOneWidget);
  });

  testWidgets('filled name → /scr-fat-002', (tester) async {
    final router = GoRouter(
      initialLocation: '/scr-fat-001',
      routes: [
        GoRoute(
          path: '/scr-fat-001',
          builder: (context, state) => const CreateFamilyScreen(),
        ),
        GoRoute(
          path: '/scr-fat-002',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-FAT-002',
            title: 'معالج الإعداد',
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
      find.byKey(const Key('create_family_name')),
      'عائلة النور',
    );
    await tester.pump();

    final btn = tester.widget<PrimaryBtn>(
      find.byKey(const Key('create_family_submit')),
    );
    expect(btn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-002');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-FAT-002'), findsWidgets);
  });

  testWidgets('AC1: forced network fail renders AppErrorState (not snackbar)', (
    tester,
  ) async {
    await _pumpCreateFamily(
      tester,
      createFamily: mockCreateFamilyFail(AppErrorKind.network),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الاختبار',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_family_error')), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('تعذّر الاتصال'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
    // Amber composition — title uses amberDeep, not coral danger snackbar.
    expect(find.textContaining('لم نستطع الوصول للخادم'), findsOneWidget);
  });

  testWidgets('AC2: Retry CTA re-invokes create', (tester) async {
    var attempts = 0;
    await _pumpCreateFamily(
      tester,
      createFamily: (name) async {
        attempts++;
        if (attempts == 1) {
          throw const CreateFamilyException(AppErrorKind.network);
        }
      },
      onCreated: () {},
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الإعادة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.byType(AppErrorState), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(AppErrorState), findsNothing);
  });

  testWidgets('AC3: success path unchanged with injectable create', (
    tester,
  ) async {
    var created = 0;
    var createCalls = 0;
    await _pumpCreateFamily(
      tester,
      createFamily: (name) async {
        createCalls++;
        expect(name, 'عائلة النجاح');
      },
      onCreated: () => created++,
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة النجاح',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(createCalls, 1);
    expect(created, 1);
    expect(find.byType(AppErrorState), findsNothing);
  });

  testWidgets('AC4: Retry CTA has Semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await _pumpCreateFamily(
        tester,
        createFamily: mockCreateFamilyFail(AppErrorKind.network),
      );

      await tester.enterText(
        find.byKey(const Key('create_family_name')),
        'عائلة الوصولية',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('create_family_submit')));
      await tester.pumpAndSettle();

      final semantics =
          tester.getSemantics(find.byKey(const Key('app_error_retry')));
      expect(semantics.label, contains('إعادة المحاولة'));
    } finally {
      handle.dispose();
    }
  });

  testWidgets('timeout failure uses distinct copy', (tester) async {
    await _pumpCreateFamily(
      tester,
      createFamily: mockCreateFamilyFail(AppErrorKind.timeout),
    );
    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة المهلة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.text('انتهت مهلة الاتصال'), findsWidgets);
    expect(find.textContaining('وقتًا أطول من المتوقع'), findsOneWidget);
    expect(find.text('تعذّر الاتصال'), findsNothing);
    expect(find.text('تعذّر إنشاء العائلة'), findsNothing);
  });

  testWidgets('validation 4xx failure uses distinct copy', (tester) async {
    await _pumpCreateFamily(
      tester,
      createFamily: mockCreateFamilyFail(AppErrorKind.validation),
    );
    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة التحقق',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.text('تعذّر إنشاء العائلة'), findsWidgets);
    expect(find.textContaining('تحقق من اسم العائلة'), findsOneWidget);
    expect(find.text('انتهت مهلة الاتصال'), findsNothing);
  });

  testWidgets('offline variant is honest needs-network (no queue promise)', (
    tester,
  ) async {
    await _pumpCreateFamily(
      tester,
      createFamily: mockCreateFamilyFail(AppErrorKind.offline),
    );
    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة دون اتصال',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.text('يلزم اتصال بالإنترنت'), findsWidgets);
    expect(find.textContaining('لا يمكن حفظ الطلب دون اتصال'), findsOneWidget);
  });
}

Future<void> _pumpCreateFamily(
  WidgetTester tester, {
  VoidCallback? onCreated,
  CreateFamilyFn? createFamily,
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
      home: CreateFamilyScreen(
        onCreated: onCreated,
        createFamily: createFamily,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
