import 'package:drift/drift.dart';

import 'communication_rules.dart';
import 'family_database.dart';

/// ADR-053 — «إعدادات هذه المحادثة»، وهي ملك القارئ لا ملك المحادثة.
///
/// The per-chat settings live with the reader, never with the conversation:
/// muting a room for the father must not mute it for the child, and archiving it
/// for one member must not hide it from the rest of the family. That is why the
/// table is keyed by (conversation, owner) and not by conversation alone.
abstract class ChatPreferencesRepository {
  /// The stored preferences, or null when this reader has never touched them —
  /// which is a different fact from "has defaults".
  Future<ChatPreference?> preferenceFor({
    required String conversationId,
    required String ownerKey,
  });

  Future<List<ChatPreference>> preferencesOf(String ownerKey);

  /// Mutes for a window. [preset] `null` means "دائمًا" ([kMuteForeverUntil]),
  /// `kMuteEightHours` and `kMuteOneWeek` are the other two WhatsApp presets.
  Future<ChatPreference> muteChat({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required Duration? preset,
    DateTime? at,
  });

  Future<ChatPreference> unmuteChat({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    DateTime? at,
  });

  Future<ChatPreference> setArchived({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required bool archived,
    DateTime? at,
  });

  Future<ChatPreference> setPinned({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required bool pinned,
    DateTime? at,
  });

  /// The look of this chat only: one wallpaper and one bubble theme, both from
  /// the reference's own sets. An unknown value is refused rather than rendered
  /// as a silent default.
  Future<ChatPreference> setLook({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required String wallpaper,
    required String bubbleTheme,
    DateTime? at,
  });
}

final class DriftChatPreferencesRepository
    implements ChatPreferencesRepository {
  DriftChatPreferencesRepository(this._db);

  final FamilyDatabase _db;

  @override
  Future<ChatPreference?> preferenceFor({
    required String conversationId,
    required String ownerKey,
  }) {
    return (_db.select(_db.chatPreferences)
          ..where(
            (t) =>
                t.conversationId.equals(conversationId) &
                t.ownerKey.equals(ownerKey),
          ))
        .getSingleOrNull();
  }

  @override
  Future<List<ChatPreference>> preferencesOf(String ownerKey) {
    return (_db.select(_db.chatPreferences)
          ..where((t) => t.ownerKey.equals(ownerKey)))
        .get();
  }

  @override
  Future<ChatPreference> muteChat({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required Duration? preset,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _ensure(
      conversationId: conversationId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      now: now,
    );
    return _apply(
      conversationId,
      ownerKey,
      ChatPreferencesCompanion(
        mutedUntil: Value(muteUntilFor(preset: preset, now: now)),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<ChatPreference> unmuteChat({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _ensure(
      conversationId: conversationId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      now: now,
    );
    // Nulling the window is the unmute — there is no second flag that could
    // disagree with it.
    return _apply(
      conversationId,
      ownerKey,
      ChatPreferencesCompanion(
        mutedUntil: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<ChatPreference> setArchived({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required bool archived,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _ensure(
      conversationId: conversationId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      now: now,
    );
    return _apply(
      conversationId,
      ownerKey,
      ChatPreferencesCompanion(
        archivedAt: Value(archived ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<ChatPreference> setPinned({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required bool pinned,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _ensure(
      conversationId: conversationId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      now: now,
    );
    return _apply(
      conversationId,
      ownerKey,
      ChatPreferencesCompanion(
        pinnedAt: Value(pinned ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<ChatPreference> setLook({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required String wallpaper,
    required String bubbleTheme,
    DateTime? at,
  }) async {
    requireWallpaper(wallpaper);
    requireBubbleTheme(bubbleTheme);

    final now = at ?? DateTime.now();
    await _ensure(
      conversationId: conversationId,
      ownerKey: ownerKey,
      ownerKind: ownerKind,
      now: now,
    );
    return _apply(
      conversationId,
      ownerKey,
      ChatPreferencesCompanion(
        wallpaper: Value(wallpaper),
        bubbleTheme: Value(bubbleTheme),
        updatedAt: Value(now),
      ),
    );
  }

  /// First touch creates the row; the identity is checked before it exists, so a
  /// bad `owner_kind` never reaches the table.
  Future<void> _ensure({
    required String conversationId,
    required String ownerKey,
    required String ownerKind,
    required DateTime now,
  }) async {
    requireOwnerKind(ownerKind);
    if (await preferenceFor(
          conversationId: conversationId,
          ownerKey: ownerKey,
        ) !=
        null) {
      return;
    }
    await _db.into(_db.chatPreferences).insert(
          ChatPreferencesCompanion.insert(
            conversationId: conversationId,
            ownerKind: ownerKind,
            ownerKey: ownerKey,
            updatedAt: Value(now),
          ),
        );
  }

  Future<ChatPreference> _apply(
    String conversationId,
    String ownerKey,
    ChatPreferencesCompanion patch,
  ) async {
    await (_db.update(_db.chatPreferences)
          ..where(
            (t) =>
                t.conversationId.equals(conversationId) &
                t.ownerKey.equals(ownerKey),
          ))
        .write(patch);
    final stored = await preferenceFor(
      conversationId: conversationId,
      ownerKey: ownerKey,
    );
    if (stored == null) {
      throw StateError('chat_preference $conversationId/$ownerKey لم تُكتب');
    }
    return stored;
  }
}
