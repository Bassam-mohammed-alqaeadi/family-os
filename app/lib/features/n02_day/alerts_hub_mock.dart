import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-019 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن ١/٢/٣). Never the screen default (Rule 23).
/// Mirrors frozen prototype FAT-019 urgency ladder + destinations.
abstract final class AlertsHubMock {
  const AlertsHubMock._();

  static const AlertsHubSnapshot seeded = AlertsHubSnapshot(
    critical: [
      HubAlert(
        id: 'a_stranger',
        urgency: AlertUrgency.critical,
        title: 'رسالة من مجهول لابن ١',
        subtitle: 'فئة: تواصل غريب · قبل ١٢ د',
        emoji: '🦁',
        swatch: DayChildSwatch.purple,
        target: HubAlertTarget.alertDetail,
        alertKind: 'stranger',
      ),
      HubAlert(
        id: 'a_app',
        urgency: AlertUrgency.critical,
        title: 'ابن ١ ثبّت تطبيقًا جديدًا',
        subtitle: 'معلّق حتى قرارك · ٤:١٠ م',
        emoji: '👻',
        swatch: DayChildSwatch.amber,
        target: HubAlertTarget.appApproval,
      ),
      HubAlert(
        id: 'a_extra',
        urgency: AlertUrgency.critical,
        title: 'ابن ١ يطلب ٣٠ دقيقة إضافية',
        subtitle: 'بانتظار ردك · قبل ٣ د',
        emoji: '⏳',
        swatch: DayChildSwatch.purple,
        target: HubAlertTarget.timeRequests,
      ),
    ],
    attention: [
      HubAlert(
        id: 'a_battery',
        urgency: AlertUrgency.attention,
        title: 'بطارية ابن ٢ ٣٢٪',
        subtitle: 'قد ينقطع الاتصال · قبل ٢٠ د',
        emoji: '🐱',
        swatch: DayChildSwatch.sky,
        target: HubAlertTarget.alertDetail,
        alertKind: 'battery',
      ),
      HubAlert(
        id: 'a_games',
        urgency: AlertUrgency.attention,
        title: 'ابن ١ تجاوز حد الألعاب ١٥ د',
        subtitle: 'قبل ساعة',
        emoji: '🦁',
        swatch: DayChildSwatch.purple,
        target: HubAlertTarget.alertDetail,
        alertKind: 'games',
      ),
    ],
    reassurance: [
      HubAlert(
        id: 'a_arrive',
        urgency: AlertUrgency.reassurance,
        title: 'ابن ٣ وصل بيت الجد',
        subtitle: 'منطقة آمنة · قبل ٤٢ د',
        emoji: '🐼',
        swatch: DayChildSwatch.amber,
        target: HubAlertTarget.alertDetail,
        alertKind: 'arrive',
      ),
      HubAlert(
        id: 'a_tasks',
        urgency: AlertUrgency.reassurance,
        title: 'ابن ٢ أنهى مهام اليوم',
        subtitle: '⏱ +٣٠ دقيقة · قبل ساعتين',
        emoji: '🐱',
        swatch: DayChildSwatch.sky,
        target: HubAlertTarget.none,
      ),
    ],
  );
}
