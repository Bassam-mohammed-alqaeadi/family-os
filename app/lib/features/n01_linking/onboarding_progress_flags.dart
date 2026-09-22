import 'package:flutter/foundation.dart';

/// Non-blocking onboarding checklist flags for SCR-FAT-002 (UI-002).
///
/// Completeness is **suggestion progress only** — never a hard gate
/// (prototype 21 / doc 20 invite principle / G-3).
@immutable
class OnboardingProgressFlags {
  const OnboardingProgressFlags({
    required this.accountCreated,
    required this.childLinked,
    required this.motherInvited,
    required this.sosConfigured,
  });

  /// After SCR-FAT-001 success — only row treated as already done by default.
  final bool accountCreated;

  /// Optional suggestion — add/link first child.
  final bool childLinked;

  /// Optional suggestion — mother invite (doc 20: اقتراح لا إجبار).
  final bool motherInvited;

  /// Optional suggestion — emergency contacts.
  final bool sosConfigured;

  /// Post-create family default: account done, all optional rows open.
  factory OnboardingProgressFlags.afterFamilyCreate() =>
      const OnboardingProgressFlags(
        accountCreated: true,
        childLinked: false,
        motherInvited: false,
        sosConfigured: false,
      );

  /// Fresh install / empty cache — still never blocks Skip.
  factory OnboardingProgressFlags.empty() => const OnboardingProgressFlags(
        accountCreated: false,
        childLinked: false,
        motherInvited: false,
        sosConfigured: false,
      );

  static const int totalSteps = 4;

  int get completedCount =>
      (accountCreated ? 1 : 0) +
      (childLinked ? 1 : 0) +
      (motherInvited ? 1 : 0) +
      (sosConfigured ? 1 : 0);

  /// 0.0–1.0 for ProgressBar; derived from flags (not a frozen const).
  double get progressFraction => completedCount / totalSteps;

  int get progressPercent => (progressFraction * 100).round();

  /// True when every **optional** suggestion row is still open.
  bool get noOptionalRowsDone =>
      !childLinked && !motherInvited && !sosConfigured;

  OnboardingProgressFlags copyWith({
    bool? accountCreated,
    bool? childLinked,
    bool? motherInvited,
    bool? sosConfigured,
  }) {
    return OnboardingProgressFlags(
      accountCreated: accountCreated ?? this.accountCreated,
      childLinked: childLinked ?? this.childLinked,
      motherInvited: motherInvited ?? this.motherInvited,
      sosConfigured: sosConfigured ?? this.sosConfigured,
    );
  }

  Map<String, Object?> toJson() => {
        'accountCreated': accountCreated,
        'childLinked': childLinked,
        'motherInvited': motherInvited,
        'sosConfigured': sosConfigured,
      };

  factory OnboardingProgressFlags.fromJson(Map<String, Object?> json) {
    bool read(String key) {
      final v = json[key];
      return v == true;
    }

    return OnboardingProgressFlags(
      accountCreated: read('accountCreated'),
      childLinked: read('childLinked'),
      motherInvited: read('motherInvited'),
      sosConfigured: read('sosConfigured'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OnboardingProgressFlags &&
        other.accountCreated == accountCreated &&
        other.childLinked == childLinked &&
        other.motherInvited == motherInvited &&
        other.sosConfigured == sosConfigured;
  }

  @override
  int get hashCode => Object.hash(
        accountCreated,
        childLinked,
        motherInvited,
        sosConfigured,
      );
}
