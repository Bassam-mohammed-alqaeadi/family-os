import 'package:family_os/core/data/communication_rules.dart';
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
    pinnedMessage: ConversationMessage(
      id: 'f1',
      body: 'العشاء جاهز يا أحباب',
      timeLabel: '٨:١٢ م',
      isMine: false,
      senderLabel: 'شريكة ١',
      pinned: true,
    ),
    messages: [
      ConversationMessage(
        id: 'f1',
        body: 'العشاء جاهز يا أحباب',
        timeLabel: '٨:١٢ م',
        isMine: false,
        senderLabel: 'شريكة ١',
        pinned: true,
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
        tick: MessageTick.read,
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
        tick: MessageTick.read,
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
    subtitle: 'دائرة العائلة',
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
        tick: MessageTick.read,
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
        tick: MessageTick.read,
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
        tick: MessageTick.read,
      ),
    ],
  );

  /// Child C DM (voice thread).
  static const ConversationDetail childC = ConversationDetail(
    chatWith: 'child_c',
    title: 'ابن ٣ 🐼',
    subtitle: 'في بيت الجد',
    emoji: '🐼',
    messages: [
      ConversationMessage(
        id: 'c1',
        body: '',
        timeLabel: 'أمس ٥:٠٥ م',
        isMine: false,
        kind: ConversationMediaKind.voice,
      ),
      ConversationMessage(
        id: 'c2',
        body: 'وصلتني يا بطل — استمتع عند جدك',
        timeLabel: 'أمس ٥:١١ م',
        isMine: true,
        tick: MessageTick.read,
      ),
    ],
  );

  /// Peer thread (child↔child) — no parent member, so read receipts may be
  /// switched off here and only here (ADR-053 family adaptation). Shows a reply
  /// and a tombstone so both render in place.
  static const ConversationDetail peer = ConversationDetail(
    chatWith: 'peer_a',
    title: 'ابن ٤ 🐢',
    subtitle: 'دائرة الأقران',
    emoji: '🐢',
    hasParentMember: false,
    messages: [
      ConversationMessage(
        id: 'p1',
        body: 'شفت الصورة؟',
        timeLabel: '٤:٠٠ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'p2',
        body: 'أي صورة؟',
        timeLabel: '٤:٠١ م',
        isMine: true,
        tick: MessageTick.read,
        replyTo: ConversationReply(
          id: 'p1',
          preview: 'شفت الصورة؟',
          fromMe: false,
        ),
      ),
      ConversationMessage(
        id: 'p3',
        body: '',
        timeLabel: '٤:٠٢ م',
        isMine: false,
        deleted: true,
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
    peer,
  ];
}
