import '../domain/role.dart';

/// Permission key `ANTI_TAMPER` (ADR-035 / ADR-035-b / SET-007).
///
/// Father OWNER only. Mother FULL / PARTNER / OBSERVER → false.
/// Split from `can('rules')` — rules edit must never imply anti-tamper.
bool canConfigureAntiTamper(AppRole role) => role == AppRole.father;
