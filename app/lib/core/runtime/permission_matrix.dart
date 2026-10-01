import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

/// A stable product action, independent of a particular screen or route.
///
/// New settings and control-centre surfaces map to one of these capabilities;
/// route guards, tiles, controls and audit labels must use the same decision.
enum PanelCapability {
  viewFamily,
  manageFamily,
  manageMotherLevel,
  viewChildState,
  editChildRules,
  approveChildRequests,
  manageBilling,
  viewPrivacyAndAudit,
  managePrivacy,
  viewDeviceState,
  repairDevice,
  sendSos,
  requestPolicyChange,
  viewOwnTransparency,
}

/// How a panel should represent a capability to the current member.
enum PermissionDisposition { allow, readOnly, requestOnly, hidden }

/// Role-derived panel profile consumed by settings, hubs and controls.
@immutable
final class PanelProfile {
  const PanelProfile({required this.role, this.motherLevel});

  final AppRole role;
  final MotherLevel? motherLevel;

  factory PanelProfile.fromRole(
    AppRole role, {
    MotherLevel? motherLevel,
  }) {
    return PanelProfile(
      role: role,
      motherLevel: role == AppRole.mother
          ? (motherLevel ?? MotherLevel.observer)
          : null,
    );
  }
}

/// One product authority table for panels and future settings registry entries.
///
/// It is a client presentation decision only. Render/native authorization stays
/// authoritative for mutations; a visible allowed control is never proof that
/// a server-side action will succeed.
abstract final class PermissionMatrix {
  static PermissionDisposition dispositionFor(
    PanelProfile profile,
    PanelCapability capability,
  ) {
    return switch (profile.role) {
      AppRole.father => _father(capability),
      AppRole.mother => _mother(profile.motherLevel!, capability),
      AppRole.child => _child(capability),
    };
  }

  static PermissionDisposition _father(PanelCapability capability) =>
      PermissionDisposition.allow;

  static PermissionDisposition _mother(
    MotherLevel level,
    PanelCapability capability,
  ) {
    switch (capability) {
      case PanelCapability.manageMotherLevel:
      case PanelCapability.manageBilling:
        return PermissionDisposition.hidden;
      case PanelCapability.manageFamily:
      case PanelCapability.managePrivacy:
        return level == MotherLevel.full
            ? PermissionDisposition.allow
            : PermissionDisposition.readOnly;
      case PanelCapability.editChildRules:
      case PanelCapability.repairDevice:
        return level == MotherLevel.full
            ? PermissionDisposition.allow
            : PermissionDisposition.requestOnly;
      case PanelCapability.approveChildRequests:
        return level == MotherLevel.observer
            ? PermissionDisposition.requestOnly
            : PermissionDisposition.allow;
      case PanelCapability.viewFamily:
      case PanelCapability.viewChildState:
      case PanelCapability.viewPrivacyAndAudit:
      case PanelCapability.viewDeviceState:
      case PanelCapability.sendSos:
      case PanelCapability.requestPolicyChange:
      case PanelCapability.viewOwnTransparency:
        return PermissionDisposition.allow;
    }
  }

  static PermissionDisposition _child(PanelCapability capability) {
    switch (capability) {
      case PanelCapability.sendSos:
      case PanelCapability.viewOwnTransparency:
        return PermissionDisposition.allow;
      case PanelCapability.requestPolicyChange:
        return PermissionDisposition.requestOnly;
      case PanelCapability.viewChildState:
        return PermissionDisposition.readOnly;
      case PanelCapability.viewFamily:
      case PanelCapability.manageFamily:
      case PanelCapability.manageMotherLevel:
      case PanelCapability.editChildRules:
      case PanelCapability.approveChildRequests:
      case PanelCapability.manageBilling:
      case PanelCapability.viewPrivacyAndAudit:
      case PanelCapability.managePrivacy:
      case PanelCapability.viewDeviceState:
      case PanelCapability.repairDevice:
        return PermissionDisposition.hidden;
    }
  }
}
