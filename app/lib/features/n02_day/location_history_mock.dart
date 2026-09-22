import 'package:family_os/features/n02_day/location_history_repository.dart';

/// Test / demo fixtures for SCR-FAT-015 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١). Never the screen default (Rule 23).
abstract final class LocationHistoryMock {
  const LocationHistoryMock._();

  static const LocationHistorySnapshot childA = LocationHistorySnapshot(
    childId: 'child_a',
    displayName: 'ابن ١',
    days: [
      LocationHistoryDay(
        id: 'day_today',
        heading: 'اليوم — الأحد ١٤ سبتمبر',
        stops: [
          LocationHistoryStop(
            title: '🏫 ثانوية النور',
            timeLabel: '٧:١٢ ص حتى الآن · داخل منطقة آمنة',
            isCurrent: true,
          ),
          LocationHistoryStop(
            title: '🚗 الطريق إلى المدرسة',
            timeLabel: '٦:٥٥ – ٧:١٢ ص · ١٧ دقيقة',
          ),
          LocationHistoryStop(
            title: '🏠 المنزل',
            timeLabel: 'حتى ٦:٥٥ ص',
          ),
        ],
      ),
      LocationHistoryDay(
        id: 'day_yesterday',
        heading: 'أمس — السبت',
        stops: [
          LocationHistoryStop(
            title: '🏠 المنزل',
            timeLabel: '٦:٤٠ م – حتى الصباح',
          ),
          LocationHistoryStop(
            title: '⚽ نادي الحي',
            timeLabel: '٤:٣٠ – ٦:٢٥ م',
          ),
          LocationHistoryStop(
            title: '🏫 ثانوية النور',
            timeLabel: '٧:١٠ ص – ١:٤٥ م',
          ),
        ],
      ),
    ],
    frequentPlaces: [
      LocationFrequentPlace(
        id: 'freq_school',
        emoji: '🏫',
        title: 'ثانوية النور',
        subtitle: 'كل يوم دراسي · ٧ص–٢م تقريبًا',
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
        subtitle: 'ظهر ٣ مرات هذا الأسبوع — مكان جديد',
        regularity: LocationPlaceRegularity.novel,
      ),
    ],
  );

  /// Known child with no trail yet (empty body, not not-found).
  static const LocationHistorySnapshot childEmpty = LocationHistorySnapshot(
    childId: 'child_empty',
    displayName: 'ابن ٢',
    days: [],
  );

  static Map<String, LocationHistorySnapshot> get seeded => {
        childA.childId: childA,
        childEmpty.childId: childEmpty,
      };
}
