import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Test / demo fixtures for SCR-FAT-022 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (عائلة 1 / شريكة 1 / ابن 1…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-022 branches without planted person names.
abstract final class ConversationMock {
  const ConversationMock._();

  /// Family group thread (pinned honesty note).
  static const ConversationDetail family = ConversationDetail(
    chatWith: 'family',
    title: 'عائلة 1 👨‍👩‍👧‍👦',
    subtitle: '5 أعضاء',
    emoji: '👨‍👩‍👧‍👦',
    familyPinnedNote: true,
    messages: [
      ConversationMessage(
        id: 'f1',
        body: 'العشاء جاهز يا أحباب',
        timeLabel: '8:12 م',
        isMine: false,
        senderLabel: 'شريكة 1',
      ),
      ConversationMessage(
        id: 'f2',
        body: 'جاي أول واحد!',
        timeLabel: '8:12 م',
        isMine: false,
        senderLabel: 'ابن 1',
      ),
      ConversationMessage(
        id: 'f3',
        body: 'أجمل لمّة — قادم يا أحباب',
        timeLabel: '8:13 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  /// Co-parent DM.
  static const ConversationDetail mother = ConversationDetail(
    chatWith: 'mother',
    title: 'شريكة 1 💗',
    subtitle: 'شريكة التوجيه',
    emoji: '🌸',
    messages: [
      ConversationMessage(
        id: 'm1',
        body: 'ابن 1 نام بدري الليلة — الوضع الجديد ممتاز',
        timeLabel: '9:40 م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'm2',
        body: 'الحمد لله — تعبنا عليه أثمر',
        timeLabel: '9:42 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
      ConversationMessage(
        id: 'm3',
        body: 'لا تنسَ موعد أسنان ابن 2 الخميس',
        timeLabel: '9:43 م',
        isMine: false,
      ),
    ],
  );

  /// Child A DM + tone chips (prototype default branch shape).
  static const ConversationDetail childA = ConversationDetail(
    chatWith: 'child_a',
    title: 'ابن 1 🦁',
    subtitle: 'متصل الآن',
    emoji: '🦁',
    toneChips: [
      'أحسنت يا بطل',
      'اتفقنا',
      'كلمني لما توصل',
      'أنا فخور فيك',
    ],
    messages: [
      ConversationMessage(
        id: 'a1',
        body: 'أبي وصلت المدرسة ✓',
        timeLabel: '7:14 ص',
        isMine: false,
      ),
      ConversationMessage(
        id: 'a2',
        body: 'بطل! يومك موفق',
        timeLabel: '7:15 ص',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
      ConversationMessage(
        id: 'a3',
        body: 'ممكن أروح النادي بعد المدرسة؟',
        timeLabel: '1:50 م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'a4',
        body: 'اتفقنا — وارجع قبل المغرب',
        timeLabel: '1:52 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  /// Child B DM.
  static const ConversationDetail childB = ConversationDetail(
    chatWith: 'child_b',
    title: 'ابن 2 🐱',
    subtitle: 'في بيت الجد',
    emoji: '🐱',
    messages: [
      ConversationMessage(
        id: 'b1',
        body: 'خلصت الواجب!',
        timeLabel: 'أمس 6:40 م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'b2',
        body: 'شاطرة! فخور فيك',
        timeLabel: 'أمس 6:42 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  /// Child C DM (voice preview as text).
  static const ConversationDetail childC = ConversationDetail(
    chatWith: 'child_c',
    title: 'ابن 3 🐼',
    subtitle: 'في بيت الجد',
    emoji: '🐼',
    messages: [
      ConversationMessage(
        id: 'c1',
        body: '🎤 رسالة صوتية · 0:12',
        timeLabel: 'أمس 5:05 م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'c2',
        body: 'وصلتني يا بطل — استمتع عند جدك',
        timeLabel: 'أمس 5:11 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  /// All prototype branches for parametric peer coverage.
  static const List<ConversationDetail> all = [
    family,
    mother,
    childA,
    childB,
    childC,
  ];
}
