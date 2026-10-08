import 'dart:convert';

import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The two room shapes the W9 contract makes distinct.
enum FamilyChatThreadKind {
  family('family'),
  child('child');

  const FamilyChatThreadKind(this.wireValue);

  final String wireValue;

  static FamilyChatThreadKind parse(Object? value) => switch (value) {
    'family' => FamilyChatThreadKind.family,
    'child' => FamilyChatThreadKind.child,
    _ => throw _invalidField('kind'),
  };
}

enum FamilyChatParticipantKind {
  membership('membership'),
  child('child');

  const FamilyChatParticipantKind(this.wireValue);

  final String wireValue;

  static FamilyChatParticipantKind parse(Object? value) => switch (value) {
    'membership' => FamilyChatParticipantKind.membership,
    'child' => FamilyChatParticipantKind.child,
    _ => throw _invalidField('participantKind'),
  };
}

/// A participant disclosed by the server. No account subject or device credential is returned.
final class FamilyChatParticipant {
  const FamilyChatParticipant({
    required this.kind,
    required this.id,
    required this.role,
    required this.displayName,
    required this.isSelf,
  });

  final FamilyChatParticipantKind kind;
  final String id;
  final String? role;
  final String? displayName;
  final bool isSelf;

  factory FamilyChatParticipant.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'participant');
    final kind = FamilyChatParticipantKind.parse(json['kind']);
    final role = FamilyChatApiClient._nullableString(json['role'], 'role');
    if (role != null &&
        !const <String>{'primary_guardian', 'co_guardian', 'child'}.contains(role)) {
      throw _invalidField('role');
    }
    return FamilyChatParticipant(
      kind: kind,
      id: FamilyChatApiClient._uuid(json['id'], 'id'),
      role: role,
      displayName: FamilyChatApiClient._nullableString(json['displayName'], 'displayName'),
      isSelf: FamilyChatApiClient._boolean(json['isSelf'], 'isSelf'),
    );
  }
}

/// One immutable server message. Deleted content stays absent while its sequence and trace stay.
final class FamilyChatMessage {
  const FamilyChatMessage({
    required this.id,
    required this.seq,
    required this.authorKind,
    required this.authorId,
    required this.body,
    required this.revision,
    required this.editedAt,
    required this.deleted,
    required this.deletedAt,
    required this.deletedByKind,
    required this.deletedById,
    required this.createdAt,
    required this.readCount,
  });

  final String id;
  final int seq;
  final FamilyChatParticipantKind authorKind;
  final String authorId;
  final String? body;
  final int revision;
  final DateTime? editedAt;
  final bool deleted;
  final DateTime? deletedAt;
  final FamilyChatParticipantKind? deletedByKind;
  final String? deletedById;
  final DateTime createdAt;
  final int readCount;

  factory FamilyChatMessage.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'message');
    final deleted = FamilyChatApiClient._boolean(json['deleted'], 'deleted');
    final body = FamilyChatApiClient._nullableString(json['body'], 'body');
    final deletedAt = FamilyChatApiClient._nullableInstant(json['deletedAt'], 'deletedAt');
    final deletedByKindValue = json['deletedByKind'];
    final deletedByKind = deletedByKindValue == null
        ? null
        : FamilyChatParticipantKind.parse(deletedByKindValue);
    final deletedById = FamilyChatApiClient._nullableString(json['deletedById'], 'deletedById');
    if (deleted != (body == null) ||
        deleted != (deletedAt != null) ||
        (deletedByKind == null) != (deletedById == null) ||
        (deleted && deletedByKind == null)) {
      throw _invalidField('deleted');
    }
    return FamilyChatMessage(
      id: FamilyChatApiClient._uuid(json['id'], 'id'),
      seq: FamilyChatApiClient._positiveInteger(json['seq'], 'seq'),
      authorKind: FamilyChatParticipantKind.parse(json['authorKind']),
      authorId: FamilyChatApiClient._uuid(json['authorId'], 'authorId'),
      body: body,
      revision: FamilyChatApiClient._positiveInteger(json['revision'], 'revision'),
      editedAt: FamilyChatApiClient._nullableInstant(json['editedAt'], 'editedAt'),
      deleted: deleted,
      deletedAt: deletedAt,
      deletedByKind: deletedByKind,
      deletedById: deletedById == null ? null : FamilyChatApiClient._uuid(deletedById, 'deletedById'),
      createdAt: FamilyChatApiClient._instant(json['createdAt'], 'createdAt'),
      readCount: FamilyChatApiClient._nonNegativeInteger(json['readCount'], 'readCount'),
    );
  }
}

