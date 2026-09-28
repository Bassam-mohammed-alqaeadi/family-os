import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';

/// Local persistence seam for active family context per account.
abstract class FamilyContextStore {
  FamilyId? loadActiveFamily(AccountId accountId);
  Future<void> saveActiveFamily(AccountId accountId, FamilyId familyId);
}

@visibleForTesting
final class MemoryFamilyContextStore implements FamilyContextStore {
  MemoryFamilyContextStore([Map<String, String>? seed])
      : _data = seed == null ? <String, String>{} : Map<String, String>.from(seed);

  final Map<String, String> _data;

  @override
  FamilyId? loadActiveFamily(AccountId accountId) {
    final raw = _data[accountId.value];
    if (raw == null || raw.trim().isEmpty) return null;
    return FamilyId(raw);
  }

  @override
  Future<void> saveActiveFamily(AccountId accountId, FamilyId familyId) async {
    _data[accountId.value] = familyId.value;
  }
}

/// LEGACY / RETAINED — Memory family context. Production boot prefers Local KV
/// via [IdentityLocalPersistence.tryBindStage1FamilyContext] (DOM-IDENTITY-A).
final MemoryFamilyContextStore stage1FamilyContextStore =
    MemoryFamilyContextStore();
