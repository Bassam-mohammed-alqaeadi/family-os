import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/policy/sos_role_actions.dart';

void main() {
  group('SosRoleActions RBAC', () {
    test('Primary (father) has full control', () {
      final a = SosActor.primary();
      expect(SosRoleActions.canAcknowledge(a), isTrue);
      expect(SosRoleActions.canResolve(a), isTrue);
      expect(SosRoleActions.canEscalate(a), isTrue);
      expect(SosRoleActions.canConfigure(a), isTrue);
      expect(SosRoleActions.canBreakGlass(a), isTrue);
    });

    test('Mother Full can configure + break-glass + respond', () {
      final a = SosActor.mother(MotherLevel.full);
      expect(SosRoleActions.canAcknowledge(a), isTrue);
      expect(SosRoleActions.canResolve(a), isTrue);
      expect(SosRoleActions.canEscalate(a), isTrue);
      expect(SosRoleActions.canConfigure(a), isTrue);
      expect(SosRoleActions.canBreakGlass(a), isTrue);
    });

    test('Mother Partner can ack/resolve/escalate; cannot configure', () {
      final a = SosActor.mother(MotherLevel.partner);
      expect(SosRoleActions.canAcknowledge(a), isTrue);
      expect(SosRoleActions.canResolve(a), isTrue);
      expect(SosRoleActions.canEscalate(a), isTrue);
      expect(SosRoleActions.canConfigure(a), isFalse);
      expect(SosRoleActions.canBreakGlass(a), isFalse);
    });

    test('Mother Observer cannot ack/resolve/escalate/configure', () {
      final a = SosActor.mother(MotherLevel.observer);
      expect(SosRoleActions.canAcknowledge(a), isFalse);
      expect(SosRoleActions.canResolve(a), isFalse);
      expect(SosRoleActions.canEscalate(a), isFalse);
      expect(SosRoleActions.canConfigure(a), isFalse);
      expect(SosRoleActions.canBreakGlass(a), isFalse);
    });

    test('Child can cancel own SOS only', () {
      final a = SosActor.child();
      expect(SosRoleActions.canCancelOwnSos(a), isTrue);
      expect(SosRoleActions.canResolve(a), isFalse);
      expect(SosRoleActions.canConfigure(a), isFalse);
      expect(SosRoleActions.canBreakGlass(a), isFalse);
    });
  });
}
