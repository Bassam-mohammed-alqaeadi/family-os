import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_privacy/protection_status_card.dart';

import 'support/native_telemetry_channel.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildFamilyTheme(),
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  Map<String, Object?> verdict(
    String state, {
    List<String> reasons = const [],
    String? reason,
    int queueDepth = 0,
    bool live = true,
    bool? backgroundLocationGranted = true,
  }) => {
    'available': true,
    'state': state,
    'reasons': reasons,
    'reason': reason,
    'queueDepth': queueDepth,
    'live': live,
    'backgroundLocationGranted': backgroundLocationGranted,
    'notificationsGranted': true,
  };

  testWidgets('fully protected renders green state, no battery button', (
    tester,
  ) async {
    mockNativeChildTelemetryChannel(
      responses: {'protectionState': verdict('fully_protected')},
    );
    await tester.pumpWidget(wrap(const ProtectionStatusCard()));
    await tester.pumpAndSettle();
    expect(find.byKey(ProtectionStatusKeys.card), findsOneWidget);
    expect(find.text('الحماية تعمل بالكامل'), findsOneWidget);
    expect(find.byKey(ProtectionStatusKeys.batteryButton), findsNothing);
    expect(find.byKey(ProtectionStatusKeys.queuedLine), findsNothing);
  });

  testWidgets('degraded with battery reason shows queue line and button', (
    tester,
  ) async {
    var tapped = false;
    mockNativeChildTelemetryChannel(
      responses: {
        'protectionState': verdict(
          'degraded',
          reasons: ['battery_restricted', 'offline'],
          queueDepth: 3,
        ),
      },
    );
    await tester.pumpWidget(
      wrap(ProtectionStatusCard(onBatteryGuidance: () => tapped = true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('الحماية تعمل جزئياً'), findsOneWidget);
    expect(
      find.text('3 — نقاط مؤجلة ستُرسل عند عودة الشبكة'),
      findsOneWidget,
    );
    expect(find.byKey(ProtectionStatusKeys.batteryButton), findsOneWidget);
    await tester.tap(find.byKey(ProtectionStatusKeys.batteryButton));
    expect(tapped, isTrue);
  });

  testWidgets('stopped renders the stopped state', (tester) async {
    mockNativeChildTelemetryChannel(
      responses: {
        'protectionState': verdict(
          'stopped',
          reason: 'service_down',
          live: false,
        ),
      },
    );
    await tester.pumpWidget(wrap(const ProtectionStatusCard()));
    await tester.pumpAndSettle();
    expect(find.text('الحماية متوقفة'), findsOneWidget);
  });

  testWidgets('live grant loss distrusts the verdict on screen', (
    tester,
  ) async {
    mockNativeChildTelemetryChannel(
      responses: {
        'protectionState': verdict(
          'fully_protected',
          backgroundLocationGranted: false,
        ),
      },
    );
    await tester.pumpWidget(wrap(const ProtectionStatusCard()));
    await tester.pumpAndSettle();
    expect(find.text('الحماية متوقفة'), findsOneWidget);
    expect(find.text('الحماية تعمل بالكامل'), findsNothing);
  });

  testWidgets('silent platform renders the honest unavailable state', (
    tester,
  ) async {
    mockNativeChildTelemetryChannel();
    await tester.pumpWidget(wrap(const ProtectionStatusCard()));
    await tester.pumpAndSettle();
    expect(find.text('تعذّرت قراءة حالة الحماية'), findsOneWidget);
    expect(find.byKey(ProtectionStatusKeys.batteryButton), findsNothing);
  });
}
