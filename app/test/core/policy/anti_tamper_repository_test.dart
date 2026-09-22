import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/policy/anti_tamper_permission.dart';
import 'package:family_os/core/policy/anti_tamper_policy.dart';
import 'package:family_os/core/policy/anti_tamper_repository.dart';
import 'package:family_os/core/policy/web_unlock_service.dart' show AuditAppend;

void main() {
  final child = ChildId('at-unit-child');

  group('canConfigureAntiTamper', () {
    test('father only', () {
      expect(canConfigureAntiTamper(AppRole.father), isTrue);
      expect(canConfigureAntiTamper(AppRole.mother), isFalse);
      expect(canConfigureAntiTamper(AppRole.child), isFalse);
    });
  });

  group('AntiTamperRepository write gate', () {
    test('mother write → denied 403 + audit; store unchanged', () async {
      final audit = AuditAppend();
      final repo = InMemoryAntiTamperRepository(audit: audit);
      await repo.write(
        child,
        const AntiTamperPolicy(noDelete: true),
        actor: AppRole.father,
      );

      final result = await repo.write(
        child,
        const AntiTamperPolicy(noDelete: false, noVpn: true),
        actor: AppRole.mother,
      );

      expect(result, isA<AntiTamperWriteDenied>());
      final denied = (result as AntiTamperWriteDenied).denied;
      expect(denied.statusCode, 403);
      expect(denied.actor, AppRole.mother);
      expect(audit.entries, hasLength(1));
      expect(audit.entries.single, contains('403'));
      expect(audit.entries.single, contains('mother'));

      final loaded = await repo.load(child);
      expect(loaded.noDelete, isTrue);
      expect(loaded.noVpn, isFalse);
    });

    test('child write → denied + audit', () async {
      final audit = AuditAppend();
      final repo = PrefsAntiTamperRepository(
        MemoryAntiTamperPrefsStore(),
        audit: audit,
      );

      final result = await repo.save(
        child,
        const AntiTamperPolicy(simAlert: true),
        actor: AppRole.child,
      );

      expect(result, isA<AntiTamperWriteDenied>());
      expect(audit.entries.single, contains('child'));
      final loaded = await repo.load(child);
      expect(loaded.simAlert, isFalse);
    });

    test('father write persists across prefs reopen', () async {
      final shared = <String, String>{};
      final repo = PrefsAntiTamperRepository(
        MemoryAntiTamperPrefsStore(shared),
      );

      final result = await repo.write(
        child,
        const AntiTamperPolicy(
          noDelete: true,
          noClockChange: true,
          bypassAlert: true,
        ),
        actor: AppRole.father,
      );
      expect(result, isA<AntiTamperWriteOk>());

      final repo2 = PrefsAntiTamperRepository(
        MemoryAntiTamperPrefsStore(shared),
      );
      final loaded = await repo2.load(child);
      expect(loaded.noDelete, isTrue);
      expect(loaded.noClockChange, isTrue);
      expect(loaded.bypassAlert, isTrue);
      expect(loaded.noVpn, isFalse);
    });
  });
}
