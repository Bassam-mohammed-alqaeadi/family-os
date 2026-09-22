import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/device_lock_service.dart';
import 'package:family_os/core/policy/sos_fire.dart';
import 'package:family_os/core/policy/time_request.dart';
import 'package:family_os/core/policy/time_request_repository.dart';
import 'package:family_os/core/policy/time_request_service.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';
import 'package:family_os/features/n02_day/request_inbox_screen.dart';
import 'package:family_os/features/n03_screen_time/time_expiry_screen.dart';
import 'package:family_os/features/n05_lock/instant_lock_screen.dart';

/// UI-015 — SOS / lock / approve / grant hit targets ≥48×48 dp (Rule 16).
void main() {
  const min = 48.0;

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: buildFamilyTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  Size sizeOf(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    return tester.getSize(finder);
  }

  void expectMinTouch(Size size, {required String label}) {
    expect(
      size.width,
      greaterThanOrEqualTo(min),
      reason: '$label width ${size.width} < $min',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(min),
      reason: '$label height ${size.height} < $min',
    );
  }

  testWidgets('AC1: SOS PrimaryBtn + icon-only ≥48×48', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimeExpiryScreen(
          childId: ChildId('ui015-sos'),
          sosFire: MockSosFireService(),
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectMinTouch(
      sizeOf(tester, find.byKey(TimeExpiryKeys.sosCta)),
      label: 'SOS PrimaryBtn',
    );
    expectMinTouch(
      sizeOf(tester, find.byKey(TimeExpiryKeys.sosIconCta)),
      label: 'SOS IconButton',
    );
  });

  testWidgets('AC2: grant chips + approve ≥48×48', (tester) async {
    final child = ChildId('ui015-grant');
    final pending = TimeRequest(
      id: 'tr-ui015',
      childId: child,
      requestedMinutes: 15,
    );
    final inbox = TimeRequestService(
      repository: InMemoryTimeRequestRepository([pending]),
      decisionBus: TimeRequestDecisionBus(),
    );
    addTearDown(inbox.dispose);

    await tester.pumpWidget(
      wrap(
        RequestInboxScreen(
          service: inbox,
          role: AppRole.father,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectMinTouch(
      sizeOf(tester, find.byKey(RequestInboxKeys.approve(pending.id))),
      label: 'approve',
    );
    expectMinTouch(
      sizeOf(tester, find.byKey(RequestInboxKeys.reject(pending.id))),
      label: 'reject',
    );
    for (final m in const [15, 30, 45, 60]) {
      expectMinTouch(
        sizeOf(tester, find.byKey(RequestInboxKeys.grantChip(m))),
        label: 'grant $m',
      );
    }
    expectMinTouch(
      sizeOf(tester, find.byKey(RequestInboxKeys.backButton)),
      label: 'inbox back',
    );
  });

  testWidgets('instant lock / unlock ≥48×48', (tester) async {
    await tester.pumpWidget(
      wrap(
        InstantLockScreen(
          childId: ChildId('ui015-lock'),
          repository: InMemoryAntiTamperRepository(),
          lockService: DeviceLockService.inMemory(),
          roleOverride: AppRole.father,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectMinTouch(
      sizeOf(tester, find.byKey(InstantLockKeys.lockButton)),
      label: 'instant lock',
    );
    expectMinTouch(
      sizeOf(tester, find.byKey(InstantLockKeys.unlockButton)),
      label: 'instant unlock',
    );
  });

  testWidgets('day board quick lock ≥48×48', (tester) async {
    await tester.pumpWidget(
      wrap(
        DayBoardScreen(
          projection: DayBoardProjection(
            children: DayChildMock.manyFixture,
          ),
          onLock: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectMinTouch(
      sizeOf(tester, find.byKey(const Key('day_board_quick_lock'))),
      label: 'day board lock',
    );
  });
}
