import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Device-local sample messages for the explicitly mock-first family thread.
///
/// They model local storage only; delivery is never claimed across devices.
List<ConversationMessage> familyChatLocalSampleMessages() {
  return const [
    ConversationMessage(
      id: 'seed_in_1',
      body: 'السلام عليكم — رسالة محفوظة على هذا الجهاز',
      timeLabel: '9:00',
      isMine: false,
      status: ConversationDeliveryStatus.sent,
    ),
    ConversationMessage(
      id: 'seed_out_1',
      body: 'وعليكم السلام',
      timeLabel: '9:01',
      isMine: true,
      status: ConversationDeliveryStatus.sent,
    ),
    ConversationMessage(
      id: 'seed_out_2',
      body: 'كيف الحال؟',
      timeLabel: '9:02',
      isMine: true,
      status: ConversationDeliveryStatus.sent,
    ),
  ];
}
