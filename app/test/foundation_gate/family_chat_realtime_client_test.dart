import 'package:family_os/foundation_gate/family_chat_realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

const _thread = '11111111-1111-4111-8111-111111111111';

void main() {
  group('FamilyChatRealtimeHint.fromFrame', () {
    test('reads a message hint and keeps only the seq', () {
      final hint = FamilyChatRealtimeHint.fromFrame(
        '{"type":"chat.message","threadId":"$_thread","seq":7}',
      );
      expect(hint?.type, 'chat.message');
      expect(hint?.threadId, _thread);
      expect(hint?.seq, 7);
    });

    test('turns a vanished room into a resync, not a silent drop', () {
      final hint = FamilyChatRealtimeHint.fromFrame(
        '{"type":"error","code":"chat_thread_not_found","threadId":"$_thread"}',
      );
      expect(hint?.type, 'resync');
    });

    test('ignores acknowledgements, unknown types and malformed frames', () {
      expect(FamilyChatRealtimeHint.fromFrame('{"type":"ready"}'), isNull);
      expect(FamilyChatRealtimeHint.fromFrame('{"type":"pong"}'), isNull);
      expect(
        FamilyChatRealtimeHint.fromFrame('{"type":"chat.text","threadId":"$_thread"}'),
        isNull,
      );
      expect(
        FamilyChatRealtimeHint.fromFrame('{"type":"chat.message","threadId":"not-a-uuid"}'),
        isNull,
      );
      expect(FamilyChatRealtimeHint.fromFrame('not json'), isNull);
      expect(FamilyChatRealtimeHint.fromFrame('[]'), isNull);
    });

    test('drops a negative or non-integer seq rather than trusting it', () {
      final hint = FamilyChatRealtimeHint.fromFrame(
        '{"type":"chat.receipt","threadId":"$_thread","seq":-1}',
      );
      expect(hint?.type, 'chat.receipt');
      expect(hint?.seq, isNull);
    });
  });
}
