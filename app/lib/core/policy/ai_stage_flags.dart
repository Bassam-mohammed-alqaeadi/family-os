import 'package:flutter/foundation.dart';

import 'ai_stage_id.dart';

/// Snapshot of server AI stage feature flags (SET-014).
@immutable
final class AiStageFlags {
  const AiStageFlags(this._enabled);

  /// All stages off — honest coming-soon UI when cache/server unknown.
  factory AiStageFlags.allOff() => AiStageFlags({
        for (final id in AiStageId.values) id: false,
      });

  factory AiStageFlags.fromMap(Map<AiStageId, bool> map) => AiStageFlags({
        for (final id in AiStageId.values) id: map[id] ?? false,
      });

  final Map<AiStageId, bool> _enabled;

  bool isEnabled(AiStageId id) => _enabled[id] ?? false;

  Map<AiStageId, bool> get asMap => Map.unmodifiable(_enabled);

  AiStageFlags copyWithEnabled(AiStageId id, bool enabled) => AiStageFlags({
        ..._enabled,
        id: enabled,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiStageFlags && mapEquals(other._enabled, _enabled);

  @override
  int get hashCode => Object.hashAll(
        AiStageId.values.map((id) => Object.hash(id, _enabled[id])),
      );
}
