import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/chat_availability.dart';
import 'package:family_os/features/n02_day/conversation_mock.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/conversation_screen.dart';

void main() {
  testWidgets('SCR-FAT-022 loads by chatWith=child_a', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.body), findsOneWidget);
    expect(find.byKey(ConversationKeys.bubble('a1')), findsOneWidget);
    expect(find.byKey(ConversationKeys.composer), findsOneWidget);
    // ADR-053 «نترك» — no false "🔒 مشفّرة طرفيًا" badge without key management.
    expect(find.byKey(ConversationKeys.encryptedTag), findsNothing);
    expect(find.byKey(ConversationKeys.toneBridge), findsOneWidget);
    expect(find.textContaining('ابن ١'), findsWidgets);
    // No presence or typing theatre.
    expect(find.textContaining('متصل'), findsNothing);
    expect(find.textContaining('يكتب'), findsNothing);
  });

  testWidgets('SCR-FAT-022 family branch + pin note + mother OK',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.mother,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.body), findsOneWidget);
    expect(find.byKey(ConversationKeys.familyPinNote), findsOneWidget);
    expect(find.byKey(ConversationKeys.bubble('f1')), findsOneWidget);
    expect(find.textContaining('شريكة ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-022 parametric peers mother/child_b/child_c',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);

    Future<void> open(String peer) async {
      await tester.pumpWidget(
        _app(
          child: ConversationScreen(
            chatWith: peer,
            repository: repo,
            roleOverride: AppRole.father,
            onSos: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open('mother');
    expect(find.byKey(ConversationKeys.bubble('m1')), findsOneWidget);

    await open('child_b');
    expect(find.byKey(ConversationKeys.bubble('b1')), findsOneWidget);

    await open('child_c');
    expect(find.byKey(ConversationKeys.bubble('c1')), findsOneWidget);
  });

  testWidgets('SCR-FAT-022 send mock message seam', (tester) async {
    String? sent;
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
          onSend: (t) => sent = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(ConversationKeys.input), 'مرحبا يا بطل');
    await tester.tap(find.byKey(ConversationKeys.send));
    await tester.pumpAndSettle();

    expect(sent, 'مرحبا يا بطل');
    expect(find.text('مرحبا يا بطل'), findsOneWidget);
    final refreshed = await repo.load('child_a');
    expect(refreshed!.messages.last.body, 'مرحبا يا بطل');
    expect(refreshed.messages.last.isMine, isTrue);
  });

  testWidgets('SCR-FAT-022 tone chip sends', (tester) async {
    String? sent;
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onSend: (t) => sent = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConversationKeys.toneChip(0)));
    await tester.pumpAndSettle();

    expect(sent, 'أحسنت يا بطل');
    expect(find.text('أحسنت يا بطل'), findsWidgets);
  });

  testWidgets('SCR-FAT-022 missing chatWith → empty', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.missingPeer), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(ConversationKeys.body), findsNothing);
    expect(find.byKey(ConversationKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-022 unknown peer → not found', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'unknown_peer',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.notFound), findsOneWidget);
    expect(find.byKey(ConversationKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-022 Rule 23 — empty repo no planted names',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: InMemoryConversationRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.notFound), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
  });

  testWidgets('SCR-FAT-022 Rule 23 — seeded uses generic labels only',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.body), findsOneWidget);
    expect(find.textContaining('خالد'), findsNothing);
    expect(find.textContaining('نورة'), findsNothing);
    expect(find.textContaining('سعد'), findsNothing);
    expect(find.textContaining('نوال'), findsNothing);
    expect(find.textContaining('عبدالله'), findsNothing);
  });

  testWidgets('SCR-FAT-022 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.childLean), findsOneWidget);
    expect(find.byKey(ConversationKeys.body), findsNothing);
    expect(find.byKey(ConversationKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-022 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryConversationRepository(
      initial: ConversationMock.all,
      failLoad: true,
    );
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.body), findsOneWidget);
  });

  testWidgets('SCR-FAT-022 P-4 SOS ungated on empty', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          repository: InMemoryConversationRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.missingPeer), findsOneWidget);
    await tester.tap(find.byKey(ConversationKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-022 UI-007 chat usable ignores billing', (tester) async {
    String? sent;
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: InMemoryConversationRepository(
            initial: ConversationMock.all,
          ),
          roleOverride: AppRole.father,
          chatAvailability: const AlwaysOnChatAvailability(),
          onSos: () {},
          onSend: (t) => sent = t,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(ConversationKeys.input), 'ok');
    await tester.tap(find.byKey(ConversationKeys.send));
    await tester.pumpAndSettle();

    expect(sent, 'ok');
    expect(stage1ChatAvailability.isUsable, isTrue);
    expect(stage1ChatAvailability.canSend, isTrue);
  });

  testWidgets('SCR-FAT-022 pinned bar + unpin clears it', (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.pinnedBar), findsOneWidget);
    await tester.tap(find.byKey(ConversationKeys.pinnedBarUnpin));
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.pinnedBar), findsNothing);
    final loaded = await repo.load('family');
    expect(loaded!.pinnedMessage, isNull);
  });

  testWidgets('SCR-FAT-022 ✓ sent then ✓✓ read — never a delivered tick',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // f3 is read in the fixture → ✓✓.
    expect(find.text('✓✓'), findsWidgets);

    await tester.enterText(find.byKey(ConversationKeys.input), 'رسالة جديدة');
    await tester.tap(find.byKey(ConversationKeys.send));
    await tester.pumpAndSettle();

    // A freshly sent message carries the single ✓.
    expect(find.text('✓'), findsWidgets);
  });

  testWidgets('SCR-FAT-022 tombstone in place + reply quote inside the bubble',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'peer_a',
          repository: InMemoryConversationRepository(initial: ConversationMock.all),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The deleted message keeps its place as a tombstone, not a hole.
    expect(find.byKey(ConversationKeys.bubble('p3')), findsOneWidget);
    expect(find.text('حُذفت هذه الرسالة'), findsWidgets);
    // The reply is quoted inside its bubble.
    expect(find.byKey(ConversationKeys.bubble('p2')), findsOneWidget);
    expect(find.textContaining('شفت الصورة؟'), findsWidgets);
  });

  testWidgets('SCR-FAT-022 long-press edits, author-only', (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(ConversationKeys.bubble('f3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat_action_edit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat_action_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('conversation_edit_field')),
      'نص معدّل',
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    final loaded = await repo.load('family');
    final edited = loaded!.messages.firstWhere((m) => m.id == 'f3');
    expect(edited.body, 'نص معدّل');
    expect(edited.edited, isTrue);
  });

  testWidgets('SCR-FAT-022 long-press deletes → tombstone in place',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'family',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(ConversationKeys.bubble('f3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_action_delete')));
    await tester.pumpAndSettle();

    final loaded = await repo.load('family');
    expect(loaded!.messages.firstWhere((m) => m.id == 'f3').deleted, isTrue);
    expect(find.text('حُذفت هذه الرسالة'), findsWidgets);
  });

  testWidgets('SCR-FAT-022 settings sheet applies wallpaper + theme to this chat',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ConversationKeys.settingsTag));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat_wallpaper_rose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_theme_teal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat_settings_done')));
    await tester.pumpAndSettle();

    final loaded = await repo.load('child_a');
    expect(loaded!.wallpaper, 'rose');
    expect(loaded.bubbleTheme, 'teal');
  });

  testWidgets('SCR-FAT-022 receipts mandatory with a parent, toggle between peers',
      (tester) async {
    final repo = InMemoryConversationRepository(initial: ConversationMock.all);
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'child_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ConversationKeys.settingsTag));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('chat_receipts_mandatory')));
    expect(find.byKey(const Key('chat_receipts_mandatory')), findsOneWidget);
    expect(find.byKey(const Key('chat_receipts_switch')), findsNothing);
    await tester.tap(find.byKey(const Key('chat_settings_done')));
    await tester.pumpAndSettle();

    // Peer thread (no parent member) → the optional toggle is offered.
    await tester.pumpWidget(
      _app(
        child: ConversationScreen(
          chatWith: 'peer_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ConversationKeys.settingsTag));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('chat_receipts_switch')));
    expect(find.byKey(const Key('chat_receipts_switch')), findsOneWidget);
    expect(find.byKey(const Key('chat_receipts_mandatory')), findsNothing);
  });

  test('SCR-FAT-022 stage1 repo defaults empty (Rule 23)', () async {
    final detail = await InMemoryConversationRepository().load('child_a');
    expect(detail, isNull);
  });

  test('SCR-FAT-022 mock has no planted names (Rule 23)', () {
    const forbidden = ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله'];
    for (final t in ConversationMock.all) {
      for (final name in forbidden) {
        expect(t.title.contains(name), isFalse, reason: t.title);
        expect(t.subtitle.contains(name), isFalse, reason: t.subtitle);
        for (final m in t.messages) {
          expect(m.body.contains(name), isFalse, reason: m.body);
          if (m.senderLabel != null) {
            expect(m.senderLabel!.contains(name), isFalse);
          }
        }
        for (final chip in t.toneChips) {
          expect(chip.contains(name), isFalse, reason: chip);
        }
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