/// The one read mark and the server-computed unread count for this caller.
final class FamilyChatReadState {
  const FamilyChatReadState({
    required this.threadId,
    required this.participantKind,
    required this.participantId,
    required this.lastReadSeq,
  });

  final String threadId;
  final FamilyChatParticipantKind participantKind;
  final String participantId;
  final int lastReadSeq;

  factory FamilyChatReadState.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'readState');
    return FamilyChatReadState(
      threadId: FamilyChatApiClient._uuid(json['threadId'], 'threadId'),
      participantKind: FamilyChatParticipantKind.parse(json['participantKind']),
      participantId: FamilyChatApiClient._uuid(json['participantId'], 'participantId'),
      lastReadSeq: FamilyChatApiClient._nonNegativeInteger(json['lastReadSeq'], 'lastReadSeq'),
    );
  }
}

/// One conversation and the participants the caller is allowed to know.
final class FamilyChatThread {
  const FamilyChatThread({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.lastReadSeq,
    required this.unreadCount,
    required this.participants,
    required this.lastMessage,
  });

  final String id;
  final FamilyChatThreadKind kind;
  final String title;
  final DateTime createdAt;
  final int lastReadSeq;
  final int unreadCount;
  final List<FamilyChatParticipant> participants;
  final FamilyChatMessage? lastMessage;

  factory FamilyChatThread.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'thread');
    final rawParticipants = json['participants'];
    if (rawParticipants is! List) throw _invalidField('participants');
    final rawLastMessage = json['lastMessage'];
    return FamilyChatThread(
      id: FamilyChatApiClient._uuid(json['id'], 'id'),
      kind: FamilyChatThreadKind.parse(json['kind']),
      title: FamilyChatApiClient._string(json['title'], 'title'),
      createdAt: FamilyChatApiClient._instant(json['createdAt'], 'createdAt'),
      lastReadSeq: FamilyChatApiClient._nonNegativeInteger(json['lastReadSeq'], 'lastReadSeq'),
      unreadCount: FamilyChatApiClient._nonNegativeInteger(json['unreadCount'], 'unreadCount'),
      participants: List<FamilyChatParticipant>.unmodifiable(
        rawParticipants.map(FamilyChatParticipant.fromJson),
      ),
      lastMessage: rawLastMessage == null
          ? null
          : FamilyChatMessage.fromJson(rawLastMessage),
    );
  }
}

final class FamilyChatThreadList {
  const FamilyChatThreadList({required this.threads});

  final List<FamilyChatThread> threads;

  factory FamilyChatThreadList.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'threadList');
    final threads = json['threads'];
    if (threads is! List || threads.length > 200) {
      throw _invalidField('threads');
    }
    return FamilyChatThreadList(
      threads: List<FamilyChatThread>.unmodifiable(
        threads.map(FamilyChatThread.fromJson),
      ),
    );
  }
}

final class FamilyChatMessagePage {
  const FamilyChatMessagePage({
    required this.messages,
    required this.readState,
    required this.hasMore,
  });

  final List<FamilyChatMessage> messages;
  final FamilyChatReadState readState;
  final bool hasMore;

  factory FamilyChatMessagePage.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'messagePage');
    final messages = json['messages'];
    if (messages is! List || messages.length > 200) {
      throw _invalidField('messages');
    }
    final parsed = messages.map(FamilyChatMessage.fromJson).toList(growable: false);
    for (var i = 1; i < parsed.length; i++) {
      if (parsed[i].seq <= parsed[i - 1].seq) throw _invalidField('messages.seq');
    }
    return FamilyChatMessagePage(
      messages: List<FamilyChatMessage>.unmodifiable(parsed),
      readState: FamilyChatReadState.fromJson(json['readState']),
      hasMore: FamilyChatApiClient._boolean(json['hasMore'], 'hasMore'),
    );
  }
}

final class FamilyChatSendResult {
  const FamilyChatSendResult({required this.message, required this.replayed});

  final FamilyChatMessage message;
  final bool replayed;

