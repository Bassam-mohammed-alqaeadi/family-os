import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/identity/family_context_store.dart';
import 'package:family_os/core/identity/identity_runtime.dart';
import 'package:family_os/core/identity/sos_sender.dart';
import 'package:family_os/core/sos_final/sos_final_runtime.dart';
import 'package:family_os/core/sos_final/sos_incident.dart';
import '../../support/recording_sos_fire_service.dart';

/// OD-13 — parent + viewed child on one SOS record + durable parent incident.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetStage1IdentityRuntimeForTest();
    rebindStage1IdentityRuntime(familyContextStore: MemoryFamilyContextStore());
    await FsSessionKernel.resetForTest();
    Stage1SosFinalRuntime.resetForTest();
    await FsSessionKernel.ensureOpen();
    await Stage1SosFinalRuntime.ensureOpen();
  });

  tearDown(() async {
    Stage1SosFinalRuntime.resetForTest();
    await FsSessionKernel.resetForTest();
    resetStage1IdentityRuntimeForTest();
  });

  test('SosFireResult stores actor + subject child', () async {
    final fire = RecordingSosFireService();
    final result = await fire.fire(
      childId: 'child_b',
      actorId: 'mem_stage1_owner',
    );
    expect(result.childId, 'child_b');
    expect(result.actorId, 'mem_stage1_owner');
  });

  test('parent fireThrough opens durable incident with both ids', () async {
    final fire = RecordingSosFireService();
    final sender = resolveParentSosSender(viewedChild: ChildId('child_b'));
    await sender.fireThrough(fire);

    expect(fire.fireLog.single.childId, 'child_b');
    expect(fire.fireLog.single.actorId, 'mem_stage1_owner');

    final open = await Stage1SosFinalRuntime.service.loadOpen(
      childId: ChildId('child_b'),
    );
    expect(open, isNotNull);
    expect(open!.childId, ChildId('child_b'));
    expect(open.raisedByActorId, 'mem_stage1_owner');
    expect(open.triggerSource, SosTriggerSource.parentAlert);
  });

  test('parent with no view uses active child as subject', () async {
    stage1IdentityRuntime.setActiveChild(ChildId('demo-child'));
    final fire = RecordingSosFireService();
    final sender = resolveParentSosSender();
    await sender.fireThrough(fire);

    expect(fire.fireLog.single.childId, 'demo-child');
    expect(fire.fireLog.single.actorId, 'mem_stage1_owner');

    final open = await Stage1SosFinalRuntime.service.loadOpen(
      childId: ChildId('demo-child'),
    );
    expect(open?.raisedByActorId, 'mem_stage1_owner');
    expect(open?.triggerSource, SosTriggerSource.parentAlert);
  });

  test('child hold still records child as actor', () async {
    final device = stage1IdentityRuntime.devices.firstWhere(
      (d) => d.childId == ChildId('child_b'),
    );
    final incident = await Stage1SosFinalRuntime.crossSystem.fireChildHold(
      childId: ChildId('child_b'),
      deviceId: device.id,
    );
    expect(incident.raisedByActorId, 'child_b');
    expect(incident.triggerSource, SosTriggerSource.hold);
    expect(incident.childId, ChildId('child_b'));
  });
}
