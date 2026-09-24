import 'package:family_os/features/n02_day/day_board_projection.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Register §10 reference mock family — Stage-1 demo seed only.
///
/// Lives in `mock/` (Rule 13 / Rule 23). Widgets never import person names;
/// they read values from repositories that this seed fills.
abstract final class RegisterMockFamily {
  static const fatherDisplayName = 'عبدالله';
  static const motherDisplayName = 'نوال';

  static const List<DayChildMock> children = [
    DayChildMock(
      id: 'child_k1',
      displayName: 'خالد',
      emoji: '🦁',
      swatch: DayChildSwatch.purple,
      ageYears: 14,
      locationLabel: 'المدرسة',
      batteryLabel: '٨٤٪',
      timeLeftLabel: '١ س ٢٠ د',
      quranLabel: '٥٠٪',
      walletLabel: '٤٥ د',
    ),
    DayChildMock(
      id: 'child_k2',
      displayName: 'نورة',
      emoji: '🐱',
      swatch: DayChildSwatch.sky,
      ageYears: 11,
      locationLabel: 'المنزل',
      batteryLabel: '٦٢٪',
      timeLeftLabel: '٢ س',
      quranLabel: '٣٠٪',
      walletLabel: '٢٠ د',
    ),
    DayChildMock(
      id: 'child_k3',
      displayName: 'سعد',
      emoji: '🐼',
      swatch: DayChildSwatch.amber,
      ageYears: 8,
      locationLabel: 'الحديقة',
      batteryLabel: '٩١٪',
      timeLeftLabel: '٤٥ د',
      quranLabel: '١٠٪',
      walletLabel: '١٥ د',
    ),
  ];

  /// Morning-board projection matching frozen prototype sample *shape*.
  static DayBoardProjection get dayBoardProjection => DayBoardProjection(
    phase: DayBoardPhase.ready,
    children: children,
    pendingRequests: const [
      DayBoardPendingRequest(
        id: 'req_time_k1',
        title: 'طلب وقت إضافي',
        subtitle: 'خالد · ١٥ دقيقة · يوتيوب',
      ),
    ],
    lastSyncLabel: 'الآن',
    offline: false,
  );
}