  factory FamilyChatSendResult.fromJson(Object? value) {
    final json = FamilyChatApiClient._object(value, 'sendResult');
    return FamilyChatSendResult(
      message: FamilyChatMessage.fromJson(json['message']),
      replayed: FamilyChatApiClient._boolean(json['replayed'], 'replayed'),
    );
  }
}

/// An allow-listed request for a device route. The native transport resolves the device
/// credential from its protected store; Dart never reads or logs that secret.
final class FamilyChatDeviceRequest {
  const FamilyChatDeviceRequest({
    required this.operation,
    required this.deviceId,
    this.threadId,
    this.messageId,
    this.queryParameters = const <String, String>{},
    this.body,
    this.idempotencyKey,
  });

  final String operation;
  final String deviceId;
  final String? threadId;
  final String? messageId;
  final Map<String, String> queryParameters;
  final String? body;
  final String? idempotencyKey;
}

abstract interface class FamilyChatDeviceTransport {
  /// Null means there is no paired device credential available to this build.
  Future<String?> configuredDeviceId();

  Future<FoundationGateHttpResponse> send(FamilyChatDeviceRequest request);
}

/// Typed client for the complete W9 HTTP contract: eight guardian operations and six paired-
/// device operations. The routes choose the author from the credential, never from a body.
final class FamilyChatApiClient {
  FamilyChatApiClient({
    required FoundationGateConfiguration configuration,
    required FoundationGateHttpTransport transport,
    FamilyChatDeviceTransport? deviceTransport,
  }) : _configuration = configuration,
       _transport = transport,
       _deviceTransport = deviceTransport;

  final FoundationGateConfiguration _configuration;
  final FoundationGateHttpTransport _transport;
  final FamilyChatDeviceTransport? _deviceTransport;

  bool get hasDeviceTransport => _deviceTransport != null;

  Future<String?> configuredDeviceId() async =>
      _deviceTransport?.configuredDeviceId();

  Future<FamilyChatThreadList> listFamilyThreads({
    required String familyId,
    required String idToken,
  }) async {
    final response = await _guardianRequest(
      'GET',
      _configuration.familyChatThreadsUri(familyId),
      idToken: idToken,
    );
    return FamilyChatThreadList.fromJson(
      _expect(response, successStatus: 200),
    );
  }

