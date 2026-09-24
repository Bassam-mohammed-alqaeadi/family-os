/// Local SOS settings seam (OD-15 Panic Quiet preference) — UI slice only.
library;

import 'package:flutter/foundation.dart';

@immutable
final class SosLocalSettings {
  const SosLocalSettings({
    this.panicQuietPreferred = false,
  });

  /// Child/parent preference hint captured at fire time (OD-15).
  final bool panicQuietPreferred;

  SosLocalSettings copyWith({bool? panicQuietPreferred}) => SosLocalSettings(
        panicQuietPreferred: panicQuietPreferred ?? this.panicQuietPreferred,
      );
}

final class InMemorySosSettingsStore {
  SosLocalSettings _settings = const SosLocalSettings();

  SosLocalSettings get settings => _settings;

  void setPanicQuietPreferred(bool value) {
    _settings = _settings.copyWith(panicQuietPreferred: value);
  }

  void reset() {
    _settings = const SosLocalSettings();
  }
}

final InMemorySosSettingsStore stage1SosSettingsStore =
    InMemorySosSettingsStore();
