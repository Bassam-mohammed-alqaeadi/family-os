// The contracts the polished guardian surface speaks, stated before the server does.
//
// Two controls in the screen-time panel have no route yet: a per-category daily budget, and a
// bedtime window for the weekend that differs from Monday to Thursday. The rule this wave
// follows is the one in `AGENTS.md` §3 — the gap is closed by declaring the contract, not by
// shrinking the surface. So the panel draws both controls, and each one says plainly whether
// what it just did reached the family's server or is waiting on it.
//
// What the backend has to add, in one paragraph: on
// `PATCH /v1/families/{familyId}/children/{childId}/screen-time`, accept two more optional
// fields — `bedtimeWeekend: {startMinute, endMinute}` and `dailyMinutesByCategory:
// [{category, minutes}]` — store both on the policy row the same way `bedtime` and `schoolMode`
// are stored today, bump `version`, and return the whole policy in the same envelope. Then bind
// [ScreenTimePolicyExtensionSource] to an http-backed implementation, and every screen that
// already renders these fields stops saying "waiting".
//
// Nothing in this file invents an answer. An unbound source is `notConfigured`, and a screen
// that shows `notConfigured` as "saved" is exactly the bug this wave exists to remove.
import 'package:flutter/foundation.dart';

/// Which half of the week a bedtime window belongs to.
enum ScreenTimeWeekPart {
  weekdays('weekdays'),
  weekend('weekend');

  const ScreenTimeWeekPart(this.wire);

  final String wire;

  static ScreenTimeWeekPart? parse(Object? value) {
    for (final part in values) {
      if (part.wire == value) return part;
    }
    return null;
  }
}

/// The categories the guardian's app panel groups apps under.
///
/// The server sends a free-text `category` per app; this enum is only how a family reads it
/// back. Anything the app reported that is not one of these five lands in [other], which is
/// why `other` has no wire value of its own — it is a bucket, not a claim.
enum ScreenTimeAppCategory {
  games('games'),
  social('social'),
  video('video'),
  education('education'),
  other('other');

  const ScreenTimeAppCategory(this.wire);

  final String wire;

  static ScreenTimeAppCategory fromWire(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    return switch (value) {
      'games' || 'game' => ScreenTimeAppCategory.games,
      'social' || 'messaging' || 'chat' => ScreenTimeAppCategory.social,
      'video' || 'youtube' || 'streaming' || 'media' => ScreenTimeAppCategory.video,
      'edu' || 'education' || 'learning' || 'school' =>
        ScreenTimeAppCategory.education,
      _ => ScreenTimeAppCategory.other,
    };
  }
}

/// One bedtime window, in minutes of the family's own day.
///
/// Minutes-of-day rather than a `DateTime` because a bedtime is a clock reading, not a moment:
/// a window that carried a timezone would move when the family travelled, and a child's bedtime
/// is the one thing in this app that must not move.
@immutable
final class ScreenTimeBedtimeWindow {
  const ScreenTimeBedtimeWindow({
    required this.weekPart,
    required this.startMinute,
    required this.endMinute,
  });

  factory ScreenTimeBedtimeWindow.fromJson(
    Map<String, Object?> json,
    ScreenTimeWeekPart weekPart,
  ) => ScreenTimeBedtimeWindow(
    weekPart: weekPart,
    startMinute: _minute(json['startMinute']),
    endMinute: _minute(json['endMinute']),
  );

  final ScreenTimeWeekPart weekPart;
  final int startMinute;
  final int endMinute;

  /// `21:30 – 06:00`, in the family's clock.
  String get startClock => _clock(startMinute);
  String get endClock => _clock(endMinute);

  Map<String, Object?> toJson() => <String, Object?>{
    'startMinute': startMinute,
    'endMinute': endMinute,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenTimeBedtimeWindow &&
          other.weekPart == weekPart &&
          other.startMinute == startMinute &&
          other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(weekPart, startMinute, endMinute);
}

/// A guardian's daily budget for one app category.
@immutable
final class ScreenTimeCategoryBudget {
  const ScreenTimeCategoryBudget({
    required this.category,
    required this.minutes,
    required this.enabled,
  });

