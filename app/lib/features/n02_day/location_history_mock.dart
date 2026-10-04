import 'package:family_os/features/n02_day/location_history_repository.dart';

/// Test / demo fixtures for SCR-FAT-015 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1). Never the screen default (Rule 23).
abstract final class LocationHistoryMock {
  const LocationHistoryMock._();

  static const LocationHistorySnapshot childA = LocationHistorySnapshot(
    childId: 'child_a',
    displayName: 'ابن 1',
    days: [
      LocationHistoryDay(
        id: 'day_today',
        heading: 'اليوم — الأحد 14 سبتمبر',
        stops: [
          LocationHistoryStop(
            title: '🏫 ثانوية النور',
            timeLabel: '7:12 ص حتى الآن · داخل منطقة آمنة',
            isCurrent: true,
          ),
          LocationHistoryStop(
            title: '🚗 الطريق إلى المدرسة',
            timeLabel: '6:55 – 7:12 ص · 17 دقيقة',
          ),
          LocationHistoryStop(title: '🏠 المنزل', timeLabel: 'حتى 6:55 ص'),
        ],
      ),
      LocationHistoryDay(
        id: 'day_yesterday',
        heading: 'أمس — السبت',
        stops: [
          LocationHistoryStop(
            title: '🏠 المنزل',
            timeLabel: '6:40 م – حتى الصباح',
          ),
          LocationHistoryStop(title: '⚽ نادي الحي', timeLabel: '4:30 – 6:25 م'),
          LocationHistoryStop(
            title: '🏫 ثانوية النور',
            timeLabel: '7:10 ص – 1:45 م',
          ),
        ],
      ),
    ],
    frequentPlaces: [
      LocationFrequentPlace(
        id: 'freq_school',
        emoji: '🏫',
        title: 'ثانوية النور',
        subtitle: 'كل يوم دراسي · 7ص–2م تقريبًا',
        regularity: LocationPlaceRegularity.regular,
      ),
      LocationFrequentPlace(
        id: 'freq_club',
        emoji: '⚽',
        title: 'نادي الحي',
        subtitle: 'السبت والثلاثاء عصرًا',
        regularity: LocationPlaceRegularity.regular,
      ),
      LocationFrequentPlace(
        id: 'freq_cafe',
        emoji: '❓',
        title: 'مقهى شارع التحلية',
        subtitle: 'ظهر 3 مرات هذا الأسبوع — مكان جديد',
        regularity: LocationPlaceRegularity.novel,
      ),
    ],
  );

  /// Known child with no trail yet (empty body, not not-found).
  static const LocationHistorySnapshot childEmpty = LocationHistorySnapshot(
    childId: 'child_empty',
    displayName: 'ابن 2',
    days: [],
  );

  static Map<String, LocationHistorySnapshot> get seeded => {
    childA.childId: childA,
    childEmpty.childId: childEmpty,
  };
}
