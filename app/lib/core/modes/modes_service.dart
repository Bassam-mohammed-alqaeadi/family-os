import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/location/modes_location_fact_feed.dart';

import 'mode_activation.dart';
import 'mode_definition.dart';
import 'mode_exception.dart';
import 'modes_engine.dart';
import 'modes_repository.dart';

/// Actor for Modes configure / activate (MODE-OD-02 / MODE-OD-13).
@immutable
final class ModesActor {
  const ModesActor.father() : role = AppRole.father, motherLevel = null;

  const ModesActor.mother(this.motherLevel) : role = AppRole.mother;

  final AppRole role;
  final MotherLevel? motherLevel;

  bool get canConfigure =>
      role == AppRole.father ||
      (role == AppRole.mother && motherLevel == MotherLevel.full);

  bool get canTicketActivate =>
      role == AppRole.father ||
      (role == AppRole.mother &&
          (motherLevel == MotherLevel.partner ||
              motherLevel == MotherLevel.full));
}

/// Coordinates Modes mutations + evaluation (FS-005-OWN).
final class ModesService {
  ModesService({
    required ModesDomainRepository store,
    required this.familyId,
    ModesLocationFactFeed? locationFacts,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _store = store,
       _locationFacts = locationFacts,
       _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? _defaultId;

  final ModesDomainRepository _store;
  final FamilyId familyId;
  final ModesLocationFactFeed? _locationFacts;
  final DateTime Function() _clock;
  final String Function() _idFactory;

  static var _seq = 0;
  static String _defaultId() {
    _seq += 1;
    return 'mode-$_seq';
  }

  Future<List<ModeDefinition>> listModes() => _store.listModes(familyId);

  Future<ModeDefinition> saveMode({
    required ModeDefinition draft,
    required ModesActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot configure Modes');
    }
    ModesEngine.assertNoWiden(draft.overlay);
    final existing = await _store.getMode(familyId, draft.id);
    final next = ModeDefinition(
      id: draft.id,
      familyId: familyId,
      catalogId: draft.catalogId,
      customLabel: draft.customLabel,
      childScope: draft.childScope,
      targetChildIds: draft.targetChildIds,
      clockWindow: draft.clockWindow,
      locationZoneId: draft.locationZoneId,
      season: draft.season,
      overlay: draft.overlay.asTightenOnly(),
      graceMinutes: draft.graceMinutes,
      enabled: draft.enabled,
      policyVersion: (existing?.policyVersion ?? 0) + 1,
      updatedAt: _clock().toUtc(),
    );
    await _store.saveMode(next);
    return next;
  }

  Future<void> deleteMode({
    required String modeId,
    required ModesActor actor,
  }) async {
    if (!actor.canConfigure) {
      throw StateError('Actor cannot delete Modes');
    }
    await _store.deleteMode(familyId, modeId);
  }

  Future<ModeActivation> activateManual({
    required String modeId,
    required ChildId childId,
    required ModesActor actor,
  }) async {
    if (!actor.canTicketActivate) {
      throw StateError('Actor cannot activate Modes');
    }
    final mode = await _store.getMode(familyId, modeId);
    if (mode == null || !mode.enabled) {
      throw StateError('Mode not found or disabled');
    }
    if (!mode.targetsChild(childId)) {
      throw StateError('Mode does not target this child');
    }
    final act = ModeActivation(
      id: _idFactory(),
      familyId: familyId,
      modeId: modeId,
      childId: childId,
      channel: ModeActivationChannel.manual,
      active: true,
      startedAt: _clock().toUtc(),
    );
    await _store.saveActivation(act);
    return act;
  }

  Future<void> deactivateManual({
    required String modeId,
    required ChildId childId,
    required ModesActor actor,
  }) async {
    if (!actor.canTicketActivate) {
      throw StateError('Actor cannot deactivate Modes');
    }
    await _store.deactivateManual(
      familyId: familyId,
      modeId: modeId,
      childId: childId,
    );
  }

  Future<ModeException> grantModeException({
    required String modeId,
    required ChildId childId,
    required String note,
    required DateTime expiresAt,
    required ModesActor actor,
  }) async {
    if (!actor.canConfigure && !actor.canTicketActivate) {
      throw StateError('Actor cannot grant ModeException');
    }
    final mex = ModeException(
      id: _idFactory(),
      familyId: familyId,
      modeId: modeId,
      childId: childId,
      note: note,
      startsAt: _clock().toUtc(),
      expiresAt: expiresAt.toUtc(),
    );
    await _store.saveException(mex);
    return mex;
  }

  Future<ModesEvaluation> evaluateChild(ChildId childId, {DateTime? at}) async {
    final now = at ?? _clock();
    final modes = await _store.listModes(familyId);
    final manuals = await _store.listActivations(familyId, childId: childId);
    final exceptions = await _store.listExceptions(familyId, childId: childId);
    var facts = const <LocationModeFact>[];
    final feed = _locationFacts;
    if (feed != null) {
      facts = await feed.listForChild(familyId, childId);
    }
    return ModesEngine.evaluate(
      modes: modes,
      childId: childId,
      at: now,
      manualActivations: manuals,
      locationFacts: facts,
      exceptions: exceptions,
    );
  }
}