  factory ScreenTimeCategoryBudget.fromJson(Map<String, Object?> json) {
    final rawCategory = json['category'];
    return ScreenTimeCategoryBudget(
      category: ScreenTimeAppCategory.fromWire(
        rawCategory is String ? rawCategory : null,
      ),
      minutes: _minute(json['minutes']),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final ScreenTimeAppCategory category;

  /// 0 means "no minutes in this category today", which is a block and is drawn as one.
  final int minutes;
  final bool enabled;

  Map<String, Object?> toJson() => <String, Object?>{
    'category': category.wire,
    'minutes': minutes,
    'enabled': enabled,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenTimeCategoryBudget &&
          other.category == category &&
          other.minutes == minutes &&
          other.enabled == enabled;

  @override
  int get hashCode => Object.hash(category, minutes, enabled);
}

/// The extension fields the panel can read and write once the server carries them.
@immutable
final class ScreenTimePolicyExtension {
  const ScreenTimePolicyExtension({
    this.bedtimeWindows = const {},
    this.categoryBudgets = const {},
  });

  final Map<ScreenTimeWeekPart, ScreenTimeBedtimeWindow> bedtimeWindows;
  final Map<ScreenTimeAppCategory, ScreenTimeCategoryBudget> categoryBudgets;

  bool get isEmpty => bedtimeWindows.isEmpty && categoryBudgets.isEmpty;

  static const ScreenTimePolicyExtension none = ScreenTimePolicyExtension();

  factory ScreenTimePolicyExtension.fromJson(Map<String, Object?> json) {
    final windows = <ScreenTimeWeekPart, ScreenTimeBedtimeWindow>{};
    final rawWindows = json['bedtimeWindows'];
    if (rawWindows is List) {
      for (final entry in rawWindows) {
        if (entry is! Map) continue;
        final map = entry.cast<String, Object?>();
        final part = ScreenTimeWeekPart.parse(map['weekPart']);
        if (part == null) continue;
        windows[part] = ScreenTimeBedtimeWindow.fromJson(map, part);
      }
    }
    final budgets = <ScreenTimeAppCategory, ScreenTimeCategoryBudget>{};
    final rawBudgets = json['dailyMinutesByCategory'];
    if (rawBudgets is List) {
      for (final entry in rawBudgets) {
        if (entry is! Map) continue;
        final budget = ScreenTimeCategoryBudget.fromJson(
          entry.cast<String, Object?>(),
        );
        budgets[budget.category] = budget;
      }
    }
    return ScreenTimePolicyExtension(
      bedtimeWindows: windows,
      categoryBudgets: budgets,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    if (bedtimeWindows.isNotEmpty)
      'bedtimeWindows': <Object?>[
        for (final entry in bedtimeWindows.entries)
          <String, Object?>{
            'weekPart': entry.key.wire,
            ...entry.value.toJson(),
          },
      ],
    if (categoryBudgets.isNotEmpty)
      'dailyMinutesByCategory': <Object?>[
        for (final budget in categoryBudgets.values) budget.toJson(),
      ],
  };
}

/// Why the extension surface answered the way it did — the same five the rest of this system
/// settled on, so a screen never has to learn a sixth vocabulary per feature.
enum ScreenTimeExtensionStatus {
  ready,
  notConfigured,
  accessDenied,
  unreachable,
  refused,
}

/// One answer about the extension fields.
class ScreenTimeExtensionAnswer {
  const ScreenTimeExtensionAnswer._({required this.status, required this.value});

  const ScreenTimeExtensionAnswer.ready(ScreenTimePolicyExtension value)
    : this._(
        status: ScreenTimeExtensionStatus.ready,
        value: value,
      );

  const ScreenTimeExtensionAnswer.unavailable(
    ScreenTimeExtensionStatus status,
  ) : this._(status: status, value: null);

  final ScreenTimeExtensionStatus status;
  final ScreenTimePolicyExtension? value;

  bool get isReady =>
      status == ScreenTimeExtensionStatus.ready && value != null;
}

/// The seam the panel reads and writes the not-yet-built fields through.
///
/// Deliberately narrow: one read, one write, no caching and no local fallback. A screen that
/// kept an unsaved weekend bedtime "visible as saved" would be the first lie in a panel whose
/// whole claim is that what it shows is what the phone obeys.
abstract interface class ScreenTimePolicyExtensionSource {
  Future<ScreenTimeExtensionAnswer> read(String childId);

  Future<ScreenTimeExtensionAnswer> write(
    String childId, {
    required ScreenTimePolicyExtension policyExtension,
    required String Function() idempotencyKey,
  });
}

/// The source a build has when no extension route is bound yet: it answers honestly and does
/// nothing else.
final class UnconfiguredScreenTimePolicyExtensionSource
    implements ScreenTimePolicyExtensionSource {
  const UnconfiguredScreenTimePolicyExtensionSource();

  @override
  Future<ScreenTimeExtensionAnswer> read(String childId) async =>
      const ScreenTimeExtensionAnswer.unavailable(
        ScreenTimeExtensionStatus.notConfigured,
      );

  @override
  Future<ScreenTimeExtensionAnswer> write(
    String childId, {
    required ScreenTimePolicyExtension policyExtension,
    required String Function() idempotencyKey,
  }) async => const ScreenTimeExtensionAnswer.unavailable(
    ScreenTimeExtensionStatus.notConfigured,
  );
}

ScreenTimePolicyExtensionSource? _activeExtensionSource;

/// Binds the extension source, or clears it back to the honest unconfigured answer.
void bindScreenTimePolicyExtension(ScreenTimePolicyExtensionSource? source) {
  _activeExtensionSource = source;
}

/// The bound source, defaulting to the one that says "nobody built this route yet".
ScreenTimePolicyExtensionSource get screenTimePolicyExtensionSource =>
    _activeExtensionSource ??
    const UnconfiguredScreenTimePolicyExtensionSource();

int _minute(Object? raw) => raw is int && raw >= 0 ? raw : 0;

String _clock(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
