import 'package:family_os/features/n12_devices/language_help_models.dart';

/// Rule 25 seam — Stage-1 mock language & help (no backend).
abstract class LanguageHelpRepository {
  Future<LanguageHelpSnapshot> load();
}

/// In-memory mock — prototype FAT-061 shape by default.
final class InMemoryLanguageHelpRepository implements LanguageHelpRepository {
  InMemoryLanguageHelpRepository({LanguageHelpSnapshot? seed})
    : _snap = seed ?? languageHelpPrototypeFixture();

  LanguageHelpSnapshot _snap;

  /// Optional gate for loading-state widget tests.
  Future<void> Function()? loadGate;

  @override
  Future<LanguageHelpSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return LanguageHelpSnapshot(
      currentLocale: _snap.currentLocale,
      helpLinks: List<LanguageHelpLink>.from(_snap.helpLinks),
    );
  }

  void seed(LanguageHelpSnapshot snap) {
    _snap = snap;
  }
}

/// Shared Stage-1 singleton (prototype fixture until a screen/test seeds).
final InMemoryLanguageHelpRepository stage1LanguageHelpRepository =
    InMemoryLanguageHelpRepository();

/// Empty — Rule 23 empty-state coverage → SCR-FAT-003.
LanguageHelpSnapshot languageHelpEmptyFixture() {
  return const LanguageHelpSnapshot();
}

/// One help link — Rule 23 one-item coverage.
LanguageHelpSnapshot languageHelpOneFixture() {
  return const LanguageHelpSnapshot(
    helpLinks: [
      LanguageHelpLink(
        id: 'help-device',
        kind: LanguageHelpLinkKind.deviceDisconnect,
      ),
    ],
  );
}

/// Prototype FAT-061 — Arabic current + two help-center rows.
LanguageHelpSnapshot languageHelpPrototypeFixture() {
  return const LanguageHelpSnapshot(
    currentLocale: LanguageHelpLocale.arabic,
    helpLinks: [
      LanguageHelpLink(
        id: 'help-device',
        kind: LanguageHelpLinkKind.deviceDisconnect,
      ),
      LanguageHelpLink(
        id: 'help-parent-mode',
        kind: LanguageHelpLinkKind.parentModeUnlock,
      ),
    ],
  );
}
