import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'mode_activation.dart';
import 'mode_definition.dart';
import 'mode_exception.dart';

/// Domain repository seam for Modes (Rule 25).
abstract class ModesDomainRepository {
  Future<List<ModeDefinition>> listModes(FamilyId familyId);

  Future<ModeDefinition?> getMode(FamilyId familyId, String modeId);

  Future<void> saveMode(ModeDefinition mode);

  Future<void> deleteMode(FamilyId familyId, String modeId);

  Future<List<ModeActivation>> listActivations(
    FamilyId familyId, {
    ChildId? childId,
  });

  Future<void> saveActivation(ModeActivation activation);

  Future<void> deactivateManual({
    required FamilyId familyId,
    required String modeId,
    required ChildId childId,
  });

  Future<List<ModeException>> listExceptions(
    FamilyId familyId, {
    ChildId? childId,
  });

  Future<void> saveException(ModeException exception);
}
