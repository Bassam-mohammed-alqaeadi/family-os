import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'screen_camera_document.dart';

/// Domain repository seam for Screen & Camera policy (Rule 25).
abstract class ScreenCameraDomainRepository {
  Future<ScreenCameraDocument?> loadFamilyBaseline(FamilyId familyId);

  Future<ScreenCameraDocument?> loadChildOverride(
    FamilyId familyId,
    ChildId childId,
  );

  Future<ScreenCameraDocument> loadEffective(
    FamilyId familyId,
    ChildId childId,
  );

  Future<void> save(ScreenCameraDocument document);

  Future<void> removeChildOverride(FamilyId familyId, ChildId childId);
}
