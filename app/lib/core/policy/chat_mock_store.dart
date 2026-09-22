import 'package:flutter/foundation.dart';

/// Stage-1 mock chat messages — **must survive** Advisor forget (SET-013 / R10).
@immutable
final class ChatMockMessage {
  const ChatMockMessage({
    required this.id,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String body;
  final DateTime createdAt;
}

/// Separate chat store so forget cannot accidentally clear conversations.
abstract class ChatMockStore {
  List<ChatMockMessage> get messages;

  Future<void> add(ChatMockMessage message);

  Future<void> clear();
}

final class MemoryChatMockStore implements ChatMockStore {
  MemoryChatMockStore([List<ChatMockMessage>? seed])
      : _messages = List<ChatMockMessage>.from(seed ?? const []);

  final List<ChatMockMessage> _messages;

  @override
  List<ChatMockMessage> get messages => List.unmodifiable(_messages);

  @override
  Future<void> add(ChatMockMessage message) async {
    _messages.add(message);
  }

  @override
  Future<void> clear() async {
    _messages.clear();
  }
}

/// Stage-1 shared chat mock (survives within process).
final MemoryChatMockStore stage1ChatMockStore = MemoryChatMockStore();
