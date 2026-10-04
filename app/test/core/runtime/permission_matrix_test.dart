import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/design/components/role_gate.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/runtime/permission_matrix.dart';

void main() {
  test('father owns every declared panel capability', () {
    final profile = PanelProfile.fromRole(AppRole.father);

    for (final capability in PanelCapability.values) {
      expect(
        PermissionMatrix.dispositionFor(profile, capability),
        PermissionDisposition.allow,
      );
    }
  });

  test('mother levels distinguish observer, partner and full authority', () {
    final observer = PanelProfile.fromRole(
      AppRole.mother,
      motherLevel: MotherLevel.observer,
    );
    final partner = PanelProfile.fromRole(
      AppRole.mother,
      motherLevel: MotherLevel.partner,
    );
    final full = PanelProfile.fromRole(
      AppRole.mother,
      motherLevel: MotherLevel.full,
    );

    expect(
      PermissionMatrix.dispositionFor(
        observer,
        PanelCapability.approveChildRequests,
      ),
      PermissionDisposition.requestOnly,
    );
    expect(
      PermissionMatrix.dispositionFor(
        partner,
        PanelCapability.approveChildRequests,
      ),
      PermissionDisposition.allow,
    );
    expect(
      PermissionMatrix.dispositionFor(full, PanelCapability.editChildRules),
      PermissionDisposition.allow,
    );
    expect(
      PermissionMatrix.dispositionFor(full, PanelCapability.manageBilling),
      PermissionDisposition.hidden,
    );
  });

  test('child can request changes and access safety, not parent controls', () {
    final child = PanelProfile.fromRole(AppRole.child);

    expect(
      PermissionMatrix.dispositionFor(child, PanelCapability.sendSos),
      PermissionDisposition.allow,
    );
    expect(
      PermissionMatrix.dispositionFor(
        child,
        PanelCapability.requestPolicyChange,
      ),
      PermissionDisposition.requestOnly,
    );
    expect(
      PermissionMatrix.dispositionFor(child, PanelCapability.editChildRules),
      PermissionDisposition.hidden,
    );
  });

  testWidgets(
    'RoleGate supplies the shared disposition to a localized surface',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RoleGate(
            profile: PanelProfile.fromRole(AppRole.child),
            capability: PanelCapability.requestPolicyChange,
            builder: (_, disposition) => Text(disposition.name),
          ),
        ),
      );

      expect(find.text('requestOnly'), findsOneWidget);
    },
  );
}
