import 'package:flutter/foundation.dart';

/// App locale options on SCR-FAT-061 (prototype FAT-061).
enum LanguageHelpLocale {
  arabic,
  english,
}

/// Help-center link kinds — prototype rows.
enum LanguageHelpLinkKind {
  /// Device disconnect guide → SCR-FAT-026.
  deviceDisconnect,

  /// Parent-mode unlock help → SCR-FAT-030.
  parentModeUnlock,
}

/// One help-center row (Rule 23 — kind only, no planted names).
@immutable
final class LanguageHelpLink {
  const LanguageHelpLink({
    required this.id,
    required this.kind,
  });

  final String id;
  final LanguageHelpLinkKind kind;
}

/// Loaded snapshot for SCR-FAT-061.
@immutable
final class LanguageHelpSnapshot {
  const LanguageHelpSnapshot({
    this.currentLocale = LanguageHelpLocale.arabic,
    this.helpLinks = const [],
  });

  final LanguageHelpLocale currentLocale;
  final List<LanguageHelpLink> helpLinks;

  /// Empty — no family setup yet → SCR-FAT-003.
  bool get isEmpty => helpLinks.isEmpty;
}
