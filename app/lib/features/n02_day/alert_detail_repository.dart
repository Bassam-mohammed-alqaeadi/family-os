import 'package:flutter/foundation.dart';

import 'package:family_os/features/n02_day/alerts_hub_repository.dart';

/// Wire kinds for SCR-FAT-020 (`?alertKind=` from FAT-019).
enum AlertDetailKind {
  stranger,
  battery,
  games,
  arrive;

  static AlertDetailKind? tryParse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'stranger':
        return AlertDetailKind.stranger;
      case 'battery':
        return AlertDetailKind.battery;
      case 'games':
        return AlertDetailKind.games;
      case 'arrive':
        return AlertDetailKind.arrive;
      default:
        return null;
    }
  }

  String get wire => name;
}

/// Suggested calm reply — content from repo (not planted in widgets).
@immutable
final class AlertToneReply {
  const AlertToneReply({
    required this.id,
    required this.text,
    required this.hint,
  });

  final String id;
  final String text;
  final String hint;
}

/// Full alert detail payload for SCR-FAT-020 (category + severity + advice).
///
/// Bark-style honesty: excerpt / category / severity — never raw message text.
@immutable
final class AlertDetail {
  const AlertDetail({
    required this.id,
    required this.kind,
    required this.childId,
    required this.urgency,
    required this.title,
    required this.body,
    this.advice,
    this.toneReplies = const [],
    this.primaryDone = false,
  });

  final String id;
  final AlertDetailKind kind;

  /// Parametric child id (G-5 / Rule 23) — never a planted display name.
  final String childId;
  final AlertUrgency urgency;
  final String title;
  final String body;

  /// Family-advisor recommendation (suggest-only).
  final String? advice;
  final List<AlertToneReply> toneReplies;

  /// Primary action completed (block / reminder / dismiss / heart).
  final bool primaryDone;

  AlertDetail copyWith({
    String? id,
    AlertDetailKind? kind,
    String? childId,
    AlertUrgency? urgency,
    String? title,
    String? body,
    String? advice,
    List<AlertToneReply>? toneReplies,
    bool? primaryDone,
  }) {
    return AlertDetail(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      childId: childId ?? this.childId,
      urgency: urgency ?? this.urgency,
      title: title ?? this.title,
      body: body ?? this.body,
      advice: advice ?? this.advice,
      toneReplies: toneReplies ?? this.toneReplies,
      primaryDone: primaryDone ?? this.primaryDone,
    );
  }
}

/// Rule 25 seam — alert detail for SCR-FAT-020 (no Firebase; Drift later).
abstract class AlertDetailRepository {
  /// Resolve by [alertId] and/or [alertKind]. Null → not found.
  Future<AlertDetail?> load({String? alertId, String? alertKind});

  /// Mark primary action done (block / reminder / dismiss / heart).
  Future<AlertDetail> markPrimaryDone(String alertId);
}

/// In-memory mock — empty until tests/repos seed (Rule 23).
final class InMemoryAlertDetailRepository implements AlertDetailRepository {
  InMemoryAlertDetailRepository({
    List<AlertDetail>? initial,
    this.failLoad = false,
  }) : _items = List<AlertDetail>.from(initial ?? const []);

  final List<AlertDetail> _items;

  /// Test seam — next [load] throws.
  bool failLoad;

  void seed(List<AlertDetail> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  Future<AlertDetail?> load({String? alertId, String? alertKind}) async {
    if (failLoad) {
      throw StateError('mock alert detail load failure');
    }
    final id = alertId?.trim();
    if (id != null && id.isNotEmpty) {
      for (final a in _items) {
        if (a.id == id) return a;
      }
      return null;
    }
    final kind = AlertDetailKind.tryParse(alertKind);
    if (kind != null) {
      for (final a in _items) {
        if (a.kind == kind) return a;
      }
    }
    return null;
  }

  @override
  Future<AlertDetail> markPrimaryDone(String alertId) async {
    final i = _items.indexWhere((a) => a.id == alertId);
    if (i < 0) {
      throw StateError('alert not found: $alertId');
    }
    final updated = _items[i].copyWith(primaryDone: true);
    _items[i] = updated;
    return updated;
  }
}

/// Stage-1 singleton — empty until tests/repos seed (Rule 23).
final stage1AlertDetailRepository = InMemoryAlertDetailRepository();
