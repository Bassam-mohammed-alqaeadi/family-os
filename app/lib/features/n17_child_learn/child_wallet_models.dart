import 'package:flutter/foundation.dart';

@immutable
final class ChildWalletApp {
  const ChildWalletApp({
    required this.id,
    required this.nameKey,
    required this.iconKey,
    required this.walletMinutes,
  });

  final String id;
  final String nameKey;
  final String iconKey;

  /// Minutes-only balance for this app wallet (ع-١).
  final int walletMinutes;
}

@immutable
final class ChildWalletBadge {
  const ChildWalletBadge({
    required this.id,
    required this.labelKey,
    required this.earned,
  });

  final String id;
  final String labelKey;
  final bool earned;
}

@immutable
final class ChildWalletSnapshot {
  const ChildWalletSnapshot({
    this.totalMinutes = 0,
    this.streakDays = 0,
    this.recordStreakDays = 0,
    this.apps = const [],
    this.badges = const [],
    this.simulated = true,
  });

  final int totalMinutes;
  final int streakDays;
  final int recordStreakDays;
  final List<ChildWalletApp> apps;
  final List<ChildWalletBadge> badges;

  /// Stage-1 honesty — balances come from mock/policy prefs, not a live device.
  final bool simulated;

  bool get isEmpty => apps.isEmpty && badges.isEmpty && totalMinutes == 0;

  int get earnedBadgeCount => badges.where((b) => b.earned).length;
}
