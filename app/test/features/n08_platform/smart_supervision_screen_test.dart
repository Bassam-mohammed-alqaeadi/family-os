import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_id.dart';
import 'package:family_os/features/n08_platform/smart_supervision_screen.dart';

void main() {
  testWidgets(
    'SET-016 iOS unavailable → Switch off/disabled + honesty badge',
    (tester) async {
      // Seed desired=true so honesty must still refuse to look ON.
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          notificationListen: true,
          webFilter: true,
        ),
      });

      await _pump(
        tester,
        platform: PlatformId.ios,
        repository: repo,
      );

      final notifSwitch = find.byKey(
        SmartSupervisionKeys.featureSwitch(
          MonitoringFeature.notificationListen,
        ),
      );
      expect(notifSwitch, findsOneWidget);

      final sw = tester.widget<Switch>(notifSwitch);
      expect(sw.value, isFalse, reason: 'unavailable must not look ON');
      expect(sw.onChanged, isNull, reason: 'unavailable switch disabled');

      expect(
        find.byKey(
          SmartSupervisionKeys.featureBadge(
            MonitoringFeature.notificationListen,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('غير متاح'), findsWidgets);

      // reportsOnly webFilter also never looks fully ON.
      final webSwitch = tester.widget<Switch>(
        find.byKey(
          SmartSupervisionKeys.featureSwitch(MonitoringFeature.webFilter),
        ),
      );
      expect(webSwitch.value, isFalse);
      expect(webSwitch.onChanged, isNull);
      expect(
        find.byKey(
          SmartSupervisionKeys.featureBadge(MonitoringFeature.webFilter),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('تقارير فقط'), findsWidgets);
    },
  );

  testWidgets('SET-016 Android full → toggle persists', (tester) async {
    final store = MemoryDesiredMonitoringPrefsStore();
    final repo = PrefsDesiredMonitoringPrefsRepository(store);

    await _pump(
      tester,
      platform: PlatformId.android,
      repository: repo,
    );

    final webKey =
        SmartSupervisionKeys.featureSwitch(MonitoringFeature.webFilter);
    expect(find.byKey(webKey), findsOneWidget);

    var sw = tester.widget<Switch>(find.byKey(webKey));
    expect(sw.value, isFalse);
    expect(sw.onChanged, isNotNull);

    await tester.tap(find.byKey(webKey));
    await tester.pumpAndSettle();

    sw = tester.widget<Switch>(find.byKey(webKey));
    expect(sw.value, isTrue);

    // Simulate restart with same store.
    final reloaded = PrefsDesiredMonitoringPrefsRepository(store);
    final prefs = await reloaded.load(DesiredMonitoringPrefs.defaultChildId);
    expect(prefs.webFilter, isTrue);

    await _pump(
      tester,
      platform: PlatformId.android,
      repository: reloaded,
    );
    expect(
      tester.widget<Switch>(find.byKey(webKey)).value,
      isTrue,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required PlatformId platform,
  required DesiredMonitoringPrefsRepository repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFamilyTheme(),
      home: SmartSupervisionScreen(
        platform: platform,
        repository: repository,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
