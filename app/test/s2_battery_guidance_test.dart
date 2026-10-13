import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n07_privacy/battery_guidance_screen.dart';

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
    home: child,
  );

  Map<String, Object?> guidance(String stepsKey) => {
    'available': true,
    'vendor': 'xiaomi',
    'action': 'a',
    'package': 'p',
    'activity': 'c',
    'stepsKey': stepsKey,
  };

  testWidgets('vendor steps render for the reported steps key', (tester) async {
    mockNativeChildTelemetryChannel(
      responses: {'batteryGuidance': guidance('oem_xiaomi')},
    );
    await tester.pumpWidget(wrap(const BatteryGuidanceScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(BatteryGuidanceKeys.screen), findsOneWidget);
    expect(find.textContaining('شاومي'), findsOneWidget);
  });

  testWidgets('unknown steps key falls back to stock steps', (tester) async {
    mockNativeChildTelemetryChannel(
      responses: {'batteryGuidance': guidance('oem_future_phone')},
    );
    await tester.pumpWidget(wrap(const BatteryGuidanceScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('أندرويد'), findsOneWidget);
  });

  testWidgets('open success reports the opened note', (tester) async {
    mockNativeChildTelemetryChannel(
      responses: {
        'batteryGuidance': guidance('oem_stock'),
        'openBatterySettings': {'opened': true},
      },
    );
    await tester.pumpWidget(wrap(const BatteryGuidanceScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BatteryGuidanceKeys.openButton));
    await tester.pumpAndSettle();
    expect(find.byKey(BatteryGuidanceKeys.resultNote), findsOneWidget);
    expect(find.textContaining('فُتحت الإعدادات'), findsOneWidget);
  });

  testWidgets('open failure reports the fallback note', (tester) async {
    mockNativeChildTelemetryChannel(
      responses: {
        'batteryGuidance': guidance('oem_stock'),
        'openBatterySettings': {'opened': false},
      },
    );
    await tester.pumpWidget(wrap(const BatteryGuidanceScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BatteryGuidanceKeys.openButton));
    await tester.pumpAndSettle();
    expect(find.byKey(BatteryGuidanceKeys.resultNote), findsOneWidget);
    expect(find.textContaining('صفحة الشركة'), findsOneWidget);
  });
}
