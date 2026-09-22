import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/features/n02_day/child_chats_mock.dart';
import 'package:family_os/features/n02_day/child_chats_repository.dart';
import 'package:family_os/features/n02_day/child_chats_screen.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';

void main() {
  testWidgets('SCR-CHD-007 empty → AppEmptyState + honesty + SOS ungated',
      (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(),
          roleOverride: AppRole.child,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.body), findsNothing);
    expect(find.byKey(ChildChatsKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(ChildChatsKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-CHD-007 one conversation', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.one,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.body), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.row('c_family')), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.callContactsCta), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.safeCircleBanner), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.row('c_father')), findsNothing);
  });

  testWidgets('SCR-CHD-007 many + pinned family first + honesty',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.many,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.body), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.safeCircleBanner), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.row('c_family')), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.row('c_father')), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.row('c_mother')), findsOneWidget);

    final familyY =
        tester.getTopLeft(find.byKey(ChildChatsKeys.row('c_family'))).dy;
    final fatherY =
        tester.getTopLeft(find.byKey(ChildChatsKeys.row('c_father'))).dy;
    expect(familyY < fatherY, isTrue);
  });

  testWidgets('SCR-CHD-007 row → CHD-008 with chatWith', (tester) async {
    ConversationThread? opened;
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.many,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
          onOpenChat: (t) => opened = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ChildChatsKeys.row('c_father')));
    await tester.tap(find.byKey(ChildChatsKeys.row('c_father')));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.id, 'c_father');
    expect(opened!.chatWith, 'father');
  });

  testWidgets('SCR-CHD-007 call contacts CTA', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.one,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
          onCallContacts: () => called = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildChatsKeys.callContactsCta));
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });

  testWidgets('SCR-CHD-007 parent lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.parentLean), findsOneWidget);
    expect(find.byKey(ChildChatsKeys.body), findsNothing);
    expect(find.byKey(ChildChatsKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-CHD-007 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryChildChatsRepository(failLoad: true);
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: repo,
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    repo.seed(ChildChatsMock.many);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ChildChatsKeys.body), findsOneWidget);
  });

  testWidgets('SCR-CHD-007 chat usable ignores billing seam', (tester) async {
    ConversationThread? opened;
    await tester.pumpWidget(
      _app(
        child: ChildChatsScreen(
          repository: InMemoryChildChatsRepository(
            initial: ChildChatsMock.one,
          ),
          roleOverride: AppRole.child,
          chatAvailability: const AlwaysOnChatAvailability(),
          onSos: () {},
          onOpenChat: (t) => opened = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ChildChatsKeys.row('c_family')));
    await tester.pumpAndSettle();
    expect(opened, isNotNull);
    expect(stage1ChatAvailability.isUsable, isTrue);
  });

  test('SCR-CHD-007 stage1 repo defaults empty (Rule 23)', () async {
    final snap = await InMemoryChildChatsRepository().load();
    expect(snap.isEmpty, isTrue);
  });

  test('SCR-CHD-007 mock has no planted names (Rule 23)', () {
    const forbidden = ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله'];
    for (final t in ChildChatsMock.many.threads) {
      for (final name in forbidden) {
        expect(t.title.contains(name), isFalse, reason: t.title);
        expect(t.preview.contains(name), isFalse, reason: t.preview);
      }
    }
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
