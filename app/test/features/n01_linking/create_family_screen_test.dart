import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
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

  testWidgets('unconfigured composition fails closed — no mock family', (
    tester,
  ) async {
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

    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    // Honest unavailability: no navigation, no fabricated family.
    expect(router.state.uri.path, '/scr-fat-001');
    expect(find.byType(PlaceholderScreen), findsNothing);
    expect(find.byKey(const Key('create_family_error')), findsOneWidget);
    expect(find.text('إنشاء العائلة غير مهيأ'), findsOneWidget);
    expect(find.textContaining('لا ننشئ عائلة وهمية'), findsOneWidget);
  });

  testWidgets('configured real source → server-confirmed create navigates', (
    tester,
  ) async {
    final source = _FakeFamilyCreationSource(
      const FamilyCreationResult.created(
        familyId: '11111111-1111-4111-8111-111111111111',
        displayName: 'عائلة النور',
      ),
    );
    final router = GoRouter(
      initialLocation: '/scr-fat-001',
      routes: [
        GoRoute(
          path: '/scr-fat-001',
          builder: (context, state) => AppScope(
            runtime: AppRuntime(
              identity: _FakeIdentitySource(_remoteIdentitySnapshot()),
              familyCreation: source,
            ),
            child: const CreateFamilyScreen(),
          ),
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

    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(source.calls, hasLength(1));
    expect(source.calls.single.displayName, 'عائلة النور');
    expect(source.calls.single.idempotencyKey, isNotEmpty);
    expect(router.state.uri.path, '/scr-fat-002');
    expect(find.byType(PlaceholderScreen), findsOneWidget);
    expect(find.text('SCR-FAT-002'), findsWidgets);
  });

  testWidgets('server session failure renders explicit session error', (
    tester,
  ) async {
    await _pumpWithSource(
      tester,
      source: _FakeFamilyCreationSource(
        const FamilyCreationResult.failed(
          FamilyCreationOutcome.unauthenticated,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الجلسة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('انتهت الجلسة'), findsOneWidget);
    expect(find.textContaining('سجّل الدخول مرة أخرى'), findsOneWidget);
  });

  testWidgets('idempotency conflict renders explicit conflict error', (
    tester,
  ) async {
    await _pumpWithSource(
      tester,
      source: _FakeFamilyCreationSource(
        const FamilyCreationResult.failed(FamilyCreationOutcome.conflict),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة التعارض',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('تعذّر تأكيد المحاولة'), findsOneWidget);
    expect(find.textContaining('راجع اسم العائلة'), findsOneWidget);
  });

  testWidgets('server unavailability renders explicit service error', (
    tester,
  ) async {
    await _pumpWithSource(
      tester,
      source: _FakeFamilyCreationSource(
        const FamilyCreationResult.failed(
          FamilyCreationOutcome.serviceUnavailable,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الخدمة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('الخدمة غير متاحة مؤقتًا'), findsOneWidget);
  });

  testWidgets('access denied renders explicit denial error', (tester) async {
    await _pumpWithSource(
      tester,
      source: _FakeFamilyCreationSource(
        const FamilyCreationResult.failed(FamilyCreationOutcome.denied),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الرفض',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('الوصول غير متاح'), findsOneWidget);
    expect(find.textContaining('لا يسمح هذا الحساب'), findsOneWidget);
  });

  testWidgets('unexpected server response renders explicit error', (
    tester,
  ) async {
    await _pumpWithSource(
      tester,
      source: _FakeFamilyCreationSource(
        const FamilyCreationResult.failed(
          FamilyCreationOutcome.invalidResponse,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الاستجابة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('استجابة غير متوقعة'), findsOneWidget);
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

      final semantics = tester.getSemantics(
        find.byKey(const Key('app_error_retry')),
      );
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
  testWidgets('name input hard-caps at 120 chars with live counter', (
    tester,
  ) async {
    var created = 0;
    await _pumpCreateFamily(tester, onCreated: () => created++);

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'ع' * 121,
    );
    await tester.pump();

    // maxLength formatter truncates the input; counter reports the cap.
    final field = tester.widget<TextField>(
      find.byKey(const Key('create_family_name')),
    );
    expect(field.controller!.text.runes.length, 120);
    expect(find.text('120 / 120'), findsOneWidget);
    expect(
      tester
          .widget<PrimaryBtn>(find.byKey(const Key('create_family_submit')))
          .onPressed,
      isNotNull,
    );
    expect(created, 0);
  });

  testWidgets('defensive gate blocks submit when controller exceeds 120', (
    tester,
  ) async {
    var created = 0;
    await _pumpCreateFamily(tester, onCreated: () => created++);

    final field = tester.widget<TextField>(
      find.byKey(const Key('create_family_name')),
    );
    field.controller!.value = TextEditingValue(text: 'ع' * 121);
    await tester.pump();

    expect(
      tester
          .widget<PrimaryBtn>(find.byKey(const Key('create_family_submit')))
          .onPressed,
      isNull,
    );
    expect(created, 0);
  });

  testWidgets('name field exposes a live length counter', (tester) async {
    await _pumpCreateFamily(tester);

    await tester.enterText(find.byKey(const Key('create_family_name')), 'نور');
    await tester.pump();

    expect(find.text('3 / 120'), findsOneWidget);
  });
}

Future<void> _pumpWithSource(
  WidgetTester tester, {
  required FamilyCreationSource source,
  VoidCallback? onCreated,
}) async {
  final runtime = AppRuntime(
    identity: _FakeIdentitySource(_remoteIdentitySnapshot()),
    familyCreation: source,
  );
  addTearDown(runtime.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppScope(
        runtime: runtime,
        child: CreateFamilyScreen(onCreated: onCreated),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

IdentitySnapshot _remoteIdentitySnapshot() {
  return IdentitySnapshot(
    authority: IdentityAuthority.remoteAuthoritative,
    accountId: AccountId('acc_real'),
    familyId: FamilyId('fam_real'),
    role: AppRole.father,
    motherLevel: MotherLevel.full,
    isPrimaryOwner: true,
  );
}

final class _FakeIdentitySource extends ChangeNotifier
    implements IdentitySource {
  _FakeIdentitySource(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

final class _FakeFamilyCreationSource implements FamilyCreationSource {
  _FakeFamilyCreationSource(this._result);

  final FamilyCreationResult _result;
  final List<({String displayName, String idempotencyKey})> calls = [];

  @override
  Future<FamilyCreationResult> create({
    required String displayName,
    required String idempotencyKey,
  }) async {
    calls.add((displayName: displayName, idempotencyKey: idempotencyKey));
    return _result;
  }
}
