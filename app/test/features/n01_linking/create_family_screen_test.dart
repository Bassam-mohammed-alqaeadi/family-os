import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_creation_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/features/n01_linking/create_family_create.dart';
import 'package:family_os/features/n01_linking/create_family_screen.dart';

import 'create_family_mocks.dart';

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
          builder: (context, state) =>
              CreateFamilyScreen(createFamily: mockCreateFamilySuccess),
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

  testWidgets('real path: server-confirmed create reports success once', (
    tester,
  ) async {
    final source = _FakeFamilyCreationSource(
      results: const [
        FamilyCreateResult.created(
          familyId: '11111111-1111-4111-8111-111111111111',
          displayName: 'عائلة النور',
        ),
      ],
    );
    var created = 0;
    await _pumpServerCreateFamily(
      tester,
      source: source,
      onCreated: () => created++,
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة النور',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(created, 1);
    expect(source.calls, 1);
    expect(source.lastDisplayName, 'عائلة النور');
    expect(source.lastIdempotencyKey, isNotEmpty);
    expect(find.byType(AppErrorState), findsNothing);
  });

  testWidgets('real path: server refusal renders error and no success', (
    tester,
  ) async {
    final source = _FakeFamilyCreationSource(
      results: const [
        FamilyCreateResult.failed(FamilyCreateFailure.networkUnavailable),
      ],
    );
    var created = 0;
    await _pumpServerCreateFamily(
      tester,
      source: source,
      onCreated: () => created++,
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الانقطاع',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(created, 0);
    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('تعذّر الاتصال'), findsWidgets);
  });

  testWidgets('real path: a retry reuses the idempotency key for one name', (
    tester,
  ) async {
    final source = _FakeFamilyCreationSource(
      results: const [
        FamilyCreateResult.failed(FamilyCreateFailure.serviceUnavailable),
        FamilyCreateResult.created(
          familyId: '11111111-1111-4111-8111-111111111111',
          displayName: 'عائلة الإعادة',
        ),
      ],
    );
    var created = 0;
    await _pumpServerCreateFamily(
      tester,
      source: source,
      onCreated: () => created++,
    );

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة الإعادة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();
    expect(source.calls, 1);
    expect(find.byType(AppErrorState), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(created, 1);
    expect(source.calls, 2);
    expect(source.idempotencyKeys[0], source.idempotencyKeys[1]);
    expect(find.byType(AppErrorState), findsNothing);
  });

  testWidgets('real path: no configured session saves nothing and says so', (
    tester,
  ) async {
    await _pumpCreateFamily(tester);

    await tester.enterText(
      find.byKey(const Key('create_family_name')),
      'عائلة بلا جلسة',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_family_submit')));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الحفظ — حاول مرة أخرى'), findsOneWidget);
    expect(find.byType(AppErrorState), findsNothing);
    expect(find.byType(PlaceholderScreen), findsNothing);
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

/// The real path: the screen with an [AppScope]-composed [FamilyCreationSource]
/// and no injected mock seam, exactly as the product route composes it.
Future<void> _pumpServerCreateFamily(
  WidgetTester tester, {
  required FamilyCreationSource source,
  VoidCallback? onCreated,
}) async {
  final runtime = AppRuntime(
    identity: _StaticIdentitySource(const IdentitySnapshot.unavailable()),
    familyCreation: source,
  );
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    AppScope(
      runtime: runtime,
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
        home: CreateFamilyScreen(onCreated: onCreated),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _StaticIdentitySource extends ChangeNotifier
    implements IdentitySource {
  _StaticIdentitySource(this._value);

  final IdentitySnapshot _value;

  @override
  IdentitySnapshot get value => _value;

  @override
  Future<IdentitySnapshot> refresh() async => _value;
}

/// Answers with exactly the results a test hands it, and records every call so
/// the test can prove what the screen sent — not what it claims it sent.
final class _FakeFamilyCreationSource implements FamilyCreationSource {
  _FakeFamilyCreationSource({required List<FamilyCreateResult> results})
    : _results = List.of(results);

  final List<FamilyCreateResult> _results;
  final List<String> idempotencyKeys = [];
  int calls = 0;
  String? lastDisplayName;

  String get lastIdempotencyKey => idempotencyKeys.last;

  @override
  Future<FamilyCreateResult> createFamily({
    required String displayName,
    required String idempotencyKey,
  }) async {
    lastDisplayName = displayName;
    idempotencyKeys.add(idempotencyKey);
    calls++;
    if (_results.isEmpty) {
      return const FamilyCreateResult.failed(FamilyCreateFailure.unavailable);
    }
    return _results.removeAt(0);
  }

  @override
  void dispose() {}
}
