import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/identity/identity_models.dart';
import 'package:family_os/core/identity/identity_runtime.dart';

@immutable
final class ManagedChildRecord {
  const ManagedChildRecord({required this.familyId, required this.childId});

  final FamilyId familyId;
  final ChildId childId;
}

@immutable
final class ManagedDeviceRecord {
  const ManagedDeviceRecord({
    required this.familyId,
    required this.childId,
    required this.deviceId,
    required this.primary,
    required this.enrollments,
  });

  final FamilyId familyId;
  final ChildId childId;
  final DeviceId deviceId;
  final bool primary;
  final List<Enrollment> enrollments;

  Enrollment? get activeEnrollment {
    for (final enrollment in enrollments) {
      if (enrollment.state == EnrollmentState.enrolled) return enrollment;
    }
    return null;
  }
}

@immutable
final class ChildManagementCapabilities {
  const ChildManagementCapabilities({
    required this.canCreateChild,
    required this.canDeleteChild,
    required this.canManageDevices,
    required this.canCloseNuclearEnrollment,
    required this.canManageLogoutPermission,
    required this.canEndChildSession,
    required this.canChangePrimaryDevice,
  });

  final bool canCreateChild;
  final bool canDeleteChild;
  final bool canManageDevices;

  /// Primary-only: mark lost, revoke enrolled enrollment, decommission.
  final bool canCloseNuclearEnrollment;
  final bool canManageLogoutPermission;
  final bool canEndChildSession;
  final bool canChangePrimaryDevice;
}

enum EnrollmentCloseReason { revoked, lost, decommissioned }

abstract class ChildDeviceManagementRepository {
  ChildManagementCapabilities capabilitiesFor(FamilyId familyId);

  List<ManagedChildRecord> listChildren(FamilyId familyId);
  ManagedChildRecord createChild({
    required FamilyId familyId,
    required ChildId childId,
  });
  bool deleteChild({required FamilyId familyId, required ChildId childId});

  List<ManagedDeviceRecord> listDevices({
    required FamilyId familyId,
    required ChildId childId,
  });
  Enrollment startPairing({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  });
  Enrollment? findEnrollment(EnrollmentId enrollmentId);
  Enrollment? findPendingByPairingToken(PairingTokenId token);
  Enrollment finalizeEnrollment(EnrollmentId enrollmentId);
  void closeEnrollment({
    required EnrollmentId enrollmentId,
    required EnrollmentCloseReason reason,
  });
  Enrollment reEnroll({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  });
  bool setChildLogoutPermission({
    required EnrollmentId enrollmentId,
    required bool allowed,
  });
  bool remoteEndChildSession(EnrollmentId enrollmentId);
  bool setPrimaryDevice({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  });
}

