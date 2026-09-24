import 'package:family_os/features/n03_screen_time/child_apps_models.dart';

/// Stage-1 demo child key (Rule 23 — opaque id, not a planted name).
const String kDefaultChildAppsChildKey = 'demo-child';

/// Prototype-shaped inventory (product names only — no child display names).
final Map<String, List<ChildAppEntry>> kDefaultChildAppsByChild = {
  kDefaultChildAppsChildKey: List<ChildAppEntry>.unmodifiable([
    const ChildAppEntry(
      id: 'minecraft',
      name: 'Minecraft',
      category: ChildAppCategory.games,
      status: ChildAppStatus.allowed,
      usedMins: 40,
      limitMins: 60,
      ageRating: '7+',
    ),
    const ChildAppEntry(
      id: 'roblox',
      name: 'Roblox',
      category: ChildAppCategory.games,
      status: ChildAppStatus.blocked,
      ageRating: '10+',
    ),
    const ChildAppEntry(
      id: 'youtube',
      name: 'YouTube Kids',
      category: ChildAppCategory.games,
      status: ChildAppStatus.allowed,
      usedMins: 55,
      limitMins: 90,
      ageRating: '9+',
    ),
    const ChildAppEntry(
      id: 'subway',
      name: 'Subway Surfers',
      category: ChildAppCategory.games,
      status: ChildAppStatus.allowed,
      usedMins: 15,
      limitMins: 30,
      ageRating: '7+',
    ),
    const ChildAppEntry(
      id: 'whatsapp',
      name: 'WhatsApp',
      category: ChildAppCategory.social,
      status: ChildAppStatus.allowed,
      usedMins: 20,
      limitMins: 45,
      ageRating: '13+',
    ),
    const ChildAppEntry(
      id: 'snapchat',
      name: 'Snapchat',
      category: ChildAppCategory.social,
      status: ChildAppStatus.pending,
      limitMins: 30,
      ageRating: '13+',
    ),
    const ChildAppEntry(
      id: 'tiktok',
      name: 'TikTok',
      category: ChildAppCategory.social,
      status: ChildAppStatus.blocked,
      ageRating: '13+',
    ),
    const ChildAppEntry(
      id: 'quran',
      name: 'Ayat (Madinah Mushaf)',
      category: ChildAppCategory.edu,
      status: ChildAppStatus.free,
      usedMins: 35,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'photomath',
      name: 'Photomath',
      category: ChildAppCategory.edu,
      status: ChildAppStatus.free,
      usedMins: 25,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'duolingo',
      name: 'Duolingo',
      category: ChildAppCategory.edu,
      status: ChildAppStatus.free,
      usedMins: 20,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'madrasati',
      name: 'Madrasati',
      category: ChildAppCategory.edu,
      status: ChildAppStatus.free,
      usedMins: 45,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'camera',
      name: 'Camera',
      category: ChildAppCategory.tools,
      status: ChildAppStatus.free,
      usedMins: 10,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'calculator',
      name: 'Calculator',
      category: ChildAppCategory.tools,
      status: ChildAppStatus.free,
      usedMins: 5,
      limitMins: -1,
      ageRating: 'all',
    ),
    const ChildAppEntry(
      id: 'clock',
      name: 'Clock',
      category: ChildAppCategory.tools,
      status: ChildAppStatus.free,
      usedMins: 2,
      limitMins: -1,
      ageRating: 'all',
    ),
  ]),
};

/// Single-app fixture for widget tests.
List<ChildAppEntry> childAppsOneFixture() => [
  const ChildAppEntry(
    id: 'minecraft',
    name: 'Minecraft',
    category: ChildAppCategory.games,
    status: ChildAppStatus.allowed,
    usedMins: 10,
    limitMins: 60,
    ageRating: '7+',
  ),
];
