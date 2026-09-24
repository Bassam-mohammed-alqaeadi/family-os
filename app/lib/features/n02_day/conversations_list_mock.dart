import 'package:family_os/features/n02_day/conversations_list_repository.dart';

/// Test / demo fixtures for SCR-FAT-021 — Rule 12 allowlisted (`*mock*.dart`).
///
/// Generic labels only (عائلة ١ / شريكة ١ / ابن ١…). Never screen default (Rule 23).
/// Mirrors frozen prototype FAT-021 rows without planted person names.
abstract final class ConversationsListMock {
  const ConversationsListMock._();

  /// Single pinned family thread.
  static const ConversationsListSnapshot one = ConversationsListSnapshot(
    threads: [
      ConversationThread(
        id: 'c_family',
        chatWith: 'family',
        title: 'عائلة ١ 📌',
        preview: 'شريكة ١: العشاء جاهز يا أحباب',
        timeLabel: '٨:١٢ م',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        isFamily: true,
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
        title: 'عائلة ١ 📌',
        preview: 'شريكة ١: العشاء جاهز يا أحباب',
        timeLabel: '٨:١٢ م',
        emoji: '👨‍👩‍👧‍👦',
        swatch: ConversationSwatch.family,
        isFamily: true,
        pinned: true,
        unreadCount: 2,
      ),
      ConversationThread(
        id: 'c_mother',
        chatWith: 'mother',
        title: 'شريكة ١ 💗',
        preview: 'ابن ١ نام بدري الليلة',
        timeLabel: '٩:٤٠ م',
        emoji: '🌸',
        swatch: ConversationSwatch.mother,
      ),
      ConversationThread(
        id: 'c_child_a',
        chatWith: 'child_a',
        title: 'ابن ١',
        preview: 'أبي وصلت المدرسة ✓',
        timeLabel: '٧:١٤ ص',
        emoji: '🦁',
        swatch: ConversationSwatch.purple,
      ),
      ConversationThread(
        id: 'c_child_b',
        chatWith: 'child_b',
        title: 'ابن ٢',
        preview: 'خلصت الواجب!',
        timeLabel: 'أمس',
        emoji: '🐱',
        swatch: ConversationSwatch.sky,
      ),
      ConversationThread(
        id: 'c_child_c',
        chatWith: 'child_c',
        title: 'ابن ٣',
        preview: '',
        timeLabel: 'أمس',
        emoji: '🐼',
        swatch: ConversationSwatch.amber,
        previewKind: ConversationPreviewKind.voice,
      ),
    ],
  );
}
