import 'package_id.dart';

/// Packages App Control **cannot** deny (APP-OD-09 · APP-SF-04).
///
/// Core four: SOS · Family OS · Required Family Chat · Quran.
abstract final class ProtectedPackageIds {
  static const sos = 'family.os.sos';
  static const familyOs = 'family.os.app';
  static const familyChat = 'family.os.chat';
  static const quran = 'quran';

  /// Canonical protected set.
  static const Set<String> core = {sos, familyOs, familyChat, quran};

  /// Stage-1 / alias tokens also treated as protected.
  static const Set<String> aliases = {
    'sos',
    'family_os',
    'family_chat',
    'familyos',
    'required_chat',
  };

  static bool isProtected(String packageId) {
    final n = PackageId.normalize(packageId);
    return core.contains(n) || aliases.contains(n);
  }

  static bool isProtectedId(PackageId id) => isProtected(id.value);
}
