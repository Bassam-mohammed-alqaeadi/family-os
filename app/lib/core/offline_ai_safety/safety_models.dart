import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';
import 'package:family_os/core/domain/mother_level.dart';
import 'package:family_os/core/domain/role.dart';

import 'safety_taxonomy.dart';

/// Signed + versioned on-device model manifest (AI-OD-01 / AI-OD-11).
@immutable
final class SignedModelManifest {
  const SignedModelManifest({
    required this.modelId,
    required this.version,
    required this.signature,
    required this.policyVersion,
    this.active = false,
  });

  final String modelId;
  final String version;
  final String signature;
  final String policyVersion;
  final bool active;

  bool get isSigned => signature.trim().isNotEmpty;
  bool get isVersioned => version.trim().isNotEmpty;

  /// Unsigned / unversioned must not execute (AI-OD-11).
  bool get mayExecute => isSigned && isVersioned;

  SignedModelManifest copyWith({bool? active}) => SignedModelManifest(
        modelId: modelId,
        version: version,
        signature: signature,
        policyVersion: policyVersion,
        active: active ?? this.active,
      );

  Map<String, Object?> toRow(FamilyId familyId) => {
        'model_id': modelId,
        'family_id': familyId.value,
        'version': version,
        'signature': signature,
        'policy_version': policyVersion,
        'active': active ? 1 : 0,
      };

  factory SignedModelManifest.fromRow(Map<String, Object?> row) {
    return SignedModelManifest(
      modelId: row['model_id']! as String,
      version: row['version']! as String,
      signature: row['signature']! as String,
      policyVersion: row['policy_version']! as String,
      active: (row['active']! as int) == 1,
    );
  }
}

/// Typed safety fact — NOT final policy (AI-SF-05).
@immutable
final class SafetySignal {
  const SafetySignal({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.category,
    required this.certainty,
    required this.severity,
    required this.provenance,
    required this.modelVersion,
    required this.policyVersion,
    required this.createdAt,
    this.tool = SafetyToolKind.searchAnalysis,
    this.redactedPreview,
    this.notified = false,
    this.ticketId,
  });

  final String id;
  final FamilyId familyId;
  final ChildId childId;
  final SafetyCategory category;
  final SafetyCertainty certainty;
  final SafetySeverity severity;
  final SafetyProvenance provenance;
  final String modelVersion;
  final String policyVersion;
  final DateTime createdAt;
  final SafetyToolKind tool;

  /// Redacted preview for reviewers — never unrestricted raw (AI-OD-05).
  final String? redactedPreview;
  final bool notified;
  final String? ticketId;

  bool get opensTicket => SafetyTicketGate.shouldOpenTicket(certainty);

