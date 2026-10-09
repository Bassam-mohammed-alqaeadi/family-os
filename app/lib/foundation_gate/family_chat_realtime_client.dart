import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';

/// Where the hint channel stands, as the screen may describe it. `retrying` is the honest
/// degraded state: no hints are arriving, and the screen falls back to its polling interval.
enum FamilyChatRealtimeState { connecting, live, retrying, stopped }

/// A hint that a room changed. It holds no message text, names or media. A `resync` hint means
/// the socket could not say more (for example, the caller left the room), so the screen asks the
/// REST API, which is the only source of truth.
final class FamilyChatRealtimeHint {
  const FamilyChatRealtimeHint({
    required this.type,
    required this.threadId,
    this.seq,
  });

  final String type;
  final String threadId;
  final int? seq;

  static const Set<String> _types = <String>{'chat.message', 'chat.receipt', 'resync'};
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Reads one server frame. Acknowledgements (`ready`, `subscribed`, `pong`) return null, and so
  /// does anything malformed: a bad frame is ignored rather than trusted.
  static FamilyChatRealtimeHint? fromFrame(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final type = decoded['type'];
    final threadId = decoded['threadId'];
    if (type == 'error' && decoded['code'] == 'chat_thread_not_found' && threadId is String) {
      return _uuid.hasMatch(threadId)
          ? FamilyChatRealtimeHint(type: 'resync', threadId: threadId)
          : null;
    }
    if (type is! String || !_types.contains(type)) return null;
    if (threadId is! String || !_uuid.hasMatch(threadId)) return null;
    final seqValue = decoded['seq'];
    final seq = seqValue is int && seqValue >= 0 ? seqValue : null;
    return FamilyChatRealtimeHint(type: type, threadId: threadId, seq: seq);
  }
}

typedef FamilyChatSocketConnector = Future<WebSocket> Function(
  Uri uri,
  Map<String, dynamic> headers,
);

Future<WebSocket> _defaultConnector(Uri uri, Map<String, dynamic> headers) =>
    WebSocket.connect(uri.toString(), headers: headers).timeout(const Duration(seconds: 10));

/// The guardian's live hint channel for one open room.
///
/// It connects with the caller's credential on the upgrade, subscribes to the room being viewed,
/// and reconnects with capped exponential backoff. It never replays a missed hint: after any gap
/// the screen refetches from REST, so a reconnect cannot become a second source of truth.
final class FamilyChatRealtimeClient {
  FamilyChatRealtimeClient({
    required FoundationGateConfiguration configuration,
    required Future<String> Function() bearer,
    FamilyChatSocketConnector? connector,
    this.maxBackoff = const Duration(seconds: 60),
  }) : _uri = configuration.chatRealtimeUri,
       _bearer = bearer,
       _connector = connector ?? _defaultConnector;

  final Uri _uri;
  final Future<String> Function() _bearer;
  final FamilyChatSocketConnector _connector;
  final Duration maxBackoff;

  final StreamController<FamilyChatRealtimeHint> _hints =
      StreamController<FamilyChatRealtimeHint>.broadcast();
  final StreamController<FamilyChatRealtimeState> _states =
      StreamController<FamilyChatRealtimeState>.broadcast();

  FamilyChatRealtimeState _state = FamilyChatRealtimeState.stopped;
  WebSocket? _socket;
  String? _watchedThreadId;
  String? _watchedFamilyId;
  Timer? _retryTimer;
  int _failures = 0;
  bool _running = false;

  Stream<FamilyChatRealtimeHint> get hints => _hints.stream;
  Stream<FamilyChatRealtimeState> get states => _states.stream;
  FamilyChatRealtimeState get state => _state;

  /// Starts (or re-targets) the channel on one room. The server needs the family too, because a
  /// person may belong to several. Calling it again only changes the room.
  Future<void> watch({required String familyId, required String threadId}) async {
    _watchedFamilyId = familyId;
    _watchedThreadId = threadId;
    if (!_running) {
      _running = true;
      await _connect();
    } else if (_state == FamilyChatRealtimeState.live) {
      _subscribe();
    }
  }

  void _subscribe() {
    final threadId = _watchedThreadId;
    final familyId = _watchedFamilyId;
    if (threadId == null || familyId == null) return;
    _send(<String, Object?>{'type': 'subscribe', 'threadId': threadId, 'familyId': familyId});
  }

  Future<void> _connect() async {
    if (!_running) return;
    _setState(FamilyChatRealtimeState.connecting);
    try {
      final token = (await _bearer()).trim();
      if (token.isEmpty) throw StateError('no credential');
      final socket = await _connector(_uri, <String, dynamic>{'authorization': 'Bearer $token'});
      if (!_running) {
        await socket.close();
        return;
      }
      _socket = socket;
      _failures = 0;
      _setState(FamilyChatRealtimeState.live);
      socket.listen(
        _onFrame,
        onDone: _onLost,
        onError: (Object _) => _onLost(),
        cancelOnError: true,
      );
      _subscribe();
    } on Object {
      _scheduleRetry();
    }
  }

  void _onFrame(Object? data) {
    if (data is! String) return;
    final hint = FamilyChatRealtimeHint.fromFrame(data);
    if (hint != null && !_hints.isClosed) _hints.add(hint);
  }

  void _onLost() {
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close().catchError((Object _) {}));
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_running) return;
    _socket = null;
    _setState(FamilyChatRealtimeState.retrying);
    _failures += 1;
    // 1s, 2s, 4s ... capped. A socket that keeps refusing must not be hammered.
    final exponent = _failures - 1 > 6 ? 6 : _failures - 1;
    final seconds = 1 << exponent;
    final delay = Duration(seconds: seconds);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay > maxBackoff ? maxBackoff : delay, () => unawaited(_connect()));
  }

  void _send(Map<String, Object?> frame) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.add(jsonEncode(frame));
    } on Object {
      _onLost();
    }
  }

  void _setState(FamilyChatRealtimeState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  Future<void> stop() async {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    final socket = _socket;
    _socket = null;
    await socket?.close();
    _setState(FamilyChatRealtimeState.stopped);
  }

  Future<void> dispose() async {
    await stop();
    await _hints.close();
    await _states.close();
  }
}
