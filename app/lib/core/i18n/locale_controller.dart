import 'package:flutter/widgets.dart';

import 'package:family_os/core/fs_foundation/fs_session_kernel.dart';
import 'package:family_os/core/prefs_misc/prefs_misc_local_persistence.dart';

/// VX-B3 · D1 — app-wide locale, persisted in prefs-misc Local KV.
final class LocaleController extends ChangeNotifier {
  LocaleController({
    Locale initial = const Locale('ar'),
    Future<void> Function(String languageCode)? persist,
  }) : _locale = _normalize(initial),
       _persist = persist;

  static const kvNamespace = 'prefs_locale';
  static const kvKey = 'language_code';

  Locale _locale;
  final Future<void> Function(String languageCode)? _persist;

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> setLocale(Locale next) async {
    final normalized = _normalize(next);
    if (normalized == _locale) return;
    _locale = normalized;
    notifyListeners();
    final persist = _persist;
    if (persist != null) {
      await persist(normalized.languageCode);
    }
  }

  static Locale _normalize(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    if (code == 'en') return const Locale('en');
    return const Locale('ar');
  }

  /// Loads from Local KV when SQLite is honest; otherwise Arabic default.
  static Future<LocaleController> open() async {
    await FsSessionKernel.ensureOpen();
    if (FsSessionKernel.sqliteFallbackToMemory) {
      return LocaleController();
    }
    final store = LocalPrefsMiscKvStore(
      FsSessionKernel.db,
      namespace: kvNamespace,
    );
    final raw = await store.read(kvKey);
    final initial = raw == 'en' ? const Locale('en') : const Locale('ar');
    return LocaleController(
      initial: initial,
      persist: (code) => store.write(kvKey, code),
    );
  }
}

/// Provides [LocaleController] down the tree (main composition root).
final class CurrentLocale extends InheritedNotifier<LocaleController> {
  const CurrentLocale({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurrentLocale>();
    assert(scope != null, 'CurrentLocale not found');
    return scope!.notifier!;
  }

  static LocaleController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CurrentLocale>()
        ?.notifier;
  }
}
