import 'package:flutter/foundation.dart';

import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/domain/identity_ids.dart';

import 'safety_models.dart';
import 'safety_taxonomy.dart';

/// Classify input payload for local FS-007 (no cloud in v1).
@immutable
final class SafetyClassifyRequest {
  const SafetyClassifyRequest({
    required this.familyId,
    required this.childId,
    required this.text,
    this.tool = SafetyToolKind.searchAnalysis,
  });

  final FamilyId familyId;
  final ChildId childId;
  final String text;
  final SafetyToolKind tool;
}

@immutable
final class SafetyClassifyHit {
  const SafetyClassifyHit({
    required this.category,
    required this.certainty,
    required this.severity,
    required this.provenance,
    this.redactedPreview,
  });

  final SafetyCategory category;
  final SafetyCertainty certainty;
  final SafetySeverity severity;
  final SafetyProvenance provenance;
  final String? redactedPreview;
}

/// Local classifier port — signed model required to run (AI-OD-11).
abstract class LocalSafetyClassifier {
  Future<SafetyClassifyHit?> classify(
    SafetyClassifyRequest request, {
    required SignedModelManifest model,
  });
}

/// Stage-1 heuristic stub — emits signals only; never mutates policy / SOS.
///
/// Keyword markers are fixtures for domain proof — not production ML truth.
final class HeuristicSafetyClassifier implements LocalSafetyClassifier {
  @override
  Future<SafetyClassifyHit?> classify(
    SafetyClassifyRequest request, {
    required SignedModelManifest model,
  }) async {
    if (!model.mayExecute) {
      throw StateError('Unsigned/unversioned model must not execute');
    }
    final t = request.text.toLowerCase();
    if (t.trim().isEmpty) return null;

    // Deliberately non-numeric product semantics (AI-OD-08 / AI-SF-24).
    if (t.contains('[confirmed:violence]')) {
      return const SafetyClassifyHit(
        category: SafetyCategory.violenceOrThreat,
        certainty: SafetyCertainty.confirmed,
        severity: SafetySeverity.high,
        provenance: SafetyProvenance.localHeuristic,
        redactedPreview: '[redacted · violence concern]',
      );
    }
    if (t.contains('[analysis:suspicious]')) {
      return const SafetyClassifyHit(
        category: SafetyCategory.suspiciousLanguage,
        certainty: SafetyCertainty.analysis,
        severity: SafetySeverity.elevated,
        provenance: SafetyProvenance.localHeuristic,
        redactedPreview: '[redacted · language concern]',
      );
    }
    if (t.contains('[preliminary:self_harm]')) {
      return const SafetyClassifyHit(
        category: SafetyCategory.selfHarmSignal,
        certainty: SafetyCertainty.preliminary,
        severity: SafetySeverity.high,
        provenance: SafetyProvenance.localHeuristic,
        redactedPreview: '[redacted · wellbeing concern]',
      );
    }
    if (t.contains('[unknown:noise]')) {
      return const SafetyClassifyHit(
        category: SafetyCategory.uncategorizedConcern,
        certainty: SafetyCertainty.unknown,
        severity: SafetySeverity.low,
        provenance: SafetyProvenance.localHeuristic,
      );
    }
    return null;
  }
}