final class RuntimeChildDeviceManagementRepository
    with ChangeNotifier
    implements ChildDeviceManagementRepository {
  RuntimeChildDeviceManagementRepository({required IdentityRuntime runtime})
    : _runtime = runtime {
    runtime.addListener(notifyListeners);
  }

  final IdentityRuntime _runtime;
  IdentityRuntime get runtime => _runtime;
  final Map<String, DeviceId> _primaryByChildKey = <String, DeviceId>{};

  @override
  ChildManagementCapabilities capabilitiesFor(FamilyId familyId) {
    final membership = _runtime
        .membershipsForAccount(_runtime.account.id)
        .firstWhere(
          (it) => it.familyId == familyId,
          orElse: () => _runtime.activeMembership,
        );
    final canCreate =
        membership.isPrimaryOwner ||
        (membership.role == AppRole.mother &&
            membership.motherLevel == MotherLevel.full);
    final canDelete = membership.isPrimaryOwner;
    return ChildManagementCapabilities(
      canCreateChild: canCreate,
      canDeleteChild: canDelete,
      canManageDevices: canCreate,
      canCloseNuclearEnrollment: membership.isPrimaryOwner,
      canManageLogoutPermission: membership.isPrimaryOwner,
      canEndChildSession: membership.isPrimaryOwner,
      canChangePrimaryDevice: membership.isPrimaryOwner,
    );
  }

  @override
  List<ManagedChildRecord> listChildren(FamilyId familyId) {
    return _runtime.children
        .where((child) => child.familyId == familyId)
        .map(
          (child) =>
              ManagedChildRecord(familyId: child.familyId, childId: child.id),
        )
        .toList(growable: false);
  }

  @override
  ManagedChildRecord createChild({
    required FamilyId familyId,
    required ChildId childId,
  }) {
    _assertCapability(familyId, (c) => c.canCreateChild, 'create child');
    final child = _runtime.createChild(familyId: familyId, childId: childId);
    return ManagedChildRecord(familyId: child.familyId, childId: child.id);
  }

  @override
  bool deleteChild({required FamilyId familyId, required ChildId childId}) {
    _assertCapability(familyId, (c) => c.canDeleteChild, 'delete child');
    return _runtime.deleteChild(familyId: familyId, childId: childId);
  }

  @override
  List<ManagedDeviceRecord> listDevices({
    required FamilyId familyId,
    required ChildId childId,
  }) {
    final enrollments = _runtime.enrollments
        .where((e) => e.familyId == familyId && e.childId == childId)
        .toList(growable: false);
    final byDevice = <String, List<Enrollment>>{};
    for (final enrollment in enrollments) {
      byDevice
          .putIfAbsent(enrollment.deviceId.value, () => <Enrollment>[])
          .add(enrollment);
    }
    final key = _childKey(familyId, childId);
    final configuredPrimary = _primaryByChildKey[key];
    final records = byDevice.entries
        .map((entry) {
          final deviceId = DeviceId(entry.key);
          final items = entry.value
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ManagedDeviceRecord(
            familyId: familyId,
            childId: childId,
            deviceId: deviceId,
            primary:
                configuredPrimary == deviceId ||
                (configuredPrimary == null &&
                    _firstActiveDevice(items) == deviceId),
            enrollments: List<Enrollment>.unmodifiable(items),
          );
        })
        .toList(growable: false);
    return records;
  }

  @override
  Enrollment startPairing({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  }) {
    _assertFamilyAccess(familyId);
    _assertCapability(familyId, (c) => c.canManageDevices, 'start pairing');
    return _runtime.startPairing(
      familyId: familyId,
      childId: childId,
      deviceId: deviceId,
    );
  }

  @override
  Enrollment? findEnrollment(EnrollmentId enrollmentId) {
    for (final enrollment in _runtime.enrollments) {
      if (enrollment.id == enrollmentId) return enrollment;
    }
    return null;
  }

  @override
  Enrollment? findPendingByPairingToken(PairingTokenId token) {
    final normalized = token.value.trim();
    for (final enrollment in _runtime.enrollments) {
      final pairing = enrollment.pairingTokenId?.value.trim();
      if (pairing == null) continue;
      if (pairing == normalized &&
          enrollment.state == EnrollmentState.pairingPending) {
        return enrollment;
      }
    }
    return null;
  }

  @override
  Enrollment finalizeEnrollment(EnrollmentId enrollmentId) {
    final enrollment = _requireEnrollment(enrollmentId);
    _assertCapability(
      enrollment.familyId,
      (c) => c.canManageDevices,
      'finalize enrollment',
    );
    return _runtime.finalizeEnrollment(enrollmentId);
  }

  @override
  void closeEnrollment({
    required EnrollmentId enrollmentId,
    required EnrollmentCloseReason reason,
  }) {
    final enrollment = _requireEnrollment(enrollmentId);
    // Canceling a pending pairing token is part of add/pair/renew (Mother Full OK).
    // Nuclear close of an enrolled (or otherwise closed) enrollment is Primary-only.
    final cancelPendingPairing =
        reason == EnrollmentCloseReason.revoked && enrollment.isPairingPending;
    if (cancelPendingPairing) {
      _assertCapability(
        enrollment.familyId,
        (c) => c.canManageDevices,
        'cancel pending pairing',
      );
    } else {
      _assertCapability(
        enrollment.familyId,
        (c) => c.canCloseNuclearEnrollment,
        'close enrollment ($reason)',
      );
    }
    switch (reason) {
      case EnrollmentCloseReason.revoked:
        _runtime.revokeEnrollment(enrollmentId);
        return;
      case EnrollmentCloseReason.lost:
        _runtime.markEnrollmentLost(enrollmentId);
        return;
      case EnrollmentCloseReason.decommissioned:
        _runtime.decommissionEnrollment(enrollmentId);
        return;
    }
  }

  @override
  Enrollment reEnroll({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  }) {
    _assertFamilyAccess(familyId);
    _assertCapability(familyId, (c) => c.canManageDevices, 're-enroll device');
    return _runtime.createEnrollment(
      familyId: familyId,
      childId: childId,
      deviceId: deviceId,
    );
  }

  @override
  bool setChildLogoutPermission({
    required EnrollmentId enrollmentId,
    required bool allowed,
  }) {
    final enrollment = _requireEnrollment(enrollmentId);
    if (!capabilitiesFor(enrollment.familyId).canManageLogoutPermission) {
      return false;
    }
    return _runtime.setChildLogoutAllowedForEnrollment(
      enrollmentId: enrollmentId,
      allowed: allowed,
    );
  }

  @override
  bool remoteEndChildSession(EnrollmentId enrollmentId) {
    final enrollment = _requireEnrollment(enrollmentId);
    if (!capabilitiesFor(enrollment.familyId).canEndChildSession) {
      return false;
    }
    return _runtime.endChildSessionRemotely(enrollmentId);
  }

  @override
  bool setPrimaryDevice({
    required FamilyId familyId,
    required ChildId childId,
    required DeviceId deviceId,
  }) {
    _assertFamilyAccess(familyId);
    if (!capabilitiesFor(familyId).canChangePrimaryDevice) {
      return false;
    }
    final records = listDevices(familyId: familyId, childId: childId);
    final target = records.where((it) => it.deviceId == deviceId).toList();
    if (target.isEmpty) return false;
    final hasActive = target.first.enrollments.any(
      (enrollment) => enrollment.state == EnrollmentState.enrolled,
    );
    if (!hasActive) return false;
    _primaryByChildKey[_childKey(familyId, childId)] = deviceId;
    notifyListeners();
    return true;
  }

  void _assertFamilyAccess(FamilyId familyId) {
    final hasMembership = _runtime
        .membershipsForAccount(_runtime.account.id)
        .any((membership) => membership.familyId == familyId);
    if (!hasMembership) {
      throw IdentityInvariantViolation(
        'cross-family access denied for ${familyId.value}',
      );
    }
  }

  void _assertCapability(
    FamilyId familyId,
    bool Function(ChildManagementCapabilities caps) allowed,
    String action,
  ) {
    if (!allowed(capabilitiesFor(familyId))) {
      throw IdentityInvariantViolation('$action denied for ${familyId.value}');
    }
  }

  Enrollment _requireEnrollment(EnrollmentId enrollmentId) {
    for (final enrollment in _runtime.enrollments) {
      if (enrollment.id == enrollmentId) return enrollment;
    }
    throw IdentityInvariantViolation(
      'unknown enrollment ${enrollmentId.value}',
    );
  }

  String _childKey(FamilyId familyId, ChildId childId) =>
      '${familyId.value}::${childId.value}';

  DeviceId? _firstActiveDevice(List<Enrollment> enrollments) {
    for (final enrollment in enrollments) {
      if (enrollment.state == EnrollmentState.enrolled) {
        return enrollment.deviceId;
      }
    }
    return null;
  }
}

final RuntimeChildDeviceManagementRepository
stage1ChildDeviceManagementRepository = RuntimeChildDeviceManagementRepository(
  runtime: stage1IdentityRuntime,
);
