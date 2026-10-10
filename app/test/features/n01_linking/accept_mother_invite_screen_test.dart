import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/app/placeholder_screen.dart';
import 'package:family_os/app/role_controller.dart';
import 'package:family_os/core/design/components/app_toast.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/family_invite_code_source.dart';
import 'package:family_os/features/n01_linking/accept_mother_invite_screen.dart';

import 'invite_code_fakes.dart';

const _joined = InviteCodeRedeemResult.joined(
  familyId: inviteTestFamilyUuid,
  familyDisplayName: 'عائلة الدعوة',
  role: 'co_guardian',
);

/// SCR-FAT-009 — joining with an invite code. "You joined" exists only after the server
/// confirmed the membership; nothing is recorded on the phone first.
void main() {
  tearDown(AppToast.dismiss);

  GoRouter routerFor(Widget screen) {
    final router = GoRouter(
      initialLocation: '/scr-fat-009',
      routes: [
        GoRoute(path: '/scr-fat-009', builder: (context, state) => screen),
        GoRoute(
          path: '/scr-fat-028',
          builder: (context, state) =>
              const PlaceholderScreen(screenId: 'SCR-FAT-028', title: 'الأم'),
        ),
        GoRoute(
          path: '/scr-shr-001',
          builder: (context, state) => const PlaceholderScreen(
            screenId: 'SCR-SHR-001',
            title: 'البداية',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('empty field disables join; no prefilled code or names', (
    tester,
  ) async {
    final source = FakeInviteCodeSource(redeemResults: [_joined]);
    await pumpWithInviteCodes(
      tester,
      source: source,
      home: const AcceptMotherInviteScreen(),
    );
    final field = tester.widget<TextField>(
      find.byKey(const Key('join_code_field')),
    );
    expect(field.controller!.text, isEmpty);
    final button = tester.widget<PrimaryBtn>(
      find.byKey(const Key('join_code_submit')),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('خالد'), findsNothing);
    expect(
      find.byKey(const Key('accept_mother_invite_local_honesty')),
      findsNothing,
    );
    expect(source.redeemed, isEmpty);
  });

  testWidgets('a malformed code is refused on the phone and never sent', (
    tester,
  ) async {
    final source = FakeInviteCodeSource(redeemResults: [_joined]);
    await pumpWithInviteCodes(
      tester,
      source: source,
      home: const AcceptMotherInviteScreen(),
    );
    await tester.enterText(find.byKey(const Key('join_code_field')), 'O0O0-1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('join_code_submit')));
    await tester.pumpAndSettle();
    expect(source.redeemed, isEmpty);
    expect(find.byKey(const Key('join_code_error_format')), findsOneWidget);
  });

  testWidgets(
    'server confirms → mother role, toast with the family name, /scr-fat-028',
    (tester) async {
      final source = FakeInviteCodeSource(redeemResults: [_joined]);
      final role = RoleController(AppRole.father);
      addTearDown(role.dispose);
      final router = routerFor(AcceptMotherInviteScreen(roleController: role));
      await pumpWithInviteCodes(tester, source: source, router: router);

      await tester.enterText(
        find.byKey(const Key('join_code_field')),
        ' abcde fghjk ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('join_code_submit')));
      await tester.pump();

      expect(
        source.redeemed.single.code,
        'ABCDEFGHJK',
        reason: 'the code is normalised before it is sent',
      );
      expect(find.textContaining('عائلة الدعوة'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/scr-fat-028');
      expect(role.value, AppRole.mother);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  for (final (failure, text) in [
    (InviteCodeFailure.notRedeemable, 'غير صحيح أو انتهت صلاحيته'),
    (InviteCodeFailure.alreadyMember, 'عضو في هذه العائلة بالفعل'),
    (InviteCodeFailure.rateLimited, 'محاولات كثيرة'),
    (InviteCodeFailure.sessionInvalid, 'سجّل الدخول بحسابك أولاً'),
    (InviteCodeFailure.unavailable, 'غير متصلة بالخادم'),
  ]) {
    testWidgets(
      'a refusal (${failure.name}) is said plainly and nobody joins',
      (tester) async {
        final source = FakeInviteCodeSource(
          redeemResults: [InviteCodeRedeemResult.failed(failure)],
        );
        final role = RoleController(AppRole.father);
        addTearDown(role.dispose);
        final router = routerFor(
          AcceptMotherInviteScreen(roleController: role),
        );
        await pumpWithInviteCodes(tester, source: source, router: router);

        await tester.enterText(
          find.byKey(const Key('join_code_field')),
          'ABCDE-FGHJK',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('join_code_submit')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(Key('join_code_error_${failure.name}')),
          findsOneWidget,
        );
        expect(find.textContaining(text), findsOneWidget);
        expect(router.state.uri.path, '/scr-fat-009');
        expect(
          role.value,
          AppRole.father,
          reason: 'a refused code never changes the role',
        );
      },
    );
  }

  testWidgets(
    'retrying the same code reuses its idempotency key; a new code gets a new one',
    (tester) async {
      final source = FakeInviteCodeSource(
        redeemResults: const [
          InviteCodeRedeemResult.failed(InviteCodeFailure.networkUnavailable),
          InviteCodeRedeemResult.failed(InviteCodeFailure.networkUnavailable),
          InviteCodeRedeemResult.failed(InviteCodeFailure.notRedeemable),
        ],
      );
      await pumpWithInviteCodes(
        tester,
        source: source,
        home: AcceptMotherInviteScreen(onJoined: (_) {}),
      );
      Future<void> submit(String code) async {
        await tester.enterText(find.byKey(const Key('join_code_field')), code);
        await tester.pump();
        await tester.tap(find.byKey(const Key('join_code_submit')));
        await tester.pumpAndSettle();
      }

      await submit('ABCDE-FGHJK');
      await submit('abcdefghjk');
      await submit('ZZZZZ-ZZZZZ');
      expect(source.redeemed, hasLength(3));
      expect(source.redeemed[0].key, source.redeemed[1].key);
      expect(source.redeemed[2].key, isNot(source.redeemed[0].key));
    },
  );

  testWidgets('decline → /scr-shr-001 without calling the server', (
    tester,
  ) async {
    final source = FakeInviteCodeSource();
    final router = routerFor(const AcceptMotherInviteScreen());
    await pumpWithInviteCodes(tester, source: source, router: router);
    await tester.ensureVisible(
      find.byKey(const Key('accept_mother_invite_decline')),
    );
    await tester.tap(find.byKey(const Key('accept_mother_invite_decline')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/scr-shr-001');
    expect(source.redeemed, isEmpty);
  });

  testWidgets('English locale renders the join flow', (tester) async {
    await pumpWithInviteCodes(
      tester,
      source: FakeInviteCodeSource(),
      home: const AcceptMotherInviteScreen(),
      locale: const Locale('en'),
    );
    expect(find.text('Join the family'), findsOneWidget);
    expect(find.textContaining('server confirms'), findsOneWidget);
  });
}
