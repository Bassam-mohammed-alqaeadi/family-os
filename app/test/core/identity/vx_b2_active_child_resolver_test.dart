import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/active_child_resolver.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

/// VX-B2 · D6 — one resolver over the identity authority; no demo literals.
void main() {
  late IdentityRuntime runtime;

  setUp(() {
    runtime = createStage1IdentityRuntime(
      familyContextStore: MemoryFamilyContextStore(),
    );
  });

  test('childIdFromParam: blank → null, value trimmed', () {
    expect(childIdFromParam(null), isNull);
    expect(childIdFromParam('  '), isNull);
    expect(childIdFromParam(' child_b '), ChildId('child_b'));
  });

  test('explicit child wins; otherwise the active child', () {
    expect(
      resolveActiveChildId(explicit: ChildId('child_b'), runtime: runtime),
      ChildId('child_b'),
    );
    expect(resolveActiveChildId(runtime: runtime), runtime.activeChildId);
  });

  test('selectActiveChild only accepts children of the active family', () {
    expect(selectActiveChild(ChildId('child_b'), runtime: runtime), isTrue);
    expect(resolveActiveChildId(runtime: runtime), ChildId('child_b'));

    // child_c belongs to fam_stage2 — rejected, selection unchanged.
    expect(selectActiveChild(ChildId('child_c'), runtime: runtime), isFalse);
    expect(resolveActiveChildId(runtime: runtime), ChildId('child_b'));
  });

  test('family switch moves family + child together', () {
    runtime.switchActiveFamily(FamilyId('fam_stage2'));
    expect(resolveActiveFamilyId(runtime: runtime), FamilyId('fam_stage2'));
    expect(resolveActiveChildId(runtime: runtime), ChildId('child_c'));
  });

  test('device ↔ child lookups follow identity devices', () {
    expect(
      deviceIdForChild(ChildId('child_b'), runtime: runtime),
      DeviceId('dev_b'),
    );
    expect(childIdForDevice('dev_b', runtime: runtime), ChildId('child_b'));
    expect(deviceIdForChild(ChildId('nobody'), runtime: runtime), isNull);
    expect(childIdForDevice(null, runtime: runtime), isNull);
  });

  test('features/ never fall back to scattered demo child literals', () {
    final banned = RegExp(
      r"ChildId\('(demo-child|child_demo|child_1)'\)|kStage1CanonicalChildId",
    );
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.contains('/mock/') || path.endsWith('_mock.dart')) continue;
      if (banned.hasMatch(entity.readAsStringSync())) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });
}
