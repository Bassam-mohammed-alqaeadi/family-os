import 'package:flutter/foundation.dart';

/// Opaque child identity for parametric screens (constitution rule 13 / G8).
///
/// Never hardcode child display names outside `mock/` — pass [ChildId].
@immutable
final class ChildId {
  /// Creates a [ChildId] from a non-empty stable string key.
  factory ChildId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'value', 'ChildId cannot be empty');
    }
    return ChildId._(trimmed);
  }

  const ChildId._(this.value);

  /// Stable opaque key (e.g. `k1`), not a display name.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChildId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ChildId($value)';
}
