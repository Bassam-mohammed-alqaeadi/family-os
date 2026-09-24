import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

import 'screen_camera_document.dart';
import 'screen_camera_repository.dart';

/// Actor for Screen & Camera configure (SC-OD-11).
@immutable
final class ScreenCameraActor {
  const ScreenCameraActor.father() : role = AppRole.father, motherLevel = null;

  const ScreenCameraActor.mother(this.motherLevel) : role = AppRole.mother;

  final AppRole role;
  final MotherLevel? motherLevel;

  bool get canConfigure =>
      role == AppRole.father ||
      (role == AppRole.mother && motherLevel == MotherLevel.full);

  bool get canDecideExceptions =>
      role == AppRole.father ||
      (role == AppRole.mother &&
          (motherLevel == MotherLevel.partner ||
              motherLevel == MotherLevel.full));
}

/// Coordinates Screen & Camera policy mutations (FS-004-OWN).
final class ScreenCameraService {
  ScreenCameraService({
    required ScreenCameraDomainRepository documents,
    required this.familyId,
    DateTime Function()? clock,
  }) : _documents = documents,
       _clock = clock ?? DateTime.now;

  final ScreenCameraDomainRepository _documents;
  final FamilyId familyId;
  final DateTime Function() _clock;

  Future<ScreenCameraDocument> loadEffective(ChildId childId) {
    return _documents.loadEffective(familyId, childId);
  }

  Future<ScreenCameraDocument> saveFamilyBaseline({
    required ScreenCameraDocument draft,
    required ScreenCameraActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot configure Screen & Camera policy');
    }
    if (draft.microphoneControlled) {
      throw StateError('Microphone is out of FS-004 scope');
    }
    final existing = await _documents.loadFamilyBaseline(familyId);
    final next = ScreenCameraDocument(
      familyId: familyId,
      scopeKind: ScreenCameraScopeKind.familyBaseline,
      preventCameraOs: draft.preventCameraOs,
      preventCapture: draft.preventCapture,
      monitorScreenshots: draft.monitorScreenshots,
      monitoredPackageIds: draft.monitoredPackageIds,
      protectSensitiveSurfaces: draft.protectSensitiveSurfaces,
      enabledExceptions: draft.enabledExceptions,
      policyVersion: (existing?.policyVersion ?? 0) + 1,
      updatedAt: _clock().toUtc(),
    );
    await _documents.save(next);
    return next;
  }

  Future<ScreenCameraDocument> saveChildPolicy({
    required ChildId childId,
    required ScreenCameraDocument draft,
    required ScreenCameraActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot configure Screen & Camera policy');
    }
    if (draft.microphoneControlled) {
      throw StateError('Microphone is out of FS-004 scope');
    }
    final existing = await _documents.loadChildOverride(familyId, childId);
    final next = ScreenCameraDocument(
      familyId: familyId,
      scopeKind: ScreenCameraScopeKind.childOverride,
      childId: childId,
      preventCameraOs: draft.preventCameraOs,
      preventCapture: draft.preventCapture,
      monitorScreenshots: draft.monitorScreenshots,
      monitoredPackageIds: draft.monitoredPackageIds,
      protectSensitiveSurfaces: draft.protectSensitiveSurfaces,
      enabledExceptions: draft.enabledExceptions,
      policyVersion: (existing?.policyVersion ?? 0) + 1,
      updatedAt: _clock().toUtc(),
    );
    await _documents.save(next);
    return next;
  }

  Future<ScreenCameraDocument> setScreenshotMonitoring({
    required ChildId childId,
    required bool enabled,
    Set<String> monitoredPackageIds = const {},
    required ScreenCameraActor actor,
  }) async {
    final current = await _documents.loadEffective(familyId, childId);
    return saveChildPolicy(
      childId: childId,
      draft: current.copyWith(
        monitorScreenshots: enabled,
        monitoredPackageIds: monitoredPackageIds,
      ),
      actor: actor,
    );
  }

  Future<ScreenCameraDocument> setCameraOsPrevent({
    required ChildId childId,
    required bool enabled,
    required ScreenCameraActor actor,
  }) async {
    final current = await _documents.loadEffective(familyId, childId);
    return saveChildPolicy(
      childId: childId,
      draft: current.copyWith(preventCameraOs: enabled),
      actor: actor,
    );
  }

  Future<void> restoreBaseline(ChildId childId, ScreenCameraActor actor) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot restore baseline');
    }
    await _documents.removeChildOverride(familyId, childId);
  }
}
