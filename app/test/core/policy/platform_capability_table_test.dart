import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/capability_level.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs.dart';
import 'package:family_os/core/policy/desired_monitoring_prefs_repository.dart';
import 'package:family_os/core/policy/monitoring_feature.dart';
import 'package:family_os/core/policy/platform_capability_table.dart';
import 'package:family_os/core/policy/platform_id.dart';

void main() {
  group('PlatformCapabilityTable fixture', () {
    test('iOS notificationListen is unavailable', () {
      expect(
        PlatformCapabilityTable.level(
          PlatformId.ios,
          MonitoringFeature.notificationListen,
        ),
        CapabilityLevel.unavailable,
      );
    });

    test('Android webFilter is full', () {
      expect(
        PlatformCapabilityTable.level(
          PlatformId.android,
          MonitoringFeature.webFilter,
        ),
        CapabilityLevel.full,
      );
    });
  });

  group('effectiveMonitoring', () {
    test('never claims more than capability', () {
      expect(
        effectiveMonitoring(
          desired: true,
          capability: CapabilityLevel.unavailable,
        ),
        CapabilityLevel.unavailable,
      );
      expect(
        effectiveMonitoring(
          desired: true,
          capability: CapabilityLevel.reportsOnly,
        ),
        CapabilityLevel.reportsOnly,
      );
      expect(
        effectiveMonitoring(
          desired: true,
          capability: CapabilityLevel.full,
        ),
        CapabilityLevel.full,
      );
      expect(
        effectiveMonitoring(
          desired: false,
          capability: CapabilityLevel.full,
        ),
        CapabilityLevel.unavailable,
      );
    });

    test('switchLooksOn only when effective is full', () {
      expect(
        switchLooksOn(
          desired: true,
          capability: CapabilityLevel.unavailable,
        ),
        isFalse,
      );
      expect(
        switchLooksOn(
          desired: true,
          capability: CapabilityLevel.reportsOnly,
        ),
        isFalse,
      );
      expect(
        switchLooksOn(
          desired: true,
          capability: CapabilityLevel.full,
        ),
        isTrue,
      );
      expect(
        switchLooksOn(
          desired: false,
          capability: CapabilityLevel.full,
        ),
        isFalse,
      );
    });

    test('switchInteractive only for full', () {
      expect(switchInteractive(CapabilityLevel.full), isTrue);
      expect(switchInteractive(CapabilityLevel.reportsOnly), isFalse);
      expect(switchInteractive(CapabilityLevel.unavailable), isFalse);
    });
  });

  group('DesiredMonitoringPrefsRepository', () {
    test('Prefs store persists Android full toggle', () async {
      final store = MemoryDesiredMonitoringPrefsStore();
      final repo = PrefsDesiredMonitoringPrefsRepository(store);

      await repo.save(
        const DesiredMonitoringPrefs(
          childId: 'c1',
          webFilter: true,
        ),
      );
      final loaded = await PrefsDesiredMonitoringPrefsRepository(store).load('c1');
      expect(loaded.webFilter, isTrue);
      expect(loaded.appLimits, isFalse);
    });

    test('InMemory round-trip', () async {
      final repo = InMemoryDesiredMonitoringPrefsRepository();
      await repo.save(
        const DesiredMonitoringPrefs(
          childId: 'c1',
          appLimits: true,
          locationAlways: true,
        ),
      );
      final loaded = await repo.load('c1');
      expect(loaded.appLimits, isTrue);
      expect(loaded.locationAlways, isTrue);
      expect(loaded.notificationListen, isFalse);
    });
  });
}
