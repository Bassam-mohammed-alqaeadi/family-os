import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/features/n02_day/conversations_list_mock.dart';
import 'package:family_os/features/n02_day/conversations_list_repository.dart';
import 'package:family_os/features/n02_day/conversations_list_screen.dart';

void main() {
  testWidgets('SCR-FAT-021 empty → AppEmptyState + honesty + SOS ungated',
      (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.body), findsNothing);
    expect(find.byKey(ConversationsListKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(ConversationsListKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-021 one conversation', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.one,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.body), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_family')), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.newChatCta), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_mother')), findsNothing);
  });

  testWidgets('SCR-FAT-021 many + pinned family first + honesty',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.many,
          ),
          roleOverride: AppRole.mother,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.body), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.sectionHeader), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_family')), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_mother')), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_child_a')), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_child_b')), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.row('c_child_c')), findsOneWidget);

    // Pinned family appears before DM rows in tree order.
    final familyY = tester
        .getTopLeft(find.byKey(ConversationsListKeys.row('c_family')))
        .dy;
    final motherY = tester
        .getTopLeft(find.byKey(ConversationsListKeys.row('c_mother')))
        .dy;
    expect(familyY < motherY, isTrue);
  });

  testWidgets('SCR-FAT-021 row → FAT-022 with chatWith', (tester) async {
    ConversationThread? opened;
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onOpenChat: (t) => opened = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(ConversationsListKeys.row('c_child_a')));
    await tester.tap(find.byKey(ConversationsListKeys.row('c_child_a')));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.id, 'c_child_a');
    expect(opened!.chatWith, 'child_a');
  });

  testWidgets('SCR-FAT-021 new chat CTA', (tester) async {
    var newChat = false;
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.one,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onNewChat: () => newChat = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConversationsListKeys.newChatCta));
    await tester.pumpAndSettle();
    expect(newChat, isTrue);
  });

  testWidgets('SCR-FAT-021 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.many,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.childLean), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.body), findsNothing);
    expect(find.byKey(ConversationsListKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-021 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryConversationsListRepository(failLoad: true);
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    repo.seed(ConversationsListMock.many);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationsListKeys.body), findsOneWidget);
  });

  testWidgets('SCR-FAT-021 chat usable ignores billing seam', (tester) async {
    ConversationThread? opened;
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.one,
          ),
          roleOverride: AppRole.father,
          chatAvailability: const AlwaysOnChatAvailability(),
          onSos: () {},
          onOpenChat: (t) => opened = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConversationsListKeys.row('c_family')));
    await tester.pumpAndSettle();
    expect(opened, isNotNull);
    expect(stage1ChatAvailability.isUsable, isTrue);
  });

  testWidgets('SCR-FAT-021 family stays pinned — never a toggle', (tester) async {
    final repo = InMemoryConversationsListRepository(
      initial: ConversationsListMock.many,
    );
    // A user attempt to unpin the family is a no-op: it is a fixed right.
    await repo.setPinned('c_family', false);
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snap = await repo.load();
    expect(snap.threads.firstWhere((t) => t.id == 'c_family').pinned, isTrue);
    expect(snap.ordered.first.id, 'c_family');

    // The row menu offers no pin toggle for the family thread.
    await tester.tap(find.byKey(ConversationsListKeys.rowMenu('c_family')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('conversations_list_action_pin')),
      findsNothing,
    );
    expect(find.text('المحادثة العائلية مثبتة دائمًا'), findsOneWidget);
  });

  testWidgets('SCR-FAT-021 row mute quick action persists', (tester) async {
    final repo = InMemoryConversationsListRepository(
      initial: ConversationsListMock.many,
    );
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConversationsListKeys.rowMenu('c_child_a')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('conversations_list_action_muteEightHours')),
    );
    await tester.pumpAndSettle();

    final snap = await repo.load();
    expect(snap.threads.firstWhere((t) => t.id == 'c_child_a').muted, isTrue);
  });

  testWidgets('SCR-FAT-021 voice preview is described in words', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🎤 رسالة صوتية'), findsOneWidget);
  });

  testWidgets('SCR-FAT-021 no presence or e2e badge', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: InMemoryConversationsListRepository(
            initial: ConversationsListMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('متصل'), findsNothing);
    expect(find.textContaining('آخر ظهور'), findsNothing);
    expect(find.textContaining('مشفّرة'), findsNothing);
  });

  testWidgets('SCR-FAT-021 a locked child thread still shows for the parent',
      (tester) async {
    final repo = InMemoryConversationsListRepository(
      initial: ConversationsListSnapshot(
        threads: const [
          ConversationThread(
            id: 'c_family',
            chatWith: 'family',
            title: 'عائلة ١',
            preview: '',
            timeLabel: '',
            emoji: '👨‍👩‍👧‍👦',
            swatch: ConversationSwatch.family,
            isFamily: true,
            pinned: true,
          ),
          ConversationThread(
            id: 'c_child_a',
            chatWith: 'child_a',
            title: 'ابن ١',
            preview: '',
            timeLabel: '',
            emoji: '🦁',
            swatch: ConversationSwatch.purple,
            locked: true,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      _app(
        child: ConversationsListScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // S-COM-009 — a lock never hides the child's thread from the parent.
    expect(find.byKey(ConversationsListKeys.row('c_child_a')), findsOneWidget);
    final snap = await repo.load();
    expect(
      snap.threads.firstWhere((t) => t.id == 'c_child_a').visibleToParent,
      isTrue,
    );
  });

  test('SCR-FAT-021 stage1 repo defaults empty (Rule 23)', () async {
    final snap = await InMemoryConversationsListRepository().load();
    expect(snap.isEmpty, isTrue);
  });

  test('SCR-FAT-021 mock has no planted names (Rule 23)', () {
    const forbidden = ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله'];
    for (final t in ConversationsListMock.many.threads) {
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
