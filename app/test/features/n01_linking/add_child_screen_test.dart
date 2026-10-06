import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/app_runtime.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/core/runtime/identity_source.dart';
import 'package:family_os/features/n01_linking/add_child_screen.dart';

import '../shared_onboarding/onboarding_test_host.dart';

const _childId = '22222222-2222-4222-8222-222222222222';

IdentitySnapshot _remoteSnapshot() => IdentitySnapshot(
  authority: IdentityAuthority.remoteAuthoritative,
  accountId: AccountId('acct-1'),
  familyId: FamilyId(kTestFamilyId),
  role: AppRole.father,
  isPrimaryOwner: true,
);

List<GoRoute> _routes() => [
  GoRoute(
    path: '/scr-fat-003',
    builder: (context, state) => const AddChildScreen(),
  ),
  GoRoute(
    path: '/scr-fat-004',
    builder: (context, state) =>
        Scaffold(body: Text('pair:${state.uri.query}')),
  ),
  placeholderRoute('/scr-fat-001', 'SCR-FAT-001'),
  placeholderRoute('/scr-fat-002', 'SCR-FAT-002'),
  placeholderRoute('/scr-shr-003', 'SCR-SHR-003'),
];

(AppRuntime, RecordingChildProfileSource) _runtime({
  FamilyChildProfileCreateResult result =
      const FamilyChildProfileCreateResult.created(childId: _childId),
  bool manual = false,
  IdentitySnapshot? snapshot,
}) {
  final source = RecordingChildProfileSource(result: result, manual: manual);
  final identity = StaticIdentitySource(snapshot ?? _remoteSnapshot());
  final runtime = AppRuntime(identity: identity, childProfiles: source);
  addTearDown(runtime.dispose);
  return (runtime, source);
}

