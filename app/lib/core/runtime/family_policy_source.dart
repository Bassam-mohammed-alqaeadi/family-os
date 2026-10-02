import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';

/// Typed, UI-safe form of the shared policy currently shown on FAT-012.
///
/// It does not claim that a policy was enforced. Future API-backed adapters
/// will add authoritative version / application receipts separately.
@immutable
final class FamilySharedPolicy {
  const FamilySharedPolicy({
    this.scopeAll = true,
    this.selectedChildIds = const [],
    this.dailyCapHours = 4,
    this.bedtimeLabel = '',
    this.webFilterOn = true,
  });

  final bool scopeAll;
  final List<String> selectedChildIds;
  final int dailyCapHours;
  final String bedtimeLabel;
  final bool webFilterOn;

  FamilySharedPolicy copyWith({
    bool? scopeAll,
    List<String>? selectedChildIds,
    int? dailyCapHours,
    String? bedtimeLabel,
    bool? webFilterOn,
  }) {
    return FamilySharedPolicy(
      scopeAll: scopeAll ?? this.scopeAll,
      selectedChildIds: selectedChildIds ?? this.selectedChildIds,
      dailyCapHours: dailyCapHours ?? this.dailyCapHours,
      bedtimeLabel: bedtimeLabel ?? this.bedtimeLabel,
      webFilterOn: webFilterOn ?? this.webFilterOn,
    );
  }
}

@immutable
final class FamilyPolicySnapshot {
  const FamilyPolicySnapshot({
    required this.familyId,
    required this.origin,
    required this.sharedPolicy,
    this.observedAt,
  });

  const FamilyPolicySnapshot.unavailable()
    : familyId = null,
      origin = RuntimeDataOrigin.unavailable,
      sharedPolicy = null,
      observedAt = null;

  final FamilyId? familyId;
  final RuntimeDataOrigin origin;
  final FamilySharedPolicy? sharedPolicy;
  final DateTime? observedAt;

  bool get canMutateLocally => origin == RuntimeDataOrigin.localOnly;
}

/// Typed source boundary for the shared children policy.
///
/// `saveSharedPolicy` is only a transport request. A UI must present the
/// resulting origin and eventually the API application receipt; it must not
/// turn a local write into a remote-enforcement claim.
abstract interface class FamilyPolicySource
    implements ValueListenable<FamilyPolicySnapshot> {
  Future<FamilyPolicySnapshot> load(FamilyId familyId);

  Future<FamilyPolicySnapshot> saveSharedPolicy(
    FamilyId familyId,
    FamilySharedPolicy policy,
  );

  void dispose();
}

/// Honest default for uncomposed routes.
final class UnavailableFamilyPolicySource extends ChangeNotifier
    implements FamilyPolicySource {
  FamilyPolicySnapshot _value = const FamilyPolicySnapshot.unavailable();

  @override
  FamilyPolicySnapshot get value => _value;

  @override
  Future<FamilyPolicySnapshot> load(FamilyId familyId) async {
    _value = const FamilyPolicySnapshot.unavailable();
    notifyListeners();
    return _value;
  }

  @override
  Future<FamilyPolicySnapshot> saveSharedPolicy(
    FamilyId familyId,
    FamilySharedPolicy policy,
  ) async {
    return load(familyId);
  }
}
