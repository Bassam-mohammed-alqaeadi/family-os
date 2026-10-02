import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/identity/child_device_management_repository.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/runtime/family_device_source.dart';
import 'package:family_os/core/runtime/family_policy_source.dart';
import 'package:family_os/core/runtime/family_roster_source.dart';
import 'package:family_os/core/runtime/runtime_data_origin.dart';
import 'package:family_os/features/n02_day/children_list_repository.dart';

/// Transitional local adapter for the Children Control Centre roster.
///
/// This is deliberately composed in the app root and labelled [localOnly]. It
/// merges the managed-child registry with display profiles without inventing a
/// profile for a managed child that lacks one. A future Render adapter can
/// replace it without changing screen contracts.
final class LocalFamilyRosterSource extends ChangeNotifier
    implements FamilyRosterSource {
  LocalFamilyRosterSource({
    required ChildrenListRepository repository,
    required ChildDeviceManagementRepository managementRepository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _managementRepository = managementRepository,
       _clock = clock ?? DateTime.now;

  final ChildrenListRepository _repository;
  final ChildDeviceManagementRepository _managementRepository;
  final DateTime Function() _clock;
  FamilyRosterSnapshot _value = const FamilyRosterSnapshot.unavailable();

  @override
  FamilyRosterSnapshot get value => _value;

  @override
  Future<FamilyRosterSnapshot> load(FamilyId familyId) async {
    final profiles = await _repository.listChildren(familyId: familyId);
    final profileById = <String, ChildrenListEntry>{
      for (final profile in profiles) profile.id: profile,
    };
    final managed = _managementRepository.listChildren(familyId);
    final children = <FamilyRosterChild>[];
    final seen = <String>{};

    // Registry records establish that a child exists. Missing display profile
    // fields remain null so the UI can offer setup/repair rather than a fake
    // child card.
    for (final record in managed) {
      final id = record.childId.value;
      final profile = profileById[id];
      children.add(_childFrom(id: id, profile: profile));
      seen.add(id);
    }

    // The pre-existing local roster remains a valid local record during the
    // transition, even before every row is represented in the managed registry.
    for (final profile in profiles) {
      if (!seen.add(profile.id)) continue;
      children.add(_childFrom(id: profile.id, profile: profile));
    }

    return _publish(
      FamilyRosterSnapshot(
        familyId: familyId,
        origin: RuntimeDataOrigin.localOnly,
        children: List.unmodifiable(children),
        observedAt: _clock(),
      ),
    );
  }

  FamilyRosterChild _childFrom({
    required String id,
    required ChildrenListEntry? profile,
  }) {
    final displayName = profile?.displayName.trim();
    return FamilyRosterChild(
      childId: ChildId(id),
      displayName: displayName == null || displayName.isEmpty ? null : displayName,
      // Zero is a valid known age for an infant. It is only null when there is
      // no profile record, never synthesized for a managed registry record.
      ageYears: profile?.ageYears,
    );
  }

  FamilyRosterSnapshot _publish(FamilyRosterSnapshot next) {
    _value = next;
    notifyListeners();
    return next;
  }
}

/// Transitional local adapter for child-device connection summaries.
///
/// It only reports enrollment-derived connection state. Location, battery and
/// online safety claims remain absent until their own authoritative sources
/// exist.
final class LocalFamilyDeviceSource extends ChangeNotifier
    implements FamilyDeviceSource {
  LocalFamilyDeviceSource({
    required ChildDeviceManagementRepository managementRepository,
    DateTime Function()? clock,
  }) : _managementRepository = managementRepository,
       _clock = clock ?? DateTime.now;

  final ChildDeviceManagementRepository _managementRepository;
  final DateTime Function() _clock;
  FamilyDeviceSnapshot _value = const FamilyDeviceSnapshot.unavailable();

  @override
  FamilyDeviceSnapshot get value => _value;

  @override
  Future<FamilyDeviceSnapshot> load(FamilyId familyId) async {
    final summaries = <FamilyChildDeviceSummary>[];
    for (final child in _managementRepository.listChildren(familyId)) {
      final devices = _managementRepository.listDevices(
        familyId: familyId,
        childId: child.childId,
      );
      final enrollments = [
        for (final device in devices) ...device.enrollments,
      ];
      summaries.add(
        FamilyChildDeviceSummary(
          childId: child.childId,
          deviceCount: devices.length,
          connectionState: _connectionState(enrollments),
        ),
      );
    }
    final next = FamilyDeviceSnapshot(
      familyId: familyId,
      origin: RuntimeDataOrigin.localOnly,
      children: List.unmodifiable(summaries),
      observedAt: _clock(),
    );
    _value = next;
    notifyListeners();
    return next;
  }

  ChildDeviceConnectionState _connectionState(List<Enrollment> enrollments) {
    if (enrollments.isEmpty) return ChildDeviceConnectionState.noDevice;
    if (enrollments.any((it) => it.state == EnrollmentState.enrolled)) {
      return ChildDeviceConnectionState.active;
    }
    if (enrollments.any((it) => it.state == EnrollmentState.pairingPending)) {
      return ChildDeviceConnectionState.pairing;
    }
    return ChildDeviceConnectionState.needsAttention;
  }
}

/// Transitional local adapter for the shared children policy sheet.
///
/// A successful save is intentionally still `localOnly`; it is not an
/// enforcement receipt from a policy engine.
final class LocalFamilyPolicySource extends ChangeNotifier
    implements FamilyPolicySource {
  LocalFamilyPolicySource({
    required ChildrenListRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final ChildrenListRepository _repository;
  final DateTime Function() _clock;
  FamilyPolicySnapshot _value = const FamilyPolicySnapshot.unavailable();

  @override
  FamilyPolicySnapshot get value => _value;

  @override
  Future<FamilyPolicySnapshot> load(FamilyId familyId) async {
    final stored = await _repository.loadSharedPolicies(familyId: familyId);
    return _publish(familyId, _fromLegacy(stored));
  }

  @override
  Future<FamilyPolicySnapshot> saveSharedPolicy(
    FamilyId familyId,
    FamilySharedPolicy policy,
  ) async {
    await _repository.saveSharedPolicies(
      _toLegacy(policy),
      familyId: familyId,
    );
    return _publish(familyId, policy);
  }

  FamilyPolicySnapshot _publish(FamilyId familyId, FamilySharedPolicy policy) {
    final next = FamilyPolicySnapshot(
      familyId: familyId,
      origin: RuntimeDataOrigin.localOnly,
      sharedPolicy: policy,
      observedAt: _clock(),
    );
    _value = next;
    notifyListeners();
    return next;
  }

  FamilySharedPolicy _fromLegacy(SharedChildrenPolicies policy) =>
      FamilySharedPolicy(
        scopeAll: policy.scopeAll,
        selectedChildIds: List.unmodifiable(policy.selectedChildIds),
        dailyCapHours: policy.dailyCapHours,
        bedtimeLabel: policy.bedtimeLabel,
        webFilterOn: policy.webFilterOn,
      );

  SharedChildrenPolicies _toLegacy(FamilySharedPolicy policy) =>
      SharedChildrenPolicies(
        scopeAll: policy.scopeAll,
        selectedChildIds: List.unmodifiable(policy.selectedChildIds),
        dailyCapHours: policy.dailyCapHours,
        bedtimeLabel: policy.bedtimeLabel,
        webFilterOn: policy.webFilterOn,
      );
}
