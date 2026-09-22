import 'package:flutter/foundation.dart';

import '../domain/minutes.dart';

/// Education / non-countable app ids (S-1 invariant).
///
/// `quran` and any `edu_*` id cannot be marked [AppWallet.countable] = true.
abstract final class EducationAppIds {
  static bool isEducation(String appId) {
    final id = appId.trim().toLowerCase();
    return id == 'quran' || id.startsWith('edu_');
  }
}

/// Per-app earned wallet (D-2 / S-2).
@immutable
final class AppWallet {
  factory AppWallet({
    required String appId,
    required Minutes earnedMinutes,
    bool countable = true,
  }) {
    final id = appId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(appId, 'appId', 'appId cannot be empty');
    }
    if (earnedMinutes.inMinutes < 0) {
      throw ArgumentError.value(
        earnedMinutes,
        'earnedMinutes',
        'earnedMinutes cannot be negative',
      );
    }
    // S-1: education apps are never countable.
    final effectiveCountable =
        EducationAppIds.isEducation(id) ? false : countable;
    return AppWallet._(
      appId: id,
      earnedMinutes: earnedMinutes,
      countable: effectiveCountable,
    );
  }

  const AppWallet._({
    required this.appId,
    required this.earnedMinutes,
    required this.countable,
  });

  final String appId;
  final Minutes earnedMinutes;

  /// When false, usage does not consume the daily entertainment cap (S-1).
  final bool countable;

  AppWallet copyWith({
    Minutes? earnedMinutes,
    bool? countable,
  }) {
    return AppWallet(
      appId: appId,
      earnedMinutes: earnedMinutes ?? this.earnedMinutes,
      countable: countable ?? this.countable,
    );
  }

  Map<String, Object?> toJson() => {
        'appId': appId,
        'earnedMinutes': earnedMinutes.inMinutes,
        'countable': countable,
      };

  factory AppWallet.fromJson(Map<String, Object?> json) {
    final rawEarned = json['earnedMinutes'];
    final earned = switch (rawEarned) {
      int v => Minutes(v < 0 ? 0 : v),
      _ => Minutes.zero,
    };
    return AppWallet(
      appId: json['appId'] as String? ?? 'unknown',
      earnedMinutes: earned,
      countable: json['countable'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppWallet &&
          appId == other.appId &&
          earnedMinutes == other.earnedMinutes &&
          countable == other.countable;

  @override
  int get hashCode => Object.hash(appId, earnedMinutes, countable);
}

/// Child-level daily cap + wallets (D-1 / SET-002).
@immutable
final class ScreenTimePolicy {
  factory ScreenTimePolicy({
    int dailyCapMinutes = 120,
    bool allowWalletOverflow = false,
    int usedMinutesToday = 0,
    List<AppWallet> wallets = const [],
  }) {
    if (dailyCapMinutes < 0) {
      throw ArgumentError.value(
        dailyCapMinutes,
        'dailyCapMinutes',
        'dailyCapMinutes cannot be negative',
      );
    }
    if (usedMinutesToday < 0) {
      throw ArgumentError.value(
        usedMinutesToday,
        'usedMinutesToday',
        'usedMinutesToday cannot be negative',
      );
    }
    return ScreenTimePolicy._(
      dailyCapMinutes: dailyCapMinutes,
      allowWalletOverflow: allowWalletOverflow,
      usedMinutesToday: usedMinutesToday,
      wallets: List<AppWallet>.unmodifiable(wallets),
    );
  }

  const ScreenTimePolicy._({
    required this.dailyCapMinutes,
    required this.allowWalletOverflow,
    required this.usedMinutesToday,
    required this.wallets,
  });

  /// Default Stage-1 policy (Ruling B: overflow off).
  static ScreenTimePolicy defaults() => ScreenTimePolicy(
        wallets: [
          AppWallet(appId: 'games', earnedMinutes: Minutes.zero),
          AppWallet(appId: 'youtube', earnedMinutes: Minutes.zero),
          AppWallet(appId: 'quran', earnedMinutes: Minutes.zero),
        ],
      );

  /// Non-negative daily entertainment cap in minutes.
  final int dailyCapMinutes;

  /// Ruling B / SET-024 default: false — wallet does not open past cap.
  final bool allowWalletOverflow;

  /// Mock daily usage (SET-002 Stage-1; real metering later).
  final int usedMinutesToday;

  final List<AppWallet> wallets;

  /// True when usage has reached/exceeded the daily cap.
  bool get isCapExhausted => usedMinutesToday >= dailyCapMinutes;

  AppWallet? walletFor(String appId) {
    final id = appId.trim();
    for (final w in wallets) {
      if (w.appId == id) return w;
    }
    return null;
  }

  ScreenTimePolicy copyWith({
    int? dailyCapMinutes,
    bool? allowWalletOverflow,
    int? usedMinutesToday,
    List<AppWallet>? wallets,
  }) {
    return ScreenTimePolicy(
      dailyCapMinutes: dailyCapMinutes ?? this.dailyCapMinutes,
      allowWalletOverflow: allowWalletOverflow ?? this.allowWalletOverflow,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      wallets: wallets ?? this.wallets,
    );
  }

  /// Replaces or inserts [wallet] by appId (S-1 enforced in [AppWallet]).
  ScreenTimePolicy upsertWallet(AppWallet wallet) {
    final next = <AppWallet>[];
    var found = false;
    for (final w in wallets) {
      if (w.appId == wallet.appId) {
        next.add(wallet);
        found = true;
      } else {
        next.add(w);
      }
    }
    if (!found) next.add(wallet);
    return copyWith(wallets: next);
  }

  Map<String, Object?> toJson() => {
        'dailyCapMinutes': dailyCapMinutes,
        'allowWalletOverflow': allowWalletOverflow,
        'usedMinutesToday': usedMinutesToday,
        'wallets': wallets.map((w) => w.toJson()).toList(),
      };

  factory ScreenTimePolicy.fromJson(Map<String, Object?> json) {
    final rawWallets = json['wallets'];
    final wallets = <AppWallet>[];
    if (rawWallets is List) {
      for (final item in rawWallets) {
        if (item is! Map) continue;
        wallets.add(
          AppWallet.fromJson(item.map((k, v) => MapEntry(k.toString(), v))),
        );
      }
    }
    final cap = json['dailyCapMinutes'];
    final used = json['usedMinutesToday'];
    return ScreenTimePolicy(
      dailyCapMinutes: cap is int && cap >= 0 ? cap : 120,
      allowWalletOverflow: json['allowWalletOverflow'] as bool? ?? false,
      usedMinutesToday: used is int && used >= 0 ? used : 0,
      wallets: wallets.isEmpty ? ScreenTimePolicy.defaults().wallets : wallets,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenTimePolicy &&
          dailyCapMinutes == other.dailyCapMinutes &&
          allowWalletOverflow == other.allowWalletOverflow &&
          usedMinutesToday == other.usedMinutesToday &&
          listEquals(wallets, other.wallets);

  @override
  int get hashCode => Object.hash(
        dailyCapMinutes,
        allowWalletOverflow,
        usedMinutesToday,
        Object.hashAll(wallets),
      );
}
