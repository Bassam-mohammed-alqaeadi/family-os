import 'package:flutter/foundation.dart';

/// Platform-stable package / application identifier (APP identity · APP-OD-08).
///
/// Policy key is the normalized string — Stage-1 marketing slugs may appear as
/// provisional ids until T-APP-01 device inventory; they are still treated as
/// opaque package keys, never as display labels for authorship.
@immutable
final class PackageId {
  factory PackageId(String raw) {
    final n = normalize(raw);
    if (n.isEmpty) {
      throw ArgumentError('PackageId must be non-empty');
    }
    return PackageId._(n);
  }

  const PackageId._(this.value);

  final String value;

  static String normalize(String raw) => raw.trim().toLowerCase();

  @override
  bool operator ==(Object other) => other is PackageId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PackageId($value)';
}
