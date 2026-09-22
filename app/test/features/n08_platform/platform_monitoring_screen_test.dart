import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_id.dart';
import 'package:family_os/features/n08_platform/platform_monitoring_screen.dart';

void main() {
  testWidgets(
    'SET-017 unavailable tile: Switch off/disabled + Semantics reason',
    (tester) async {
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          notificationListen: true,
          webFilter: true,
          appLimits: true,
        ),
      });

      await _pump(tester, repository: repo);

      final unavailableKey = PlatformMonitoringKeys.featureSwitch(
        PlatformId.ios,
        MonitoringFeature.notificationListen,
      );
      final swFinder = find.byKey(unavailableKey);
      expect(swFinder, findsOneWidget);

      final sw = tester.widget<Switch>(swFinder);
      expect(sw.value, isFalse, reason: 'unavailable must not look ON');
      expect(sw.onChanged, isNull, reason: 'unavailable switch disabled');

      // Semantics announces disabled reason (honesty badge copy).
      expect(
        find.bySemanticsLabel(RegExp('غير متاح')),
        findsWidgets,
        reason: 'Semantics label must include disabled reason',
      );
    },
  );

  testWidgets(
    'SET-017 unavailable ≠ selected-on mint tokens',
    (tester) async {
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          notificationListen: true,
          // appLimits starts false so Android full toggle can turn ON.
        ),
      });

      await _pump(tester, repository: repo);

      final colors = FamilyColors.defaults;

      final unavailable = tester.widget<Switch>(
        find.byKey(
          PlatformMonitoringKeys.featureSwitch(
            PlatformId.ios,
            MonitoringFeature.notificationListen,
          ),
        ),
      );
      expect(unavailable.value, isFalse);
      expect(unavailable.onChanged, isNull);

      final offThumb = unavailable.thumbColor?.resolve(const {});
      final offTrack = unavailable.trackColor?.resolve(const {});
      expect(offThumb, colors.ink2);
      expect(offTrack, colors.border);
      expect(offThumb, isNot(colors.mint));
      expect(offTrack, isNot(colors.mint100));

      // Android full ON uses mint selected-on tokens.
      final androidAppLimits = PlatformMonitoringKeys.featureSwitch(
        PlatformId.android,
        MonitoringFeature.appLimits,
      );
      await tester.tap(find.byKey(androidAppLimits));
      await tester.pumpAndSettle();

      final fullOn = tester.widget<Switch>(find.byKey(androidAppLimits));
      expect(fullOn.value, isTrue);
      expect(fullOn.onChanged, isNotNull);

      final onThumb = fullOn.thumbColor?.resolve({WidgetState.selected});
      final onTrack = fullOn.trackColor?.resolve({WidgetState.selected});
      expect(onThumb, colors.mint);
      expect(onTrack, colors.mint100);
      expect(onThumb, isNot(offThumb));
      expect(onTrack, isNot(offTrack));
    },
  );

  testWidgets('SET-017 reportsOnly shows limited state', (tester) async {
    final repo = InMemoryDesiredMonitoringPrefsRepository({
      DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
        webFilter: true,
      ),
    });

    await _pump(tester, repository: repo);

    final webKey = PlatformMonitoringKeys.featureSwitch(
      PlatformId.ios,
      MonitoringFeature.webFilter,
    );
    final sw = tester.widget<Switch>(find.byKey(webKey));
    expect(sw.value, isFalse, reason: 'reportsOnly must not look fully ON');
    expect(sw.onChanged, isNull);

    expect(
      find.byKey(
        PlatformMonitoringKeys.featureBadge(
          PlatformId.ios,
          MonitoringFeature.webFilter,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('تقارير فقط'), findsWidgets);
    expect(find.textContaining('ليست إنفاذًا كاملًا'), findsWidgets);
  });
}

Future<void> _pump(
  WidgetTester tester, {
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
      home: PlatformMonitoringScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}
