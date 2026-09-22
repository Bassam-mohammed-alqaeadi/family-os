import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Test / demo fixtures for SCR-FAT-022 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (عائلة ١ / شريكة ١ / ابن ١…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-022 branches without planted person names.
abstract final class ConversationMock {
  const ConversationMock._();

  /// Family group thread (pinned honesty note).
  static const ConversationDetail family = ConversationDetail(
    chatWith: 'family',
    title: 'عائلة ١ 👨‍👩‍👧‍👦',
    subtitle: '٥ أعضاء',
    emoji: '👨‍👩‍👧‍👦',
    familyPinnedNote: true,
    messages: [
      ConversationMessage(
        id: 'f1',
        body: 'العشاء جاهز يا أحباب',
        timeLabel: '٨:١٢ م',
        isMine: false,
        senderLabel: 'شريكة ١',
      ),
      ConversationMessage(
        id: 'f2',
        body: 'جاي أول واحد!',
        timeLabel: '٨:١٢ م',
        isMine: false,
        senderLabel: 'ابن ١',
      ),
      ConversationMessage(
        id: 'f3',
        body: 'أجمل لمّة — قادم يا أحباب',
        timeLabel: '٨:١٣ م',
        isMine: true,
        status: ConversationDeliveryStatus.read,
      ),
    ],
  );

  /// Co-parent DM.
  static const ConversationDetail mother = ConversationDetail(
    chatWith: 'mother',
    title: 'شريكة ١ 💗',
    subtitle: 'شريكة التوجيه',
    emoji: '🌸',
    messages: [
      ConversationMessage(
        id: 'm1',
        body: 'ابن ١ نام بدري الليلة — الوضع الجديد ممتاز',
        timeLabel: '٩:٤٠ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'm2',
        body: 'الحمد لله — تعبنا عليه أثمر',
        timeLabel: '٩:٤٢ م',
        isMine: true,
        status: ConversationDeliveryStatus.read,
      ),
      ConversationMessage(
        id: 'm3',
        body: 'لا تنسَ موعد أسنان ابن ٢ الخميس',
        timeLabel: '٩:٤٣ م',
        isMine: false,
      ),
    ],
  );

  /// Child A DM + tone chips (prototype default branch shape).
  static const ConversationDetail childA = ConversationDetail(
    chatWith: 'child_a',
    title: 'ابن ١ 🦁',
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
        timeLabel: '٧:١٤ ص',
        isMine: false,
      ),
      ConversationMessage(
        id: 'a2',
        body: 'بطل! يومك موفق',
        timeLabel: '٧:١٥ ص',
        isMine: true,
        status: ConversationDeliveryStatus.read,
      ),
      ConversationMessage(
        id: 'a3',
        body: 'ممكن أروح النادي بعد المدرسة؟',
        timeLabel: '١:٥٠ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'a4',
        body: 'اتفقنا — وارجع قبل المغرب',
        timeLabel: '١:٥٢ م',
        isMine: true,
        status: ConversationDeliveryStatus.read,
      ),
    ],
  );

  /// Child B DM.
  static const ConversationDetail childB = ConversationDetail(
    chatWith: 'child_b',
    title: 'ابن ٢ 🐱',
    subtitle: 'في بيت الجد',
    emoji: '🐱',
    messages: [
      ConversationMessage(
        id: 'b1',
        body: 'خلصت الواجب!',
        timeLabel: 'أمس ٦:٤٠ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'b2',
        body: 'شاطرة! فخور فيك',
        timeLabel: 'أمس ٦:٤٢ م',
        isMine: true,
        status: ConversationDeliveryStatus.read,
      ),
    ],
  );

  /// Child C DM (voice preview as text).
  static const ConversationDetail childC = ConversationDetail(
    chatWith: 'child_c',
    title: 'ابن ٣ 🐼',
    subtitle: 'في بيت الجد',
    emoji: '🐼',
    messages: [
      ConversationMessage(
        id: 'c1',
        body: '🎤 رسالة صوتية · ٠:١٢',
        timeLabel: 'أمس ٥:٠٥ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'c2',
        body: 'وصلتني يا بطل — استمتع عند جدك',
        timeLabel: 'أمس ٥:١١ م',
        isMine: true,
        status: ConversationDeliveryStatus.read,
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
