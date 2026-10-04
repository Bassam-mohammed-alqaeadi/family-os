import 'package:family_os/features/n02_day/alert_detail_repository.dart';
import 'package:family_os/features/n02_day/alerts_hub_repository.dart';

/// Test / demo fixtures for SCR-FAT-020 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (ابن 1/2/3). Never the screen default (Rule 23).
/// IDs/kinds align with [AlertsHubMock] FAT-019 → FAT-020 seam.
abstract final class AlertDetailMock {
  const AlertDetailMock._();

  static const List<AlertDetail> seeded = [
    AlertDetail(
      id: 'a_stranger',
      kind: AlertDetailKind.stranger,
      childId: 'child_a',
      urgency: AlertUrgency.critical,
      title: 'رقم غير معروف راسل ابن 1',
      body:
          'تلقّى ابن 1 رسائل من رقم خارج دائرته المعتمدة، فيها طلب لقاء. '
          'لا نعرض لك نص الرسائل — نعرض الفئة والخطورة فقط، احترامًا لثقة الابن وحمايةً له معًا.',
      advice:
          'تحدث مع ابن 1 اليوم بهدوء، ولا تبدأ بالعتاب — الهدف أن يخبرك هو.',
      toneReplies: [
        AlertToneReply(
          id: 'tone_curious',
          text: 'يا بطل، مين صاحبك الجديد؟',
          hint: 'فضول ودود — لا اتهام',
        ),
        AlertToneReply(
          id: 'tone_open',
          text: 'حبيبي، احكِ لي عن يومك',
          hint: 'باب مفتوح',
        ),
      ],
    ),
    AlertDetail(
      id: 'a_battery',
      kind: AlertDetailKind.battery,
      childId: 'child_b',
      urgency: AlertUrgency.attention,
      title: 'بطارية ابن 2 32٪ وتنخفض',
      body:
          'قد ينقطع الاتصال بجهاز ابن 2 خلال ساعتين تقريبًا. آخر شحن كامل: صباح اليوم.',
      advice:
          'ابن 2 في بيت الجد — رسالة لطيفة تذكّره بالشاحن تكفي، لا داعي للقلق.',
    ),
    AlertDetail(
      id: 'a_games',
      kind: AlertDetailKind.games,
      childId: 'child_a',
      urgency: AlertUrgency.attention,
      title: 'ابن 1 تجاوز حد الألعاب 15 دقيقة',
      body:
          'حد الألعاب اليومي ساعة — لعب اليوم 1 س 15 د. هذا أول تجاوز هذا الأسبوع.',
      advice: 'تجاوز أول ومعزول — تنبيه لطيف يكفي، ولا حاجة لتشديد القاعدة.',
    ),
    AlertDetail(
      id: 'a_arrive',
      kind: AlertDetailKind.arrive,
      childId: 'child_c',
      urgency: AlertUrgency.reassurance,
      title: 'ابن 3 وصل بيت الجد بسلام',
      body:
          'دخل منطقة «بيت الجد» الآمنة قبل 42 دقيقة · 77٪ بطارية · كل شيء على ما يرام.',
    ),
  ];
}
