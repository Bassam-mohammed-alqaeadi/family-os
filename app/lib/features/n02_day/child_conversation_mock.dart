import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Test / demo fixtures for SCR-CHD-008 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Child POV: [ConversationMessage.isMine] = child outbound. Generic labels only
/// (أب ١ / أم ١ / عائلة ١) — never planted names (Rule 23).
abstract final class ChildConversationMock {
  const ChildConversationMock._();

  /// Father DM — prototype CHD-008 default shape.
  static const ConversationDetail father = ConversationDetail(
    chatWith: 'father',
    title: 'أب ١ 👨',
    subtitle: 'دائرة العائلة',
    emoji: '👨',
    messages: [
      ConversationMessage(
        id: 'cf1',
        body: 'اتفقنا — وارجع قبل المغرب',
        timeLabel: '١:٥٢ م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'cf2',
        body: 'توّي واصل النادي',
        timeLabel: '٤:١٠ م',
        isMine: true,
        tick: MessageTick.read,
      ),
      ConversationMessage(
        id: 'cf3',
        body: 'استمتع — وخلّ عينك عالساعة',
        timeLabel: '٤:١١ م',
        isMine: false,
      ),
    ],
  );

  /// Mother DM.
  static const ConversationDetail mother = ConversationDetail(
    chatWith: 'mother',
    title: 'أم ١ 👩',
    subtitle: 'دائرة العائلة',
    emoji: '👩',
    messages: [
      ConversationMessage(
        id: 'cm1',
        body: '🎤 رسالة صوتية',
        timeLabel: 'أمس',
        isMine: false,
      ),
      ConversationMessage(
        id: 'cm2',
        body: 'وصلتني — أحبك',
        timeLabel: 'أمس',
        isMine: true,
        tick: MessageTick.read,
      ),
    ],
  );

  /// Pinned family group (child view).
  static const ConversationDetail family = ConversationDetail(
    chatWith: 'family',
    title: 'عائلة ١ 📌',
    subtitle: 'دائرتك الآمنة',
    emoji: '👨‍👩‍👧‍👦',
    familyPinnedNote: true,
    pinnedMessage: ConversationMessage(
      id: 'cg1',
      body: 'العشاء جاهز',
      timeLabel: '٨:١٢ م',
      isMine: false,
      senderLabel: 'أم ١',
      pinned: true,
    ),
    messages: [
      ConversationMessage(
        id: 'cg1',
        body: 'العشاء جاهز',
        timeLabel: '٨:١٢ م',
        isMine: false,
        senderLabel: 'أم ١',
        pinned: true,
      ),
      ConversationMessage(
        id: 'cg2',
        body: 'جاي!',
        timeLabel: '٨:١٣ م',
        isMine: true,
        tick: MessageTick.read,
      ),
    ],
  );

  static const List<ConversationDetail> all = [father, mother, family];
}
