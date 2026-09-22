import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/policy_sync_bus.dart';
import 'package:family_os/core/policy/screen_time_policy.dart';
import 'package:family_os/core/policy/smart_mode_activation.dart';
import 'package:family_os/core/policy/smart_mode_activation_bus.dart';
import 'package:family_os/core/policy/smart_modes.dart';
import 'package:family_os/features/n02_day/child_day_board_screen.dart';
import 'package:family_os/features/n02_day/day_board_motion.dart';
import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_board_screen.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// UI-017 — large text + reduce-motion on day boards (FAT-010 / CHD-004).
void main() {
  final child = ChildId('ui017-child');

  for (final scale in const [1.3, 2.0]) {
    testWidgets(
      'AC1 FAT-010 primary cards survive textScale $scale without overflow',
      (tester) async {
        final errors = <Object>[];
        final old = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details.exception);
          old?.call(details);
        };
        addTearDown(() => FlutterError.onError = old);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: DayBoardScreen(
              projection: DayBoardProjection(
                children: DayChildMock.manyFixture,
                pendingRequests: const [
                  DayBoardPendingRequest(
                    id: 'p1',
                    title:
                        'طلب وقت إضافي طويل جدًا للاختبار مع نص عربي ممتد',
                    subtitle:
                        'وصف مساند طويل جدًا يجب ألا يقص البطاقة عند تكبير الخط',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(
          errors.where(_isOverflow),
          isEmpty,
          reason: 'RenderFlex/clip overflow at scale $scale: $errors',
        );
        expect(find.byKey(DayBoardKeys.activeChild), findsOneWidget);
        expect(find.byKey(DayBoardKeys.greeting), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(DayBoardKeys.priority),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          errors.where(_isOverflow),
          isEmpty,
          reason: 'overflow after scroll at scale $scale: $errors',
        );
        expect(find.byKey(DayBoardKeys.priority), findsOneWidget);
      },
    );

    testWidgets(
      'AC1 CHD-004 status card survives textScale $scale without overflow',
      (tester) async {
        final errors = <Object>[];
        final old = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details.exception);
          old?.call(details);
        };
        addTearDown(() => FlutterError.onError = old);

        final syncBus = PolicySyncBus();
        addTearDown(syncBus.dispose);
        final activationBus = SmartModeActivationBus();
        final policy = ScreenTimePolicy(
          dailyCapMinutes: 90,
          usedMinutesToday: 10,
        );
        syncBus.hydrate(child, policy: policy);
        activationBus.publish(
          SmartModeActivation(
            childId: child.value,
            active: true,
            modeId: BuiltInModeId.school,
            updatedAt: DateTime.utc(2026, 9, 21),
            expiresAt: DateTime.utc(2026, 9, 21, 15, 30),
          ),
        );

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: ChildDayBoardScreen(
              childId: child,
              syncBus: syncBus,
              activationBus: activationBus,
              initialPolicy: policy,
              showModeNotices: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(
          errors.where(_isOverflow),
          isEmpty,
          reason: 'RenderFlex/clip overflow at scale $scale: $errors',
        );
        expect(find.byKey(ChildDayBoardKeys.statusCard), findsOneWidget);
        expect(find.byKey(ChildDayBoardKeys.activeModeLabel), findsOneWidget);
      },
    );
  }

  testWidgets('AC2 reduce-motion zeros FAT-010 pulse AnimationController', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        disableAnimations: true,
        child: DayBoardScreen(
          projection: DayBoardProjection(children: DayChildMock.manyFixture),
        ),
      ),
    );
    await tester.pump();

    final state = tester.state<DayBoardMotionPulseState>(
      find.byKey(DayBoardKeys.pulseMotion),
    );
    expect(state.controller.duration, Duration.zero);
    expect(state.controller.isAnimating, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(state.controller.isAnimating, isFalse);
    expect(state.controller.value, 1.0);
  });

  testWidgets('AC2 reduce-motion zeros CHD-004 status AnimationController', (
    tester,
  ) async {
    final activationBus = SmartModeActivationBus();
    activationBus.publish(
      SmartModeActivation(
        childId: child.value,
        active: true,
        modeId: BuiltInModeId.school,
        updatedAt: DateTime.utc(2026, 9, 21),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        disableAnimations: true,
        child: ChildDayBoardScreen(
          childId: child,
          activationBus: activationBus,
          showModeNotices: false,
        ),
      ),
    );
    await tester.pump();

    final state = tester.state<DayBoardMotionPulseState>(
      find.byKey(ChildDayBoardKeys.statusMotion),
    );
    expect(state.controller.duration, Duration.zero);
    expect(state.controller.isAnimating, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(state.controller.isAnimating, isFalse);
  });

  testWidgets('AC2 motion runs when animations allowed on FAT-010', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        disableAnimations: false,
        child: DayBoardScreen(
          projection: DayBoardProjection(children: DayChildMock.manyFixture),
        ),
      ),
    );
    await tester.pump();

    final state = tester.state<DayBoardMotionPulseState>(
      find.byKey(DayBoardKeys.pulseMotion),
    );
    expect(state.controller.duration, isNot(Duration.zero));
    expect(state.controller.isAnimating, isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    expect(state.controller.value, greaterThan(0));
    await tester.pumpAndSettle();
    expect(state.controller.status, AnimationStatus.completed);
  });

  testWidgets('dayBoardMotionDuration helper honors disableAnimations', (
    tester,
  ) async {
    late Duration reduced;
    late Duration normal;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduced = dayBoardMotionDuration(
              context,
              const Duration(milliseconds: 500),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: Builder(
          builder: (context) {
            normal = dayBoardMotionDuration(
              context,
              const Duration(milliseconds: 500),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(reduced, Duration.zero);
    expect(normal, const Duration(milliseconds: 500));
  });
}

bool _isOverflow(Object e) {
  final s = e.toString();
  return s.contains('overflowed') ||
      s.contains('RenderFlex') ||
      s.contains('A RenderFlex overflowed');
}

Widget _wrap({
  required Widget child,
  double textScale = 1.0,
  bool disableAnimations = false,
}) {
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
    builder: (context, nested) {
      final mq = MediaQuery.of(context);
      return MediaQuery(
        data: mq.copyWith(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: nested!,
      );
    },
    home: child,
  );
}


