import 'package:flutter/foundation.dart';

/// Canonical System #3 identity keys.
///
/// Local-first and backend-ready: values are opaque, stable identifiers.
@immutable
final class AccountId {
  factory AccountId(String value) => AccountId._(_normalize(value, 'AccountId'));
  const AccountId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AccountId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AccountId($value)';
}

@immutable
final class FamilyId {
  factory FamilyId(String value) => FamilyId._(_normalize(value, 'FamilyId'));
  const FamilyId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FamilyId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'FamilyId($value)';
}

@immutable
final class MemberId {
  factory MemberId(String value) => MemberId._(_normalize(value, 'MemberId'));
  const MemberId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MemberId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'MemberId($value)';
}

@immutable
final class DeviceId {
  factory DeviceId(String value) => DeviceId._(_normalize(value, 'DeviceId'));
  const DeviceId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeviceId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'DeviceId($value)';
}

@immutable
final class PairingTokenId {
  factory PairingTokenId(String value) =>
      PairingTokenId._(_normalize(value, 'PairingTokenId'));
  const PairingTokenId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PairingTokenId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'PairingTokenId($value)';
}

@immutable
final class EnrollmentId {
  factory EnrollmentId(String value) =>
      EnrollmentId._(_normalize(value, 'EnrollmentId'));
  const EnrollmentId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EnrollmentId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'EnrollmentId($value)';
}

@immutable
final class SessionId {
  factory SessionId(String value) => SessionId._(_normalize(value, 'SessionId'));
  const SessionId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SessionId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'SessionId($value)';
}

@immutable
final class InviteId {
  factory InviteId(String value) => InviteId._(_normalize(value, 'InviteId'));
  const InviteId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InviteId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'InviteId($value)';
}

@immutable
final class InviteTokenId {
  factory InviteTokenId(String value) =>
      InviteTokenId._(_normalize(value, 'InviteTokenId'));
  const InviteTokenId._(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InviteTokenId && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'InviteTokenId($value)';
}

String _normalize(String raw, String type) {
  final value = raw.trim();
  if (value.isEmpty) {
    throw ArgumentError.value(raw, type, '$type cannot be empty');
  }
  return value;
}
