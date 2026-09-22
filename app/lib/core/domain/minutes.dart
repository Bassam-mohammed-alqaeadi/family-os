import 'package:flutter/foundation.dart';

/// Immutable non-negative minute currency (Policy Register E-1 / ADR-031).
///
/// Raw reward/balance ints must not appear in public APIs — use [Minutes].
@immutable
final class Minutes implements Comparable<Minutes> {
  /// Creates a [Minutes] value. Throws [ArgumentError] if [value] is negative.
  factory Minutes(int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Minutes cannot be negative');
    }
    return Minutes._(value);
  }

  const Minutes._(this._value);

  /// Zero minutes.
  static const Minutes zero = Minutes._(0);

  final int _value;

  /// Non-negative internal count (read-only; not a "reward API").
  int get inMinutes => _value;

  bool get isZero => _value == 0;

  Minutes operator +(Minutes other) => Minutes(_value + other._value);

  /// Subtracts [other]. Throws if the result would be negative.
  Minutes operator -(Minutes other) {
    final result = _value - other._value;
    if (result < 0) {
      throw ArgumentError(
        'Minutes subtraction underflow: $_value - ${other._value}',
      );
    }
    return Minutes(result);
  }

  bool operator <(Minutes other) => _value < other._value;
  bool operator <=(Minutes other) => _value <= other._value;
  bool operator >(Minutes other) => _value > other._value;
  bool operator >=(Minutes other) => _value >= other._value;

  @override
  int compareTo(Minutes other) => _value.compareTo(other._value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Minutes && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Minutes($_value)';
}
