import 'package:flutter/foundation.dart';

/// Amber (never red) smart-watch alert — describes behavior, not the child.
enum SmartAlertKind { withdrawal, arabiziPhrase, emotion, sensitiveImage }

@immutable
final class SmartAlertItem {
  const SmartAlertItem({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.subtitleKey,
    required this.tagKey,
    this.detailScreenId = 'SCR-FAT-066',
  });

  final String id;
  final SmartAlertKind kind;
  final String titleKey;
  final String subtitleKey;
  final String tagKey;
  final String detailScreenId;
}

@immutable
final class SmartWatchTool {
  const SmartWatchTool({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.enabled,
  });

  final String id;
  final String titleKey;
  final String subtitleKey;
  final bool enabled;

  SmartWatchTool copyWith({bool? enabled}) {
    return SmartWatchTool(
      id: id,
      titleKey: titleKey,
      subtitleKey: subtitleKey,
      enabled: enabled ?? this.enabled,
    );
  }
}

@immutable
final class SmartAlertsSnapshot {
  const SmartAlertsSnapshot({this.alerts = const [], this.tools = const []});

  final List<SmartAlertItem> alerts;
  final List<SmartWatchTool> tools;

  bool get isEmpty => alerts.isEmpty && tools.isEmpty;
}
