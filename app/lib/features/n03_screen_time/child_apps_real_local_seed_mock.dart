import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/features/n03_screen_time/child_apps_models.dart';

/// LDR-B2 — REAL_LOCAL managed package catalog (father prefs).
///
/// Not OS discovery: [usedMins] always 0 (Native usage closed).
/// Lives in `*mock*.dart` allowlist (Rule 12).
abstract final class ChildAppsRealLocalSeedMock {
  ChildAppsRealLocalSeedMock._();

  static const List<ChildAppEntry> managedCatalog = [
    ChildAppEntry(
      id: 'youtube',
      name: 'YouTube Kids',
      category: ChildAppCategory.games,
      status: ChildAppStatus.allowed,
      usedMins: 0,
      limitMins: 90,
      ageRating: '9+',
    ),
    ChildAppEntry(
      id: 'roblox',
      name: 'Roblox',
      category: ChildAppCategory.games,
      status: ChildAppStatus.blocked,
      usedMins: 0,
      limitMins: 0,
      ageRating: '10+',
    ),
    ChildAppEntry(
      id: 'whatsapp',
      name: 'WhatsApp',
      category: ChildAppCategory.social,
      status: ChildAppStatus.allowed,
      usedMins: 0,
      limitMins: 45,
      ageRating: '13+',
    ),
    ChildAppEntry(
      id: 'quran',
      name: 'Ayat',
      category: ChildAppCategory.edu,
      status: ChildAppStatus.free,
      usedMins: 0,
      limitMins: -1,
      ageRating: 'all',
    ),
  ];

  static Map<String, List<ChildAppEntry>> forChildren(
    Iterable<ChildId> childIds,
  ) {
    return {
      for (final id in childIds)
        id.value: List<ChildAppEntry>.from(managedCatalog),
    };
  }
}
