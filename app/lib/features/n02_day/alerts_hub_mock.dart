import 'package:family_os/features/n02_day/alerts_hub_repository.dart';
import 'package:family_os/features/n02_day/day_child_mock.dart';

/// Test / demo fixtures for SCR-FAT-019 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1/2/3). Never the screen default (Rule 23).
/// Mirrors frozen prototype FAT-019 urgency ladder + destinations.
abstract final class AlertsHubMock {
  const AlertsHubMock._();

  static const AlertsHubSnapshot seeded = AlertsHubSnapshot(
    critical: [
      HubAlert(
        id: 'a_stranger',
        urgency: AlertUrgency.critical,
        title: 'رسالة من مجهول لابن 1',
        subtitle: 'فئة: تواصل غريب · قبل 12 د',
        emoji: '🦁',
        swatch: DayChildSwatch.purple,
        target: HubAlertTarget.alertDetail,
        alertKind: 'stranger',
      ),
      HubAlert(
        id: 'a_app',
        urgency: AlertUrgency.critical,
        title: 'ابن 1 ثبّت تطبيقًا جديدًا',
        subtitle: 'معلّق حتى قرارك · 4:10 م',
        emoji: '👻',
        swatch: DayChildSwatch.amber,
        target: HubAlertTarget.appApproval,
      ),
      HubAlert(
        id: 'a_extra',
        urgency: AlertUrgency.critical,
        title: 'ابن 1 يطلب 30 دقيقة إضافية',
        subtitle: 'بانتظار ردك · قبل 3 د',
        emoji: '⏳',
        swatch: DayChildSwatch.purple,
        target: HubAlertTarget.timeRequests,
      ),
    ],
    attention: [
      HubAlert(
        id: 'a_battery',
        urgency: AlertUrgency.attention,
        title: 'بطارية ابن 2 32٪',
        subtitle: 'قد ينقطع الاتصال · قبل 20 د',
        emoji: '🐱',
        swatch: DayChildSwatch.sky,
        target: HubAlertTarget.alertDetail,
        alertKind: 'battery',
      ),
      HubAlert(
        id: 'a_games',
        urgency: AlertUrgency.attention,
        title: 'ابن 1 تجاوز حد الألعاب 15 د',
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
        title: 'ابن 3 وصل بيت الجد',
        subtitle: 'منطقة آمنة · قبل 42 د',
        emoji: '🐼',
        swatch: DayChildSwatch.amber,
        target: HubAlertTarget.alertDetail,
        alertKind: 'arrive',
      ),
      HubAlert(
        id: 'a_tasks',
        urgency: AlertUrgency.reassurance,
        title: 'ابن 2 أنهى مهام اليوم',
        subtitle: '⏱ +30 دقيقة · قبل ساعتين',
        emoji: '🐱',
        swatch: DayChildSwatch.sky,
        target: HubAlertTarget.none,
      ),
    ],
  );
}
