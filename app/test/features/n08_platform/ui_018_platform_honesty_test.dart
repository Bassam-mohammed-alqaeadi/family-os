import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/app/role_guard.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/desired_monitoring_sync_bus.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_id.dart';
import 'package:family_os/features/n08_platform/effective_monitoring_transparency.dart';
import 'package:family_os/features/n08_platform/platform_monitoring_screen.dart';
import 'package:family_os/features/n08_platform/smart_supervision_screen.dart';

void main() {
  group('UI-018 AC1 unavailable styling', () {
    testWidgets(
      'FAT-067 iOS: unavailable Switch off + muted tokens ≠ mint ON',
      (tester) async {
        final repo = InMemoryDesiredMonitoringPrefsRepository({
          DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
            notificationListen: true,
            webFilter: true,
          ),
        });

        await _pumpSmart(
          tester,
          platform: PlatformId.ios,
          repository: repo,
          locale: const Locale('en'),
        );

        final sw = tester.widget<Switch>(
          find.byKey(
            SmartSupervisionKeys.featureSwitch(
              MonitoringFeature.notificationListen,
            ),
          ),
        );
        expect(sw.value, isFalse);
        expect(sw.onChanged, isNull);

        final colors = FamilyColors.defaults;
        expect(sw.thumbColor?.resolve(const {}), colors.ink2);
        expect(sw.trackColor?.resolve(const {}), colors.border);
        expect(sw.thumbColor?.resolve(const {}), isNot(colors.mint));
        expect(
          find.byKey(
            SmartSupervisionKeys.featureBadge(
              MonitoringFeature.notificationListen,
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Unavailable'), findsWidgets);
      },
    );

    testWidgets(
      'FAT-068 iOS notificationListen: unavailable ≠ selected-on mint',
      (tester) async {
        final repo = InMemoryDesiredMonitoringPrefsRepository({
          DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
            notificationListen: true,
          ),
        });

        await _pumpPlatform(tester, repository: repo);

        final sw = tester.widget<Switch>(
          find.byKey(
            PlatformMonitoringKeys.featureSwitch(
              PlatformId.ios,
              MonitoringFeature.notificationListen,
            ),
          ),
        );
        expect(sw.value, isFalse);
        expect(sw.onChanged, isNull);

        final colors = FamilyColors.defaults;
        expect(sw.thumbColor?.resolve(const {}), isNot(colors.mint));
        expect(sw.trackColor?.resolve(const {}), isNot(colors.mint100));
      },
    );
  });

  group('UI-018 AC2 Semantics states reason', () {
    testWidgets('FAT-068 EN Semantics include Unavailable reason',
        (tester) async {
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          notificationListen: true,
        ),
      });

      await _pumpPlatform(
        tester,
        repository: repo,
        locale: const Locale('en'),
      );

      expect(
        find.bySemanticsLabel(RegExp('Unavailable')),
        findsWidgets,
      );
    });

    testWidgets('FAT-067 AR Semantics include غير متاح reason', (tester) async {
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          notificationListen: true,
        ),
      });

      await _pumpSmart(
        tester,
        platform: PlatformId.ios,
        repository: repo,
        locale: const Locale('ar'),
      );

      expect(
        find.bySemanticsLabel(RegExp('غير متاح')),
        findsWidgets,
      );
    });
  });

  group('UI-018 reportsOnly intermediate + offline', () {
    testWidgets('reportsOnly never looks fully ON + limited badge',
        (tester) async {
      final repo = InMemoryDesiredMonitoringPrefsRepository({
        DesiredMonitoringPrefs.defaultChildId: const DesiredMonitoringPrefs(
          webFilter: true,
        ),
      });

      await _pumpSmart(
        tester,
        platform: PlatformId.ios,
        repository: repo,
        locale: const Locale('en'),
      );

      final sw = tester.widget<Switch>(
        find.byKey(
          SmartSupervisionKeys.featureSwitch(MonitoringFeature.webFilter),
        ),
      );
      expect(sw.value, isFalse);
      expect(sw.onChanged, isNull);
      expect(find.textContaining('Reports only'), findsWidgets);
    });

    testWidgets('offline shows last-capability honesty banner', (tester) async {
      await _pumpPlatform(
        tester,
        repository: InMemoryDesiredMonitoringPrefsRepository(),
        offline: true,
        locale: const Locale('en'),
      );

      expect(
        find.byKey(PlatformMonitoringKeys.offlineBanner),
        findsOneWidget,
      );
      expect(find.textContaining('Offline'), findsWidgets);
    });
  });

  group('UI-018 child transparency matches effective (P-7)', () {
    testWidgets(
      'desired ON + iOS unavailable → child list omits feature (not fake-on)',
      (tester) async {
        final bus = DesiredMonitoringSyncBus();
        bus.publish(
          const DesiredMonitoringPrefs(
            notificationListen: true,
            appLimits: true,
            webFilter: true,
          ),
          platform: PlatformId.ios,
        );

        await tester.pumpWidget(
          _app(
            locale: const Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EffectiveMonitoringTransparency(
                  syncBus: bus,
                  platform: PlatformId.ios,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // appLimits iOS = full → visible as Active
        expect(
          find.byKey(
            EffectiveMonitoringTransparencyKeys.featureLine(
              MonitoringFeature.appLimits,
            ),
          ),
          findsOneWidget,
        );
        // notificationListen iOS = unavailable → never listed as on
        expect(
          find.byKey(
            EffectiveMonitoringTransparencyKeys.featureLine(
              MonitoringFeature.notificationListen,
            ),
          ),
          findsNothing,
        );
        // webFilter iOS = reportsOnly → limited badge, not full Active-only
        expect(
          find.byKey(
            EffectiveMonitoringTransparencyKeys.featureLine(
              MonitoringFeature.webFilter,
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Reports only'), findsWidgets);
      },
    );

    testWidgets('P12 father toggle updates child effective same session',
        (tester) async {
      final bus = DesiredMonitoringSyncBus();
      final repo = InMemoryDesiredMonitoringPrefsRepository();

      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SmartSupervisionScreen(
                    platform: PlatformId.android,
                    repository: repo,
                    syncBus: bus,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: EffectiveMonitoringTransparency(
                        syncBus: bus,
                        platform: PlatformId.android,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(EffectiveMonitoringTransparencyKeys.empty),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          SmartSupervisionKeys.featureSwitch(MonitoringFeature.webFilter),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          EffectiveMonitoringTransparencyKeys.featureLine(
            MonitoringFeature.webFilter,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Active'), findsWidgets);
    });
  });

  group('UI-018 Mother FULL host access', () {
    test('FAT-067/068 not father-only — mother may open', () {
      expect(
        roleGuardRedirectForPath(
          screenPath('SCR-FAT-067'),
          AppRole.mother,
        ),
        isNull,
      );
      expect(
        roleGuardRedirectForPath(
          screenPath('SCR-FAT-068'),
          AppRole.mother,
        ),
        isNull,
      );
      expect(
        roleGuardRedirectForPath(
          screenPath('SCR-FAT-067'),
          AppRole.child,
        ),
        isNull,
      );
    });
  });
}

Future<void> _pumpSmart(
  WidgetTester tester, {
  required PlatformId platform,
  required DesiredMonitoringPrefsRepository repository,
  Locale locale = const Locale('ar'),
  DesiredMonitoringSyncBus? syncBus,
  bool offline = false,
}) async {
  await tester.pumpWidget(
    _app(
      locale: locale,
      home: SmartSupervisionScreen(
        platform: platform,
        repository: repository,
        syncBus: syncBus,
        offline: offline,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPlatform(
  WidgetTester tester, {
  required DesiredMonitoringPrefsRepository repository,
  Locale locale = const Locale('ar'),
  bool offline = false,
}) async {
  await tester.pumpWidget(
    _app(
      locale: locale,
      home: PlatformMonitoringScreen(
        repository: repository,
        offline: offline,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app({required Locale locale, required Widget home}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildFamilyTheme(),
    home: home,
  );
}
