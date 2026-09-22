import 'package:flutter/foundation.dart';

/// Flag keys for AT `anti_tamper_policy` (SET-007 / SET-008 / P-6).
abstract final class AntiTamperFlags {
  static const noDelete = 'noDelete';
  static const noClockChange = 'noClockChange';
  static const noVpn = 'noVpn';
  static const simAlert = 'simAlert';
  static const settingsPin = 'settingsPin';
  static const bypassAlert = 'bypassAlert';

  static const List<String> known = [
    noDelete,
    noClockChange,
    noVpn,
    simAlert,
    settingsPin,
    bypassAlert,
  ];
}

/// Child-device anti-tamper defenses (ADR-035 / ADR-035-b / SET-007).
///
/// Written only under father session. Mother UI must omit these flags entirely.
@immutable
final class AntiTamperPolicy {
  const AntiTamperPolicy({
    this.noDelete = false,
    this.noClockChange = false,
    this.noVpn = false,
    this.simAlert = false,
    this.settingsPin = false,
    this.bypassAlert = false,
    this.policyVersion = 1,
    this.updatedAt,
  });

  /// Stage-1 default: all defenses off until father enables.
  static AntiTamperPolicy defaults() => const AntiTamperPolicy();

  final bool noDelete;
  final bool noClockChange;
  final bool noVpn;
  final bool simAlert;
  final bool settingsPin;
  final bool bypassAlert;
  final int policyVersion;
  final DateTime? updatedAt;

  bool flag(String key) => switch (key) {
        AntiTamperFlags.noDelete => noDelete,
        AntiTamperFlags.noClockChange => noClockChange,
        AntiTamperFlags.noVpn => noVpn,
        AntiTamperFlags.simAlert => simAlert,
        AntiTamperFlags.settingsPin => settingsPin,
        AntiTamperFlags.bypassAlert => bypassAlert,
        _ => false,
      };

  AntiTamperPolicy copyWith({
    bool? noDelete,
    bool? noClockChange,
    bool? noVpn,
    bool? simAlert,
    bool? settingsPin,
    bool? bypassAlert,
    int? policyVersion,
    DateTime? updatedAt,
  }) {
    return AntiTamperPolicy(
      noDelete: noDelete ?? this.noDelete,
      noClockChange: noClockChange ?? this.noClockChange,
      noVpn: noVpn ?? this.noVpn,
      simAlert: simAlert ?? this.simAlert,
      settingsPin: settingsPin ?? this.settingsPin,
      bypassAlert: bypassAlert ?? this.bypassAlert,
      policyVersion: policyVersion ?? this.policyVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AntiTamperPolicy withFlag(String key, bool enabled) {
    return switch (key) {
      AntiTamperFlags.noDelete => copyWith(noDelete: enabled),
      AntiTamperFlags.noClockChange => copyWith(noClockChange: enabled),
      AntiTamperFlags.noVpn => copyWith(noVpn: enabled),
      AntiTamperFlags.simAlert => copyWith(simAlert: enabled),
      AntiTamperFlags.settingsPin => copyWith(settingsPin: enabled),
      AntiTamperFlags.bypassAlert => copyWith(bypassAlert: enabled),
      _ => this,
    };
  }

  Map<String, dynamic> toJson() => {
        'noDelete': noDelete,
        'noClockChange': noClockChange,
        'noVpn': noVpn,
        'simAlert': simAlert,
        'settingsPin': settingsPin,
        'bypassAlert': bypassAlert,
        'policyVersion': policyVersion,
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };

  factory AntiTamperPolicy.fromJson(Map<String, dynamic> json) {
    return AntiTamperPolicy(
      noDelete: json['noDelete'] == true,
      noClockChange: json['noClockChange'] == true,
      noVpn: json['noVpn'] == true,
      simAlert: json['simAlert'] == true,
      settingsPin: json['settingsPin'] == true,
      bypassAlert: json['bypassAlert'] == true,
      policyVersion: (json['policyVersion'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AntiTamperPolicy &&
        other.noDelete == noDelete &&
        other.noClockChange == noClockChange &&
        other.noVpn == noVpn &&
        other.simAlert == simAlert &&
        other.settingsPin == settingsPin &&
        other.bypassAlert == bypassAlert &&
        other.policyVersion == policyVersion;
  }

  @override
  int get hashCode => Object.hash(
        noDelete,
        noClockChange,
        noVpn,
        simAlert,
        settingsPin,
        bypassAlert,
        policyVersion,
      );
}
