import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Test / demo fixtures for SCR-CHD-007 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Closed circle only (عائلة · أب · أم). Generic labels — never planted names
/// (Rule 23). Mirrors frozen prototype CHD-007 without عبدالله/خالد.
abstract final class ChildChatsMock {
  const ChildChatsMock._();

  /// Single pinned family thread.
  static const ConversationsListSnapshot one = ConversationsListSnapshot(
    threads: [
      ConversationThread(
        id: 'c_family',
        chatWith: 'family',
        title: 'عائلة ١ 📌',
        preview: 'أم ١: العشاء جاهز',
        timeLabel: '٢',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        pinned: true,
        unreadCount: 2,
      ),
    ],
  );

  /// Family + father + mother (prototype CHD-007 closed circle).
  static const ConversationsListSnapshot many = ConversationsListSnapshot(
    threads: [
      ConversationThread(
        id: 'c_family',
        chatWith: 'family',
        title: 'عائلة ١ 📌',
        preview: 'أم ١: العشاء جاهز',
        timeLabel: '٢',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        pinned: true,
        unreadCount: 2,
      ),
      ConversationThread(
        id: 'c_father',
        chatWith: 'father',
        title: 'أب ١',
        preview: 'اتفقنا — وارجع قبل المغرب',
        timeLabel: '١:٥٢ م',
        emoji: '👨',
        swatch: ConversationSwatch.purple,
      ),
      ConversationThread(
        id: 'c_mother',
        chatWith: 'mother',
        title: 'أم ١',
        preview: '🎤 رسالة صوتية',
        timeLabel: 'أمس',
        emoji: '👩',
        swatch: ConversationSwatch.mother,
      ),
    ],
  );
}
