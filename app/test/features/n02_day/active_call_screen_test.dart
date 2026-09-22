import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/app_empty_state.dart';
import 'package:family_os/core/design/components/app_error_state.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/active_call_mock.dart';
import 'package:family_os/features/n02_day/active_call_repository.dart';
import 'package:family_os/features/n02_day/active_call_screen.dart';

void main() {
  testWidgets('SCR-FAT-023 loads by callId=call_child_a', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: InMemoryActiveCallRepository(
            initial: ActiveCallMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onEnd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.body), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.avatar), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.peerLabel), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.statusLine), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.mute), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.speaker), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.video), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.end), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.honesty), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.playTogether), findsOneWidget);
    expect(find.textContaining('ابن ١'), findsWidgets);
  });

  testWidgets('SCR-FAT-023 mother OK + parametric peers', (tester) async {
    final repo = InMemoryActiveCallRepository(initial: ActiveCallMock.all);

    Future<void> open(String id) async {
      await tester.pumpWidget(
        _app(
          child: ActiveCallScreen(
            callId: id,
            repository: repo,
            roleOverride: AppRole.mother,
            onSos: () {},
            onEnd: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open('call_mother');
    expect(find.byKey(ActiveCallKeys.body), findsOneWidget);
    expect(find.textContaining('شريكة ١'), findsWidgets);

    await open('call_child_b');
    expect(find.textContaining('ابن ٢'), findsWidgets);

    await open('call_child_c_video');
    expect(find.textContaining('ابن ٣'), findsWidgets);
  });

  testWidgets('SCR-FAT-023 mute / speaker / end mock seams', (tester) async {
    var muted = false;
    var speaker = false;
    var ended = false;
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: InMemoryActiveCallRepository(
            initial: ActiveCallMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onMute: (v) => muted = v,
          onSpeaker: (v) => speaker = v,
          onEnd: () => ended = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ActiveCallKeys.mute));
    await tester.pumpAndSettle();
    expect(muted, isTrue);

    await tester.tap(find.byKey(ActiveCallKeys.speaker));
    await tester.pumpAndSettle();
    expect(speaker, isTrue);

    await tester.tap(find.byKey(ActiveCallKeys.end));
    await tester.pumpAndSettle();
    expect(ended, isTrue);
  });

  testWidgets('SCR-FAT-023 missing callId → empty', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          repository: InMemoryActiveCallRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.missingId), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('SCR-FAT-023 unknown callId → not found', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'missing_call',
          repository: InMemoryActiveCallRepository(
            initial: ActiveCallMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.notFound), findsOneWidget);
  });

  testWidgets('SCR-FAT-023 Rule 23 — empty repo no planted names',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: InMemoryActiveCallRepository(),
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.notFound), findsOneWidget);
    for (final name in const ['خالد', 'نورة', 'سعد', 'نوال']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  testWidgets('SCR-FAT-023 Rule 23 — seeded uses generic labels only',
      (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: InMemoryActiveCallRepository(
            initial: ActiveCallMock.all,
          ),
          roleOverride: AppRole.father,
          onSos: () {},
          onEnd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ابن ١'), findsWidgets);
    for (final name in const ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله']) {
      expect(find.textContaining(name), findsNothing);
    }
  });

  testWidgets('SCR-FAT-023 child lean', (tester) async {
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: InMemoryActiveCallRepository(
            initial: ActiveCallMock.all,
          ),
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.childLean), findsOneWidget);
    expect(find.byKey(ActiveCallKeys.body), findsNothing);
  });

  testWidgets('SCR-FAT-023 error → AppErrorState + retry', (tester) async {
    final repo = InMemoryActiveCallRepository(
      initial: ActiveCallMock.all,
      failLoad: true,
    );
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          callId: 'call_child_a',
          repository: repo,
          roleOverride: AppRole.father,
          onSos: () {},
          onEnd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.error), findsOneWidget);
    expect(find.byType(AppErrorState), findsOneWidget);

    repo.failLoad = false;
    await tester.tap(find.byKey(const Key('app_error_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.body), findsOneWidget);
  });

  testWidgets('SCR-FAT-023 P-4 SOS ungated on empty', (tester) async {
    var sos = false;
    await tester.pumpWidget(
      _app(
        child: ActiveCallScreen(
          repository: InMemoryActiveCallRepository(),
          roleOverride: AppRole.father,
          onSos: () => sos = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ActiveCallKeys.missingId), findsOneWidget);
    await tester.tap(find.byKey(ActiveCallKeys.sosCta));
    await tester.pumpAndSettle();
    expect(sos, isTrue);
  });

  test('SCR-FAT-023 stage1 repo defaults empty (Rule 23)', () async {
    final detail = await InMemoryActiveCallRepository().load('call_child_a');
    expect(detail, isNull);
  });

  test('SCR-FAT-023 mock has no planted names (Rule 23)', () {
    const forbidden = ['خالد', 'نورة', 'سعد', 'نوال', 'عبدالله'];
    for (final c in ActiveCallMock.all) {
      for (final name in forbidden) {
        expect(c.peerLabel.contains(name), isFalse, reason: c.peerLabel);
        expect(c.callId.contains(name), isFalse, reason: c.callId);
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
