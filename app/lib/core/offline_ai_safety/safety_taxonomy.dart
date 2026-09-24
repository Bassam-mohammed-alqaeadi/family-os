import 'package:flutter/foundation.dart';

/// AI-OD-07 closed v1 harmful-content categories.
enum SafetyCategory {
  sexualContent,
  sensitiveVisual,
  violenceOrThreat,
  selfHarmSignal,
  predatoryOrGroomingSignal,
  substanceOrGambling,
  suspiciousLanguage,
  uncategorizedConcern,
}

extension SafetyCategoryWire on SafetyCategory {
  String get wireName => switch (this) {
        SafetyCategory.sexualContent => 'sexual_content',
        SafetyCategory.sensitiveVisual => 'sensitive_visual',
        SafetyCategory.violenceOrThreat => 'violence_or_threat',
        SafetyCategory.selfHarmSignal => 'self_harm_signal',
        SafetyCategory.predatoryOrGroomingSignal =>
          'predatory_or_grooming_signal',
        SafetyCategory.substanceOrGambling => 'substance_or_gambling',
        SafetyCategory.suspiciousLanguage => 'suspicious_language',
        SafetyCategory.uncategorizedConcern => 'uncategorized_concern',
      };

  static SafetyCategory parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'sexual_content':
        return SafetyCategory.sexualContent;
      case 'sensitive_visual':
        return SafetyCategory.sensitiveVisual;
      case 'violence_or_threat':
        return SafetyCategory.violenceOrThreat;
      case 'self_harm_signal':
        return SafetyCategory.selfHarmSignal;
      case 'predatory_or_grooming_signal':
        return SafetyCategory.predatoryOrGroomingSignal;
      case 'substance_or_gambling':
        return SafetyCategory.substanceOrGambling;
      case 'suspicious_language':
        return SafetyCategory.suspiciousLanguage;
      case 'uncategorized_concern':
        return SafetyCategory.uncategorizedConcern;
      default:
        throw FormatException('Unknown SafetyCategory: $raw');
    }
  }
}

/// AI-OD-08 certainty (ticket gate uses these — no numeric %).
enum SafetyCertainty {
  unknown,
  preliminary,
  analysis,
  confirmed,
}

extension SafetyCertaintyWire on SafetyCertainty {
  String get wireName => name;

  static SafetyCertainty parse(String raw) =>
      SafetyCertainty.values.byName(raw.trim().toLowerCase());
}

/// AI-OD-08 severity — product labels only (non-numeric).
enum SafetySeverity { low, elevated, high }

extension SafetySeverityWire on SafetySeverity {
  String get wireName => name;

  static SafetySeverity parse(String raw) =>
      SafetySeverity.values.byName(raw.trim().toLowerCase());
}

/// Provenance of a local classification (AI-OD-01 / L3 §4).
enum SafetyProvenance { localMl, localHeuristic, localOcrMl }

extension SafetyProvenanceWire on SafetyProvenance {
  String get wireName => switch (this) {
        SafetyProvenance.localMl => 'local_ml',
        SafetyProvenance.localHeuristic => 'local_heuristic',
        SafetyProvenance.localOcrMl => 'local_ocr+ml',
      };

  static SafetyProvenance parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'local_ml':
        return SafetyProvenance.localMl;
      case 'local_heuristic':
        return SafetyProvenance.localHeuristic;
      case 'local_ocr+ml':
      case 'local_ocr_ml':
        return SafetyProvenance.localOcrMl;
      default:
        throw FormatException('Unknown SafetyProvenance: $raw');
    }
  }
}

/// Input tool plane for child transparency (AI-OD-06).
enum SafetyToolKind { searchAnalysis, imageClassification, screenshotMonitoring }

/// Ticket gate B1 — open only for analysis|confirmed (AI-OD-03-GATE).
abstract final class SafetyTicketGate {
  static bool shouldOpenTicket(SafetyCertainty certainty) =>
      certainty == SafetyCertainty.analysis ||
      certainty == SafetyCertainty.confirmed;

  /// Notify always on completed classification (including preliminary/unknown).
  static bool shouldNotify(SafetyCertainty certainty) => true;
}

/// Forbidden FS-007 actions (AI-SF-04…11 / AI-OD-09).
@immutable
abstract final class SafetyAiForbiddenActions {
  static const bool mayFireSos = false;
  static const bool mayEscalateSos = false;
  static const bool maySilentMutateWebLists = false;
  static const bool maySilentMutatePackages = false;
  static const bool maySilentMutateModes = false;
  static const bool mayPermanentPolicyFromClassifyAlone = false;
  static const bool cloudClassifyInV1 = false;

  static void assertNoSos() {
    assert(!mayFireSos && !mayEscalateSos);
  }

  static void assertNoSilentPolicyMutation() {
    assert(
      !maySilentMutateWebLists &&
          !maySilentMutatePackages &&
          !maySilentMutateModes &&
          !mayPermanentPolicyFromClassifyAlone,
    );
  }
}