  SafetySignal copyWith({
    bool? notified,
    String? ticketId,
    String? redactedPreview,
    bool clearPreview = false,
  }) {
    return SafetySignal(
      id: id,
      familyId: familyId,
      childId: childId,
      category: category,
      certainty: certainty,
      severity: severity,
      provenance: provenance,
      modelVersion: modelVersion,
      policyVersion: policyVersion,
      createdAt: createdAt,
      tool: tool,
      redactedPreview:
          clearPreview ? null : (redactedPreview ?? this.redactedPreview),
      notified: notified ?? this.notified,
      ticketId: ticketId ?? this.ticketId,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'family_id': familyId.value,
        'child_id': childId.value,
        'category': category.wireName,
        'certainty': certainty.wireName,
        'severity': severity.wireName,
        'provenance': provenance.wireName,
        'model_version': modelVersion,
        'policy_version': policyVersion,
        'tool': tool.name,
        'redacted_preview': redactedPreview,
        'notified': notified ? 1 : 0,
        'ticket_id': ticketId,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
      };

  factory SafetySignal.fromRow(Map<String, Object?> row) {
    return SafetySignal(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      childId: ChildId(row['child_id']! as String),
      category: SafetyCategoryWire.parse(row['category']! as String),
      certainty: SafetyCertaintyWire.parse(row['certainty']! as String),
      severity: SafetySeverityWire.parse(row['severity']! as String),
      provenance: SafetyProvenanceWire.parse(row['provenance']! as String),
      modelVersion: row['model_version']! as String,
      policyVersion: row['policy_version']! as String,
      tool: SafetyToolKind.values.byName(row['tool']! as String),
      redactedPreview: row['redacted_preview'] as String?,
      notified: (row['notified']! as int) == 1,
      ticketId: row['ticket_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
    );
  }
}

enum SafetyTicketStatus {
  open,
  inReview,
  resolved,
  dismissedFp,
  suggestionPending,
}

@immutable
final class SafetyTicket {
  const SafetyTicket({
    required this.id,
    required this.familyId,
    required this.signalId,
    required this.childId,
    required this.status,
    required this.createdAt,
    this.redactedPreview,
    this.closedAt,
    this.closedBy,
  });

  final String id;
  final FamilyId familyId;
  final String signalId;
  final ChildId childId;
  final SafetyTicketStatus status;
  final DateTime createdAt;
  final String? redactedPreview;
  final DateTime? closedAt;
  final String? closedBy;

  bool get isOpen =>
      status == SafetyTicketStatus.open ||
      status == SafetyTicketStatus.inReview ||
      status == SafetyTicketStatus.suggestionPending;

  SafetyTicket copyWith({
    SafetyTicketStatus? status,
    String? redactedPreview,
    bool clearPreview = false,
    DateTime? closedAt,
    String? closedBy,
  }) {
    return SafetyTicket(
      id: id,
      familyId: familyId,
      signalId: signalId,
      childId: childId,
      status: status ?? this.status,
      createdAt: createdAt,
      redactedPreview:
          clearPreview ? null : (redactedPreview ?? this.redactedPreview),
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'family_id': familyId.value,
        'signal_id': signalId,
        'child_id': childId.value,
        'status': status.name,
        'redacted_preview': redactedPreview,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
        'closed_at': closedAt?.toUtc().millisecondsSinceEpoch,
        'closed_by': closedBy,
      };

  factory SafetyTicket.fromRow(Map<String, Object?> row) {
    return SafetyTicket(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      signalId: row['signal_id']! as String,
      childId: ChildId(row['child_id']! as String),
      status: SafetyTicketStatus.values.byName(row['status']! as String),
      redactedPreview: row['redacted_preview'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
      closedAt: row['closed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row['closed_at']! as int,
              isUtc: true,
            ),
      closedBy: row['closed_by'] as String?,
    );
  }
}

/// Suggest-only hand-off toward owning systems (AI-OD-09) — never auto-apply.
enum SafetySuggestionTarget { webFilter, appControl, modes }

enum SafetySuggestionStatus { pendingHuman, approved, rejected }

@immutable
final class SafetySuggestion {
  const SafetySuggestion({
    required this.id,
    required this.familyId,
    required this.ticketId,
    required this.target,
    required this.summary,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final FamilyId familyId;
  final String ticketId;
  final SafetySuggestionTarget target;
  final String summary;
  final SafetySuggestionStatus status;
  final DateTime createdAt;

  /// Structural: no execute() — human approve is external to owning system.
  bool get mayAutoApply => false;

  Map<String, Object?> toRow() => {
        'id': id,
        'family_id': familyId.value,
        'ticket_id': ticketId,
        'target': target.name,
        'summary': summary,
        'status': status.name,
        'created_at': createdAt.toUtc().millisecondsSinceEpoch,
      };

  factory SafetySuggestion.fromRow(Map<String, Object?> row) {
    return SafetySuggestion(
      id: row['id']! as String,
      familyId: FamilyId(row['family_id']! as String),
      ticketId: row['ticket_id']! as String,
      target: SafetySuggestionTarget.values.byName(row['target']! as String),
      summary: row['summary']! as String,
      status: SafetySuggestionStatus.values.byName(row['status']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at']! as int,
        isUtc: true,
      ),
    );
  }
}

/// Child transparency card state (AI-OD-06) — domain facts for UX later.
@immutable
final class ChildSafetyTransparency {
  const ChildSafetyTransparency({
    required this.searchAnalysis,
    required this.imageClassification,
    required this.screenshotMonitoring,
    required this.namesOnDeviceOffline,
  });

  final String searchAnalysis;
  final String imageClassification;
  final String screenshotMonitoring;

  /// Must name offline/local on-device when local plane applies.
  final bool namesOnDeviceOffline;
}

/// RBAC for FS-007 (AI-OD-04 / AI-OD-11).
@immutable
final class SafetyAiActor {
  const SafetyAiActor.father() : role = AppRole.father, motherLevel = null;
  const SafetyAiActor.mother(this.motherLevel) : role = AppRole.mother;
  const SafetyAiActor.child() : role = AppRole.child, motherLevel = null;

  final AppRole role;
  final MotherLevel? motherLevel;

  bool get canConfigure =>
      role == AppRole.father ||
      (role == AppRole.mother && motherLevel == MotherLevel.full);

  bool get canApplyModel => canConfigure;

  bool get canReceiveNotify =>
      role == AppRole.father ||
      (role == AppRole.mother &&
          (motherLevel == MotherLevel.full ||
              motherLevel == MotherLevel.partner));

  bool get canReviewTicket => canReceiveNotify;

  bool get isObserver =>
      role == AppRole.mother && motherLevel == MotherLevel.observer;
}