  Future<FamilyChatThread> createFamilyThread({
    required String familyId,
    required FamilyChatThreadKind kind,
    required List<String> childIds,
    required String idempotencyKey,
    required String idToken,
    String title = '',
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    _validateUuidList(childIds, 'childIds', max: 1);
    if ((kind == FamilyChatThreadKind.family && childIds.isNotEmpty) ||
        (kind == FamilyChatThreadKind.child && childIds.length != 1) ||
        title.trim().length > 120) {
      throw _invalidInput();
    }
    final body = <String, Object?>{
      'kind': kind.wireValue,
      if (title.trim().isNotEmpty) 'title': title.trim(),
      if (childIds.isNotEmpty) 'childIds': childIds,
    };
    final response = await _guardianRequest(
      'POST',
      _configuration.familyChatThreadsUri(familyId),
      idToken: idToken,
      idempotencyKey: idempotencyKey,
      body: body,
    );
    final json = _expect(response, successStatus: 201);
    return FamilyChatThread.fromJson(_object(json['thread'], 'thread'));
  }

  Future<FamilyChatThread> addFamilyThreadMember({
    required String familyId,
    required String threadId,
    required FamilyChatParticipantKind participantKind,
    required String participantId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    _validateUuid(participantId, 'participantId');
    final response = await _guardianRequest(
      'POST',
      _configuration.familyChatThreadMembersUri(familyId, threadId),
      idToken: idToken,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'participantKind': participantKind.wireValue,
        'participantId': participantId,
      },
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatThread.fromJson(_object(json['thread'], 'thread'));
  }

  Future<FamilyChatMessagePage> listFamilyMessages({
    required String familyId,
    required String threadId,
    required String idToken,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    final response = await _guardianRequest(
      'GET',
      _configuration.familyChatMessagesUri(
        familyId,
        threadId,
        afterSeq: afterSeq,
        limit: limit,
      ),
      idToken: idToken,
    );
    return FamilyChatMessagePage.fromJson(_expect(response, successStatus: 200));
  }

  Future<FamilyChatSendResult> sendFamilyMessage({
    required String familyId,
    required String threadId,
    required String body,
    required String clientMessageId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    _validateMessage(body, clientMessageId);
    _validateIdempotencyKey(idempotencyKey);
    final response = await _guardianRequest(
      'POST',
      _configuration.familyChatMessagesUri(familyId, threadId),
      idToken: idToken,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'body': body,
        'clientMessageId': clientMessageId,
      },
    );
    return FamilyChatSendResult.fromJson(
      _expect(response, successStatus: 201),
    );
  }

  Future<FamilyChatMessage> editFamilyMessage({
    required String familyId,
    required String threadId,
    required String messageId,
    required String body,
    required int revision,
    required String idToken,
  }) async {
    if (body.trim().isEmpty || body.trim().length > 2000 || revision < 1) {
      throw _invalidInput();
    }
    final response = await _guardianRequest(
      'PATCH',
      _configuration.familyChatMessageUri(familyId, threadId, messageId),
      idToken: idToken,
      body: <String, Object?>{'body': body, 'revision': revision},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatMessage.fromJson(_object(json['message'], 'message'));
  }

  Future<FamilyChatMessage> deleteFamilyMessage({
    required String familyId,
    required String threadId,
    required String messageId,
    required String idempotencyKey,
    required String idToken,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    final response = await _guardianRequest(
      'POST',
      _configuration.familyChatMessageDeletionUri(familyId, threadId, messageId),
      idToken: idToken,
      idempotencyKey: idempotencyKey,
      body: const <String, Object?>{},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatMessage.fromJson(_object(json['message'], 'message'));
  }

  Future<FamilyChatReadState> markFamilyThreadRead({
    required String familyId,
    required String threadId,
    required int readSeq,
    required String idempotencyKey,
    required String idToken,
  }) async {
    if (readSeq < 0) throw _invalidInput();
    _validateIdempotencyKey(idempotencyKey);
    final response = await _guardianRequest(
      'POST',
      _configuration.familyChatReadsUri(familyId, threadId),
      idToken: idToken,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'readSeq': readSeq},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatReadState.fromJson(_object(json['readState'], 'readState'));
  }

  Future<FamilyChatThreadList> listDeviceThreads({
    required String deviceId,
    String? deviceCredential,
  }) async {
    final response = await _deviceRequest(
      operation: 'listThreads',
      method: 'GET',
      uri: _configuration.deviceChatThreadsUri(deviceId),
      deviceId: deviceId,
      deviceCredential: deviceCredential,
    );
    return FamilyChatThreadList.fromJson(_expect(response, successStatus: 200));
  }

  Future<FamilyChatMessagePage> listDeviceMessages({
    required String deviceId,
    required String threadId,
    int afterSeq = 0,
    int limit = 50,
    String? deviceCredential,
  }) async {
    final response = await _deviceRequest(
      operation: 'listMessages',
      method: 'GET',
      uri: _configuration.deviceChatMessagesUri(
        deviceId,
        threadId,
        afterSeq: afterSeq,
        limit: limit,
      ),
      deviceId: deviceId,
      threadId: threadId,
      deviceCredential: deviceCredential,
    );
    return FamilyChatMessagePage.fromJson(_expect(response, successStatus: 200));
  }

  Future<FamilyChatSendResult> sendDeviceMessage({
    required String deviceId,
    required String threadId,
    required String body,
    required String clientMessageId,
    required String idempotencyKey,
    String? deviceCredential,
  }) async {
    _validateMessage(body, clientMessageId);
    _validateIdempotencyKey(idempotencyKey);
    final response = await _deviceRequest(
      operation: 'sendMessage',
      method: 'POST',
      uri: _configuration.deviceChatMessagesUri(deviceId, threadId),
      deviceId: deviceId,
      threadId: threadId,
      deviceCredential: deviceCredential,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'body': body,
        'clientMessageId': clientMessageId,
      },
    );
    return FamilyChatSendResult.fromJson(_expect(response, successStatus: 201));
  }

  Future<FamilyChatMessage> editDeviceMessage({
    required String deviceId,
    required String threadId,
    required String messageId,
    required String body,
    required int revision,
    String? deviceCredential,
  }) async {
    if (body.trim().isEmpty || body.trim().length > 2000 || revision < 1) {
      throw _invalidInput();
    }
    final response = await _deviceRequest(
      operation: 'editMessage',
      method: 'PATCH',
      uri: _configuration.deviceChatMessageUri(deviceId, threadId, messageId),
      deviceId: deviceId,
      threadId: threadId,
      messageId: messageId,
      deviceCredential: deviceCredential,
      body: <String, Object?>{'body': body, 'revision': revision},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatMessage.fromJson(_object(json['message'], 'message'));
  }

  Future<FamilyChatMessage> deleteDeviceMessage({
    required String deviceId,
    required String threadId,
    required String messageId,
    required String idempotencyKey,
    String? deviceCredential,
  }) async {
    _validateIdempotencyKey(idempotencyKey);
    final response = await _deviceRequest(
      operation: 'deleteMessage',
      method: 'POST',
      uri: _configuration.deviceChatMessageDeletionUri(deviceId, threadId, messageId),
      deviceId: deviceId,
      threadId: threadId,
      messageId: messageId,
      deviceCredential: deviceCredential,
      idempotencyKey: idempotencyKey,
      body: const <String, Object?>{},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatMessage.fromJson(_object(json['message'], 'message'));
  }

  Future<FamilyChatReadState> markDeviceThreadRead({
    required String deviceId,
    required String threadId,
    required int readSeq,
    required String idempotencyKey,
    String? deviceCredential,
  }) async {
    if (readSeq < 0) throw _invalidInput();
    _validateIdempotencyKey(idempotencyKey);
    final response = await _deviceRequest(
      operation: 'markRead',
      method: 'POST',
      uri: _configuration.deviceChatReadsUri(deviceId, threadId),
      deviceId: deviceId,
      threadId: threadId,
      deviceCredential: deviceCredential,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'readSeq': readSeq},
    );
    final json = _expect(response, successStatus: 200);
    return FamilyChatReadState.fromJson(_object(json['readState'], 'readState'));
  }

  Future<FoundationGateHttpResponse> _guardianRequest(
    String method,
    Uri uri, {
    required String idToken,
    String? idempotencyKey,
    Map<String, Object?>? body,
  }) {
    if (idToken.trim().isEmpty) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.unauthenticated,
      );
    }
    return _transportRequest(
      method,
      uri,
      headers: _headers(
        scheme: 'Bearer',
        credential: idToken,
        idempotencyKey: idempotencyKey,
      ),
      body: body,
    );
  }

  Future<FoundationGateHttpResponse> _deviceRequest({
    required String operation,
    required String method,
    required Uri uri,
    required String deviceId,
    String? threadId,
    String? messageId,
    String? deviceCredential,
    String? idempotencyKey,
    Map<String, Object?>? body,
  }) {
    if (deviceCredential != null) {
      if (!RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(deviceCredential)) {
        throw _invalidInput();
      }
      return _transportRequest(
        method,
        uri,
        headers: _headers(
          scheme: 'Device',
          credential: deviceCredential,
          idempotencyKey: idempotencyKey,
        ),
        body: body,
      );
    }
    final native = _deviceTransport;
    if (native == null) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
    return native
        .send(
          FamilyChatDeviceRequest(
            operation: operation,
            deviceId: deviceId,
            threadId: threadId,
            messageId: messageId,
            queryParameters: uri.queryParameters,
            body: body == null ? null : jsonEncode(body),
            idempotencyKey: idempotencyKey,
          ),
        )
        .catchError((Object _) => throw const FoundationGateApiException(
          FoundationGateApiFailure.networkUnavailable,
        ));
  }

  Future<FoundationGateHttpResponse> _transportRequest(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    Map<String, Object?>? body,
  }) async {
    try {
      final encoded = body == null ? null : jsonEncode(body);
      return switch (method) {
        'GET' => await _transport.get(uri, headers: headers),
        'POST' => await _transport.post(
          uri,
          headers: headers,
          body: encoded ?? '{}',
        ),
        'PATCH' => await _transport.patch(
          uri,
          headers: headers,
          body: encoded ?? '{}',
        ),
        _ => throw _invalidInput(),
      };
    } on FoundationGateApiException {
      rethrow;
    } on Object {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.networkUnavailable,
      );
    }
  }

  static Map<String, String> _headers({
    required String scheme,
    required String credential,
    String? idempotencyKey,
  }) => <String, String>{
    'authorization': '$scheme $credential',
    'accept': 'application/json',
    'content-type': 'application/json',
    if (idempotencyKey != null) 'idempotency-key': idempotencyKey,
  };

  static Object _expect(
    FoundationGateHttpResponse response, {
    required int successStatus,
  }) {
    if (response.statusCode != successStatus) throw _httpFailure(response);
    return _decode(response.body);
  }

  static FoundationGateApiException _httpFailure(
    FoundationGateHttpResponse response,
  ) {
    Map<String, Object?>? envelope;
    try {
      final value = jsonDecode(response.body);
      if (value is Map) {
        envelope = value.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      envelope = null;
    }
    final errorValue = envelope?['error'];
    final error = errorValue is Map
        ? errorValue.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};
    final detailsValue = error['details'];
    final details = detailsValue is Map
        ? detailsValue.map((key, value) => MapEntry(key.toString(), value))
        : null;
    final failure = switch (response.statusCode) {
      400 || 422 => FoundationGateApiFailure.invalidInput,
      401 => FoundationGateApiFailure.unauthenticated,
      403 => FoundationGateApiFailure.accessDenied,
      404 => FoundationGateApiFailure.notFound,
      409 => FoundationGateApiFailure.conflict,
      429 || 503 => FoundationGateApiFailure.serviceUnavailable,
      >= 500 => FoundationGateApiFailure.serviceUnavailable,
      _ => FoundationGateApiFailure.invalidResponse,
    };
    return FoundationGateApiException(
      failure,
      details: details,
      statusCode: response.statusCode,
      serverCode: error['code'] is String ? error['code']! as String : null,
      serverMessage: error['message'] is String
          ? error['message']! as String
          : null,
    );
  }

  static Map<String, Object?> _decode(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    if (decoded is! Map) {
      throw const FoundationGateApiException(
        FoundationGateApiFailure.invalidResponse,
      );
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map) throw _invalidField(field);
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _string(Object? value, String field) {
    if (value is! String) throw _invalidField(field);
    return value;
  }

  static String _uuid(Object? value, String field) {
    if (value is! String || !isFoundationGateUuid(value)) {
      throw _invalidField(field);
    }
    return value;
  }

  static String? _nullableString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) throw _invalidField(field);
    return value;
  }

  static int _integer(Object? value, String field) {
    if (value is! int) throw _invalidField(field);
    return value;
  }

  static int _positiveInteger(Object? value, String field) {
    final parsed = _integer(value, field);
    if (parsed < 1) throw _invalidField(field);
    return parsed;
  }

  static int _nonNegativeInteger(Object? value, String field) {
    final parsed = _integer(value, field);
    if (parsed < 0) throw _invalidField(field);
    return parsed;
  }

  static bool _boolean(Object? value, String field) {
    if (value is! bool) throw _invalidField(field);
    return value;
  }

  static DateTime _instant(Object? value, String field) {
    if (value is! String) throw _invalidField(field);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _invalidField(field);
    return parsed;
  }

  static DateTime? _nullableInstant(Object? value, String field) =>
      value == null ? null : _instant(value, field);

  static void _validateUuid(String value, String field) {
    if (!isFoundationGateUuid(value)) throw _invalidInput(field);
  }

  static void _validateUuidList(
    List<String> values,
    String field, {
    required int max,
  }) {
    if (values.length > max ||
        values.any((value) => !isFoundationGateUuid(value)) ||
        values.toSet().length != values.length) {
      throw _invalidInput(field);
    }
  }

  static void _validateMessage(String body, String clientMessageId) {
    if (body.trim().isEmpty ||
        body.trim().length > 2000 ||
        !RegExp(r'^[A-Za-z0-9_.:-]{8,64}$').hasMatch(clientMessageId)) {
      throw _invalidInput();
    }
  }

  static void _validateIdempotencyKey(String value) {
    if (value.trim().isEmpty || value.trim().length > 128) {
      throw _invalidInput('idempotencyKey');
    }
  }

  static FoundationGateApiException _invalidInput([String? field]) =>
      FoundationGateApiException(
        FoundationGateApiFailure.invalidInput,
        details: field == null ? null : <String, Object?>{'field': field},
      );
}

FoundationGateApiException _invalidField(String field) =>
    FoundationGateApiException(
      FoundationGateApiFailure.invalidResponse,
      details: <String, Object?>{'field': field},
    );
