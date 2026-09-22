import 'package:flutter/foundation.dart';

/// Allowed RulesEngine consequents (ADR-038(d) allow-list / SET-023).
///
/// Owner-only actions are **not** members of this enum — they live only as
/// forbidden wire ids in [ForbiddenRuleConsequentIds].
enum RuleConsequent {
  /// Notify father on feed / alert.
  notifyFather,

  /// Grant minutes within father-defined rule amounts (ADR-038 e).
  grantMinutes,

  /// Soft device / app pause (not anti-tamper; not unlock of father-blocked apps).
  softLock,
}

/// ADR-038(d) / ADR-035 owner-only consequents — never selectable or savable.
abstract final class ForbiddenRuleConsequentIds {
  static const antiTamper = 'ANTI_TAMPER';
  static const blockOverride = 'BLOCK_OVERRIDE';
  static const delegationEdit = 'DELEGATION_EDIT';

  static const Set<String> all = {
    antiTamper,
    blockOverride,
    delegationEdit,
  };
}

/// Wire id for an allow-listed [RuleConsequent] (stable API / AST token).
extension RuleConsequentWire on RuleConsequent {
  String get id => switch (this) {
        RuleConsequent.notifyFather => 'NOTIFY_FATHER',
        RuleConsequent.grantMinutes => 'GRANT_MINUTES',
        RuleConsequent.softLock => 'SOFT_LOCK',
      };
}

/// Thrown when a rule payload includes an ADR-038(d) forbidden consequent.
@immutable
final class ForbiddenRuleConsequentException implements Exception {
  const ForbiddenRuleConsequentException(this.consequentId);

  final String consequentId;

  @override
  String toString() =>
      'ForbiddenRuleConsequentException: consequent "$consequentId" is '
      'owner-only (ADR-038(d) / SET-023)';
}

/// True when [id] matches an explicit ADR-038(d) forbidden consequent.
bool isForbiddenRuleConsequentId(String id) {
  final normalized = id.trim().toUpperCase();
  return ForbiddenRuleConsequentIds.all.contains(normalized);
}

/// Parses an allow-listed consequent wire id, or `null` if unknown/forbidden.
RuleConsequent? tryParseRuleConsequentId(String id) {
  final normalized = id.trim().toUpperCase();
  for (final c in RuleConsequent.values) {
    if (c.id == normalized) return c;
  }
  return null;
}

/// Validates raw consequent ids — throws [ForbiddenRuleConsequentException]
/// on any ADR-038(d) owner-only id. Unknown non-forbidden ids are rejected
/// as [ArgumentError] (allow-list only).
void validateRuleConsequentIds(Iterable<String> consequentIds) {
  for (final raw in consequentIds) {
    final id = raw.trim();
    if (id.isEmpty) continue;
    if (isForbiddenRuleConsequentId(id)) {
      throw ForbiddenRuleConsequentException(id.toUpperCase());
    }
    if (tryParseRuleConsequentId(id) == null) {
      throw ArgumentError.value(
        id,
        'consequentIds',
        'not in RuleConsequent allow-list',
      );
    }
  }
}

/// Maps validated wire ids to [RuleConsequent] (call [validateRuleConsequentIds] first).
List<RuleConsequent> parseRuleConsequentIds(Iterable<String> consequentIds) {
  validateRuleConsequentIds(consequentIds);
  return [
    for (final raw in consequentIds)
      if (raw.trim().isNotEmpty) tryParseRuleConsequentId(raw)!,
  ];
}