void main() {
  testWidgets('empty name: submit disabled, inline error after submit tap', (
    tester,
  ) async {
    final (runtime, source) = _runtime();
    await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    final btn = tester.widget<PrimaryBtn>(find.byKey(AddChildKeys.submit));
    expect(btn.onPressed, isNull);

    await tester.enterText(find.byKey(AddChildKeys.name), 'س');
    await tester.enterText(find.byKey(AddChildKeys.name), '   ');
    await tester.pump();
    expect(find.text('أدخل اسم الطفل.'), findsOneWidget);
    expect(source.calls, isEmpty);
  });

  testWidgets('uses a compact age dropdown and keeps a safe back route', (
    tester,
  ) async {
    final (runtime, _) = _runtime();
    final router = await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );

    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-002');
  });

  testWidgets('saves exactly the chosen draft and routes to pairing', (
    tester,
  ) async {
    final (runtime, source) = _runtime();
    final router = await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );

    await tester.enterText(find.byKey(AddChildKeys.name), ' سارة ');
    await tester.ensureVisible(find.byKey(AddChildKeys.age));
    await tester.tap(find.byKey(AddChildKeys.age));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 سنة').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddChildKeys.character(3)));
    await tester.ensureVisible(find.byKey(AddChildKeys.color(4)));
    await tester.tap(find.byKey(AddChildKeys.color(4)));
    await tester.pump();

    // Live preview reflects the draft.
    expect(find.text('سارة'), findsOneWidget);
    // The selected age is visible in both the compact dropdown and preview.
    expect(find.text('7 سنة'), findsNWidgets(2));

    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();

    expect(source.calls, hasLength(1));
    final call = source.calls.single;
    expect(call.familyId, kTestFamilyId);
    expect(call.draft.displayName, 'سارة');
    expect(call.draft.ageYears, 7);
    expect(call.draft.avatarEmoji, kAddChildCharacters[3]);
    expect(call.draft.themeColor, 'mint');
    expect(call.idempotencyKey, isNotEmpty);
    expect(router.state.uri.path, '/scr-fat-004');
    expect(router.state.uri.queryParameters, {
      'childId': _childId,
      'childName': 'سارة',
      'source': 'server',
    });
  });

  testWidgets('double tap while saving creates exactly one child', (
    tester,
  ) async {
    final (runtime, source) = _runtime(manual: true);
    await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'عمر');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pump();

    // Busy state: the PrimaryBtn is gone, a progress label is shown.
    expect(find.byType(PrimaryBtn), findsNothing);
    expect(find.text('جارٍ الحفظ…'), findsOneWidget);
    await tester.tap(find.byKey(AddChildKeys.submit), warnIfMissed: false);
    await tester.tap(find.byKey(AddChildKeys.submit), warnIfMissed: false);
    await tester.pump();
    expect(source.calls, hasLength(1));

    // Fields are locked while saving.
    expect(
      tester.widget<TextField>(find.byKey(AddChildKeys.name)).enabled,
      isFalse,
    );

    source.complete();
    await tester.pumpAndSettle();
    expect(source.calls, hasLength(1));
  });

  testWidgets('network failure: inline notice, retry reuses idempotency key', (
    tester,
  ) async {
    final (runtime, source) = _runtime(
      result: const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.networkUnavailable,
      ),
    );
    final router = await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'ليان');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/scr-fat-003');
    expect(find.byKey(AddChildKeys.notice), findsOneWidget);
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
    expect(find.byKey(AddChildKeys.noticeAction), findsOneWidget);
    // The typed name survives the failure.
    expect(
      tester.widget<TextField>(find.byKey(AddChildKeys.name)).controller!.text,
      'ليان',
    );

    source.result = const FamilyChildProfileCreateResult.created(
      childId: _childId,
    );
    await tester.tap(find.byKey(AddChildKeys.noticeAction));
    await tester.pumpAndSettle();

    expect(source.calls, hasLength(2));
    expect(source.calls[0].idempotencyKey, source.calls[1].idempotencyKey);
    expect(router.state.uri.path, '/scr-fat-004');
  });

  testWidgets('changing the draft after a failure rotates the key', (
    tester,
  ) async {
    final (runtime, source) = _runtime(
      result: const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.serviceUnavailable,
      ),
    );
    await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'أحمد');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddChildKeys.name), 'أحمد علي');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();
    expect(source.calls, hasLength(2));
    expect(
      source.calls[0].idempotencyKey,
      isNot(source.calls[1].idempotencyKey),
    );
  });

  testWidgets('access denied has no retry', (tester) async {
    final (runtime, _) = _runtime(
      result: const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.accessDenied,
      ),
    );
    await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'نور');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();
    expect(find.text('غير مسموح'), findsOneWidget);
    expect(find.byKey(AddChildKeys.noticeAction), findsNothing);
  });

  testWidgets('expired session offers sign-in and keeps the child draft', (
    tester,
  ) async {
    final (runtime, source) = _runtime(
      result: const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.sessionInvalid,
      ),
    );
    final router = await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'نور');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();

    expect(source.calls, hasLength(1));
    expect(find.text('انتهت الجلسة'), findsOneWidget);
    expect(find.text('تسجيل الدخول مجددًا'), findsOneWidget);

    await tester.tap(find.byKey(AddChildKeys.noticeAction));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-003');
    expect(router.state.uri.queryParameters['resume'], '/scr-fat-003');

    router.pop(true);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-003');
    expect(
      tester.widget<TextField>(find.byKey(AddChildKeys.name)).controller!.text,
      'نور',
    );
    expect(find.byKey(AddChildKeys.notice), findsNothing);
  });

  testWidgets('no active server family → honest redirect, nothing created', (
    tester,
  ) async {
    final (runtime, source) = _runtime(
      snapshot: const IdentitySnapshot.unavailable(),
    );
    final router = await pumpWithRouter(
      tester,
      runtime: runtime,
      initialLocation: '/scr-fat-003',
      routes: _routes(),
    );
    await tester.enterText(find.byKey(AddChildKeys.name), 'نور');
    await tester.pump();
    await scrollAndTap(tester, find.byKey(AddChildKeys.submit));
    await tester.pumpAndSettle();

    expect(source.calls, isEmpty);
    expect(find.text('لا توجد عائلة نشطة'), findsOneWidget);
    await tester.tap(find.byKey(AddChildKeys.noticeAction));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-fat-001');
  });
}
