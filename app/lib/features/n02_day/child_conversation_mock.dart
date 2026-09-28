import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Test / demo fixtures for SCR-CHD-008 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Child POV: [ConversationMessage.isMine] = child outbound. Generic labels only
/// (أب 1 / أم 1 / عائلة 1) — never planted names (Rule 23).
abstract final class ChildConversationMock {
  const ChildConversationMock._();

  /// Father DM — prototype CHD-008 default shape.
  static const ConversationDetail father = ConversationDetail(
    chatWith: 'father',
    title: 'أب 1 👨',
    subtitle: 'متصل',
    emoji: '👨',
    messages: [
      ConversationMessage(
        id: 'cf1',
        body: 'اتفقنا — وارجع قبل المغرب',
        timeLabel: '1:52 م',
        isMine: false,
      ),
      ConversationMessage(
        id: 'cf2',
        body: 'توّي واصل النادي',
        timeLabel: '4:10 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
      ConversationMessage(
        id: 'cf3',
        body: 'استمتع — وخلّ عينك عالساعة',
        timeLabel: '4:11 م',
        isMine: false,
      ),
    ],
  );

  /// Mother DM.
  static const ConversationDetail mother = ConversationDetail(
    chatWith: 'mother',
    title: 'أم 1 👩',
    subtitle: 'متصلة',
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
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  /// Pinned family group (child view).
  static const ConversationDetail family = ConversationDetail(
    chatWith: 'family',
    title: 'عائلة 1 📌',
    subtitle: 'دائرتك الآمنة',
    emoji: '👨‍👩‍👧‍👦',
    familyPinnedNote: true,
    messages: [
      ConversationMessage(
        id: 'cg1',
        body: 'العشاء جاهز',
        timeLabel: '8:12 م',
        isMine: false,
        senderLabel: 'أم 1',
      ),
      ConversationMessage(
        id: 'cg2',
        body: 'جاي!',
        timeLabel: '8:13 م',
        isMine: true,
        status: ConversationDeliveryStatus.sent,
      ),
    ],
  );

  static const List<ConversationDetail> all = [father, mother, family];
}
