import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

String familyScopedChildKey({
  required FamilyId familyId,
  required ChildId childId,
}) {
  return '${familyId.value}::${childId.value}';
}

ChildId familyScopedChildId({
  required FamilyId familyId,
  required ChildId childId,
}) {
  return ChildId(familyScopedChildKey(familyId: familyId, childId: childId));
}

ChildId activeScopedChildId([IdentityRuntime? runtime]) {
  final identity = runtime ?? stage1IdentityRuntime;
  return familyScopedChildId(
    familyId: identity.activeFamilyId,
    childId: identity.activeChildId,
  );
}

ChildScope activeChildScope([IdentityRuntime? runtime]) {
  final identity = runtime ?? stage1IdentityRuntime;
  return ChildScope(
    familyId: identity.activeFamilyId,
    childId: identity.activeChildId,
  );
}
