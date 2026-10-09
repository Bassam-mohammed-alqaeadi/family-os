/// Local SOS settings seam (OD-15 Panic Quiet + per-child escalation desk).
///
/// UI-complete now · Backend/Native wire later — zero screen redo (Rule 25).
library;

import 'package:flutter/foundation.dart';

/// Per-child outside-escalation preferences (FAT-028 father desk).
@immutable
final class ChildSosEscalationPrefs {
  const ChildSosEscalationPrefs({
    this.enabled = false,
    this.delaySeconds = 60,
    this.notifyTrustedBackups = true,
    this.prepareSmsFallback = true,
  });

  /// When true, if parents do not answer this child's SOS, use trusted backups.
  final bool enabled;

  /// Seconds with no parent response before escalating to backups.
  final int delaySeconds;

  /// Use verified/enabled family ladder backups for this child.
  final bool notifyTrustedBackups;

  /// Father intends SMS to backup phones when Native/Backend SMS is wired.
  /// Local Stage-1: preference only — no live SMS send.
  final bool prepareSmsFallback;

  ChildSosEscalationPrefs copyWith({
    bool? enabled,
    int? delaySeconds,
    bool? notifyTrustedBackups,
    bool? prepareSmsFallback,
  }) => ChildSosEscalationPrefs(
    enabled: enabled ?? this.enabled,
    delaySeconds: delaySeconds ?? this.delaySeconds,
    notifyTrustedBackups: notifyTrustedBackups ?? this.notifyTrustedBackups,
    prepareSmsFallback: prepareSmsFallback ?? this.prepareSmsFallback,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'delaySeconds': delaySeconds,
    'notifyTrustedBackups': notifyTrustedBackups,
    'prepareSmsFallback': prepareSmsFallback,
  };

  factory ChildSosEscalationPrefs.fromJson(Map<String, dynamic> json) {
    final delay = json['delaySeconds'];
    final seconds = delay is int
        ? delay
        : int.tryParse(delay?.toString() ?? '') ?? 60;
    return ChildSosEscalationPrefs(
      enabled: json['enabled'] == true,
      delaySeconds: seconds,
      notifyTrustedBackups: json['notifyTrustedBackups'] != false,
      prepareSmsFallback: json['prepareSmsFallback'] != false,
    );
  }
}

@immutable
final class SosLocalSettings {
  const SosLocalSettings({
    this.panicQuietPreferred = false,
    Map<String, ChildSosEscalationPrefs>? childEscalation,
  }) : _childEscalation = childEscalation;

  static const Map<String, ChildSosEscalationPrefs> _empty =
      <String, ChildSosEscalationPrefs>{};

  /// Child/parent preference hint captured at fire time (OD-15).
  final bool panicQuietPreferred;

  /// Nullable storage so hot-reload / legacy instances never crash readers.
  final Map<String, ChildSosEscalationPrefs>? _childEscalation;

  /// childId.value → escalation prefs for that child only.
  Map<String, ChildSosEscalationPrefs> get childEscalation =>
      _childEscalation ?? _empty;

  ChildSosEscalationPrefs escalationFor(String childId) =>
      childEscalation[childId] ?? const ChildSosEscalationPrefs();

  SosLocalSettings copyWith({
    bool? panicQuietPreferred,
    Map<String, ChildSosEscalationPrefs>? childEscalation,
  }) => SosLocalSettings(
    panicQuietPreferred: panicQuietPreferred ?? this.panicQuietPreferred,
    childEscalation: childEscalation ?? this.childEscalation,
  );

  Map<String, dynamic> toJson() => {
    'panicQuietPreferred': panicQuietPreferred,
    'childEscalation': {
      for (final e in childEscalation.entries) e.key: e.value.toJson(),
    },
  };

  factory SosLocalSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['childEscalation'];
    final map = <String, ChildSosEscalationPrefs>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final v = e.value;
        if (v is Map) {
          map[e.key.toString()] = ChildSosEscalationPrefs.fromJson(
            Map<String, dynamic>.from(
              v.map((k, val) => MapEntry(k.toString(), val)),
            ),
          );
        }
      }
    }
    return SosLocalSettings(
      panicQuietPreferred: json['panicQuietPreferred'] == true,
      childEscalation: map,
    );
  }
}

/// Rule 25 seam — InMemory or Local KV durable (DOM-SOS-SETTINGS).
abstract class SosSettingsStore {
  SosLocalSettings get settings;
  void setPanicQuietPreferred(bool value);
  void setChildEscalation(String childId, ChildSosEscalationPrefs prefs);
  void reset();
}

final class InMemorySosSettingsStore implements SosSettingsStore {
  SosLocalSettings _settings = const SosLocalSettings();

  @override
  SosLocalSettings get settings => _settings;

  @override
  void setPanicQuietPreferred(bool value) {
    _settings = _settings.copyWith(panicQuietPreferred: value);
  }

  @override
  void setChildEscalation(String childId, ChildSosEscalationPrefs prefs) {
    final next = Map<String, ChildSosEscalationPrefs>.from(
      _settings.childEscalation,
    );
    next[childId] = prefs;
    _settings = _settings.copyWith(childEscalation: next);
  }

  @override
  void reset() {
    _settings = const SosLocalSettings();
  }
}

/// Stage-1 singleton — production may rebind to durable Local KV.
SosSettingsStore stage1SosSettingsStore = InMemorySosSettingsStore();

void rebindStage1SosSettingsStore(SosSettingsStore store) {
  stage1SosSettingsStore = store;
}
