import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/call_history_mock.dart';
import 'package:family_os/features/n02_day/call_history_repository.dart';
import 'package:family_os/features/n02_day/call_history_screen.dart';

void main() {
  testWidgets('SCR-FAT-024 empty → AppEmptyState + honesty + SOS ungated',
      (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.empty), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.body), findsNothing);
    expect(find.byKey(CallHistoryKeys.sosCta), findsOneWidget);

    await tester.tap(find.byKey(CallHistoryKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  testWidgets('SCR-FAT-024 one call', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.one,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.body), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_child_a')), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.redial('log_child_a')), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_child_b_missed')), findsNothing);
    expect(find.textContaining('ابن ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-024 many + directions + mother OK', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.many,
          ),
          roleOverride: AppRole.mother,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.body), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.honestyBanner), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_child_a')), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_child_b_missed')), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_mother')), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.row('log_child_c_video')), findsOneWidget);
    expect(find.textContaining('صادرة'), findsWidgets);
    expect(find.textContaining('فائتة'), findsOneWidget);
    expect(find.textContaining('واردة'), findsOneWidget);
    expect(find.textContaining('صادرة فيديو'), findsOneWidget);
  });

  testWidgets('SCR-FAT-024 redial → FAT-023 callId', (tester) async {
    CallLogEntry? redialed;
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onRedial: (e) => redialed = e,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CallHistoryKeys.redial('log_child_a')));
    await tester.pumpAndSettle();

    expect(redialed, isNotNull);
    expect(redialed!.callId, 'call_child_a');
    expect(redialed!.id, 'log_child_a');
  });

  testWidgets('SCR-FAT-024 row tap → redial seam', (tester) async {
    CallLogEntry? opened;
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.one,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onRedial: (e) => opened = e,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CallHistoryKeys.row('log_child_a')));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.callId, 'call_child_a');
  });

  testWidgets('SCR-FAT-024 blank callId → dial seam', (tester) async {
    CallLogEntry? dialed;
    final blank = CallLogEntry(
      id: 'log_blank',
      callId: '  ',
      peerLabel: 'ابن ١',
      emoji: '🦁',
      avatarColor: 0xFF7C5CE6,
      direction: CallLogDirection.outgoing,
      whenLabel: 'الآن',
    );
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistorySnapshot(entries: [blank]),
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onDial: (e) => dialed = e,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CallHistoryKeys.redial('log_blank')));
    await tester.pumpAndSettle();

    expect(dialed, isNotNull);
    expect(dialed!.id, 'log_blank');
  });

  testWidgets('SCR-FAT-024 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.many,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.childLean), findsOneWidget);
    expect(find.byKey(CallHistoryKeys.body), findsNothing);
    expect(find.byKey(CallHistoryKeys.sosCta), findsOneWidget);
  });

  testWidgets('SCR-FAT-024 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryCallHistoryRepository(failLoad: true);
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    repo.seed(CallHistoryMock.many);
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(CallHistoryKeys.body), findsOneWidget);
  });

  testWidgets('SCR-FAT-024 Rule 23 — empty default no planted names',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final name in const ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  testWidgets('SCR-FAT-024 Rule 23 — seeded generic labels only',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: CallHistoryScreen(
          repository: InMemoryCallHistoryRepository(
            initial: CallHistoryMock.many,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ابن ١'), findsWidgets);
    expect(find.textContaining('شريكة ١'), findsWidgets);
    for (final name in const ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  test('SCR-FAT-024 stage1 repo defaults empty (Rule 23)', () async {
    final snap = await InMemoryCallHistoryRepository().load();
    expect(snap.isEmpty, isTrue);
  });

  test('SCR-FAT-024 mock has no planted names (Rule 23)', () {
    const forbidden = ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله'];
    for (final e in CallHistoryMock.many.entries) {
      for (final name in forbidden) {
        expect(e.peerLabel.contains(name), isFalse, reason: e.peerLabel);
        expect(e.callId.contains(name), isFalse, reason: e.callId);
        expect(e.id.contains(name), isFalse, reason: e.id);
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
