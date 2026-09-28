import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Test / demo fixtures for SCR-FAT-021 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (عائلة 1 / شريكة 1 / ابن 1…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-021 rows without planted person names.
abstract final class ConversationsListMock {
  const ConversationsListMock._();

  /// Single pinned family thread.
  static const ConversationsListSnapshot one = ConversationsListSnapshot(
    threads: [
      ConversationThread(
        id: 'c_family',
        chatWith: 'family',
        title: 'عائلة 1 📌',
        preview: 'شريكة 1: العشاء جاهز يا أحباب',
        timeLabel: '8:12 م',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        pinned: true,
        unreadCount: 2,
      ),
    ],
  );

  /// Family + co-parent + three child DMs (prototype shape).
  static const ConversationsListSnapshot many = ConversationsListSnapshot(
    threads: [
      ConversationThread(
        id: 'c_family',
        chatWith: 'family',
        title: 'عائلة 1 📌',
        preview: 'شريكة 1: العشاء جاهز يا أحباب',
        timeLabel: '8:12 م',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        pinned: true,
        unreadCount: 2,
      ),
      ConversationThread(
        id: 'c_mother',
        chatWith: 'mother',
        title: 'شريكة 1 💗',
        preview: 'ابن 1 نام بدري الليلة',
        timeLabel: '9:40 م',
        emoji: '🌸',
        swatch: ConversationSwatch.mother,
      ),
      ConversationThread(
        id: 'c_child_a',
        chatWith: 'child_a',
        title: 'ابن 1',
        preview: 'أبي وصلت المدرسة ✓',
        timeLabel: '7:14 ص',
        emoji: '🦁',
        swatch: ConversationSwatch.purple,
      ),
      ConversationThread(
        id: 'c_child_b',
        chatWith: 'child_b',
        title: 'ابن 2',
        preview: 'خلصت الواجب!',
        timeLabel: 'أمس',
        emoji: '🐱',
        swatch: ConversationSwatch.sky,
      ),
      ConversationThread(
        id: 'c_child_c',
        chatWith: 'child_c',
        title: 'ابن 3',
        preview: '🎤 رسالة صوتية',
        timeLabel: 'أمس',
        emoji: '🐼',
        swatch: ConversationSwatch.amber,
      ),
    ],
  );
}
