import 'dart:collection';
import 'dart:convert';

import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _threadId = '22222222-2222-4222-8222-222222222222';
const _childId = '33333333-3333-4333-8333-333333333333';
const _membershipId = '44444444-4444-4444-8444-444444444444';
const _otherMembershipId = '55555555-5555-4555-8555-555555555555';
const _messageId = '66666666-6666-4666-8666-666666666666';
const _deviceId = '77777777-7777-4777-8777-777777777777';
const _idempotencyKey = '88888888-8888-4888-8888-888888888888';
const _clientMessageId = 'client-message-0001';
const _createdAt = '2026-10-08T08:30:00.000Z';

Map<String, Object?> _message({
  int seq = 1,
  String? body = 'Hello family',
  int revision = 1,
  bool deleted = false,
  String? editedAt,
  String? deletedAt,
  String? deletedByKind,
  String? deletedById,
}) => <String, Object?>{
  'id': _messageId,
  'seq': seq,
  'authorKind': 'membership',
  'authorId': _membershipId,
  'body': body,
  'revision': revision,
  'editedAt': editedAt,
  'deleted': deleted,
  'deletedAt': deletedAt,
  'deletedByKind': deletedByKind,
  'deletedById': deletedById,
  'createdAt': _createdAt,
  'readCount': 1,
};

Map<String, Object?> _thread() => <String, Object?>{
  'id': _threadId,
  'kind': 'direct',
  'title': 'Family chat',
  'createdAt': _createdAt,
  'lastReadSeq': 0,
  'unreadCount': 1,
  'participants': <Object?>[
    <String, Object?>{
      'kind': 'membership',
      'id': _membershipId,
      'role': 'primary_guardian',
      'displayName': null,
      'isSelf': true,
    },
    <String, Object?>{
      'kind': 'child',
      'id': _childId,
      'role': 'child',
      'displayName': 'Amani',
      'isSelf': false,
    },
  ],
  'lastMessage': _message(),
};

Map<String, Object?> _page() => <String, Object?>{
  'messages': <Object?>[_message()],
  'readState': _readState(),
  'hasMore': false,
};

Map<String, Object?> _readState({int seq = 1}) => <String, Object?>{
  'threadId': _threadId,
  'participantKind': 'membership',
  'participantId': _membershipId,
  'lastReadSeq': seq,
};

FoundationGateHttpResponse _response(int status, Object value) =>
    FoundationGateHttpResponse(
      statusCode: status,
      body: jsonEncode(value),
    );

class _HttpCall {
  const _HttpCall(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class _RecordingHttpTransport implements FoundationGateHttpTransport {
  final Queue<FoundationGateHttpResponse> _responses =
      Queue<FoundationGateHttpResponse>();
  final Queue<Object> _postFailures = Queue<Object>();
  final List<_HttpCall> calls = <_HttpCall>[];

  void addResponse(FoundationGateHttpResponse response) =>
      _responses.addLast(response);

  void failNextPost(Object failure) => _postFailures.addLast(failure);

  Future<FoundationGateHttpResponse> _record(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    calls.add(_HttpCall(method, uri, Map.unmodifiable(headers), body));
    if (method == 'POST' && _postFailures.isNotEmpty) {
      throw _postFailures.removeFirst();
    }
    if (_responses.isEmpty) {
      throw StateError('No fake response queued for $method $uri');
    }
    return _responses.removeFirst();
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) =>
      _record('GET', uri, headers, null);

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _record('POST', uri, headers, body);

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _record('PATCH', uri, headers, body);

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _record('PUT', uri, headers, body);
}

class _RecordingDeviceTransport implements FamilyChatDeviceTransport {
  _RecordingDeviceTransport(this.responses);

  final Queue<FoundationGateHttpResponse> responses;
  final List<FamilyChatDeviceRequest> requests = <FamilyChatDeviceRequest>[];
  String? id = _deviceId;

  @override
  Future<String?> configuredDeviceId() async => id;

  @override
  Future<FoundationGateHttpResponse> send(FamilyChatDeviceRequest request) async {
    requests.add(request);
    if (responses.isEmpty) throw StateError('No fake native chat response queued.');
    return responses.removeFirst();
  }
}

void main() {
  FamilyChatApiClient guardianClient(_RecordingHttpTransport transport) =>
      FamilyChatApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      );

  test('all eight guardian operations match the typed W9 contract', () async {
    final http = _RecordingHttpTransport();
    final client = guardianClient(http);
    final thread = _thread();
    final msg = _message();
    final edited = _message(revision: 2, editedAt: _createdAt);
    final deleted = _message(
      body: null,
      deleted: true,
      deletedAt: _createdAt,
      deletedByKind: 'membership',
      deletedById: _membershipId,
    );

    http
      ..addResponse(_response(200, <String, Object?>{'threads': [thread]}))
      ..addResponse(_response(201, <String, Object?>{'thread': thread}))
      ..addResponse(_response(200, <String, Object?>{'thread': thread}))
      ..addResponse(_response(200, _page()))
      ..addResponse(
        _response(201, <String, Object?>{
          'message': msg,
          'replayed': false,
        }),
      )
      ..addResponse(_response(200, <String, Object?>{'message': edited}))
      ..addResponse(_response(200, <String, Object?>{'message': deleted}))
      ..addResponse(_response(200, <String, Object?>{'readState': _readState()}));

    expect(
      (await client.listFamilyThreads(
        familyId: _familyId,
        idToken: 'fresh-token-1',
      )).threads.single.id,
      _threadId,
    );
    expect(
      (await client.createFamilyThread(
        familyId: _familyId,
        kind: FamilyChatThreadKind.direct,
        participants: const <FamilyChatParticipantReference>[
          FamilyChatParticipantReference(kind: FamilyChatParticipantKind.child, id: _childId),
        ],
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token-2',
      )).id,
      _threadId,
    );
    expect(
      (await client.addFamilyThreadMember(
        familyId: _familyId,
        threadId: _threadId,
        participantKind: FamilyChatParticipantKind.membership,
        participantId: _otherMembershipId,
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token-3',
      )).participants,
      hasLength(2),
    );
    expect(
      (await client.listFamilyMessages(
        familyId: _familyId,
        threadId: _threadId,
        idToken: 'fresh-token-4',
        afterSeq: 7,
        limit: 25,
      )).messages.single.seq,
      1,
    );
    expect(
      (await client.sendFamilyMessage(
        familyId: _familyId,
        threadId: _threadId,
        body: 'Hello family',
        clientMessageId: _clientMessageId,
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token-5',
      )).replayed,
      isFalse,
    );
    expect(
      (await client.editFamilyMessage(
        familyId: _familyId,
        threadId: _threadId,
        messageId: _messageId,
        body: 'Edited text',
        revision: 1,
        idToken: 'fresh-token-6',
      )).revision,
      2,
    );
    expect(
      (await client.deleteFamilyMessage(
        familyId: _familyId,
        threadId: _threadId,
        messageId: _messageId,
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token-7',
      )).deleted,
      isTrue,
    );
    expect(
      (await client.markFamilyThreadRead(
        familyId: _familyId,
        threadId: _threadId,
        readSeq: 1,
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token-8',
      )).lastReadSeq,
      1,
    );

    expect(http.calls, hasLength(8));
    expect(http.calls.map((call) => call.method).toList(), <String>[
      'GET',
      'POST',
      'POST',
      'GET',
      'POST',
      'PATCH',
      'POST',
      'POST',
    ]);
    expect(http.calls[0].uri.path, '/v1/families/$_familyId/chat/threads');
    expect(http.calls[1].headers['idempotency-key'], _idempotencyKey);
    expect(jsonDecode(http.calls[1].body!), <String, Object?>{
      'kind': 'direct',
      'participants': <Object?>[
        <String, Object?>{'kind': 'child', 'id': _childId},
      ],
    });
    expect(http.calls[3].uri.queryParameters, <String, String>{
      'afterSeq': '7',
      'limit': '25',
    });
    expect(http.calls[4].headers['authorization'], 'Bearer fresh-token-5');
    expect(http.calls[4].headers['idempotency-key'], _idempotencyKey);
    expect(jsonDecode(http.calls[4].body!), <String, Object?>{
      'body': 'Hello family',
      'clientMessageId': _clientMessageId,
    });
    expect(jsonDecode(http.calls[5].body!), <String, Object?>{
      'body': 'Edited text',
      'revision': 1,
    });
  });

  test('all six paired-device operations use native transport without exposing a secret', () async {
    final replies = Queue<FoundationGateHttpResponse>()
      ..add(_response(200, <String, Object?>{'threads': [_thread()]}))
      ..add(_response(200, _page()))
      ..add(
        _response(201, <String, Object?>{
          'message': _message(),
          'replayed': true,
        }),
      )
      ..add(_response(200, <String, Object?>{'message': _message(revision: 2)}))
      ..add(
        _response(
          200,
          <String, Object?>{
            'message': _message(
              body: null,
              deleted: true,
              deletedAt: _createdAt,
              deletedByKind: 'child',
              deletedById: _childId,
            ),
          },
        ),
      )
      ..add(
        _response(
          200,
          <String, Object?>{
            'readState': <String, Object?>{
              'threadId': _threadId,
              'participantKind': 'child',
              'participantId': _childId,
              'lastReadSeq': 1,
            },
          },
        ),
      );
    final native = _RecordingDeviceTransport(replies);
    final client = FamilyChatApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: _RecordingHttpTransport(),
      deviceTransport: native,
    );

    await client.listDeviceThreads(deviceId: _deviceId);
    await client.listDeviceMessages(deviceId: _deviceId, threadId: _threadId);
    await client.sendDeviceMessage(
      deviceId: _deviceId,
      threadId: _threadId,
      body: 'Hello family',
      clientMessageId: _clientMessageId,
      idempotencyKey: _idempotencyKey,
    );
    await client.editDeviceMessage(
      deviceId: _deviceId,
      threadId: _threadId,
      messageId: _messageId,
      body: 'Edited text',
      revision: 1,
    );
    await client.deleteDeviceMessage(
      deviceId: _deviceId,
      threadId: _threadId,
      messageId: _messageId,
      idempotencyKey: _idempotencyKey,
    );
    final receipt = await client.markDeviceThreadRead(
      deviceId: _deviceId,
      threadId: _threadId,
      readSeq: 1,
      idempotencyKey: _idempotencyKey,
    );

    expect(receipt.participantId, _childId);
    expect(native.requests.map((request) => request.operation), <String>[
      'listThreads',
      'listMessages',
      'sendMessage',
      'editMessage',
      'deleteMessage',
      'markRead',
    ]);
    expect(native.requests.every((request) => request.deviceId == _deviceId), isTrue);
    expect(native.requests[1].queryParameters, <String, String>{
      'afterSeq': '0',
      'limit': '50',
    });
    expect(native.requests[2].body, jsonEncode(<String, Object?>{
      'body': 'Hello family',
      'clientMessageId': _clientMessageId,
    }));
    expect(native.requests[2].idempotencyKey, _idempotencyKey);
    expect(native.requests.every((request) => request.body?.contains('credential') != true), isTrue);
  });

  test('client rejects malformed success bodies and impossible deleted null combinations', () async {
    final http = _RecordingHttpTransport()
      ..addResponse(
        _response(200, <String, Object?>{
          'threads': <Object?>[
            <String, Object?>{
              ..._thread(),
              'lastMessage': <String, Object?>{
                ..._message(),
                'deleted': true,
                'deletedAt': _createdAt,
              },
            },
          ],
        }),
      );
    final client = guardianClient(http);
    await expectLater(
      client.listFamilyThreads(familyId: _familyId, idToken: 'fresh-token'),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('bad request arguments are refused before a transport call', () async {
    final http = _RecordingHttpTransport();
    final client = guardianClient(http);
    await expectLater(
      client.sendFamilyMessage(
        familyId: _familyId,
        threadId: _threadId,
        body: '  ',
        clientMessageId: _clientMessageId,
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    await expectLater(
      client.createFamilyThread(
        familyId: _familyId,
        kind: FamilyChatThreadKind.direct,
        participants: const <FamilyChatParticipantReference>[
          FamilyChatParticipantReference(kind: FamilyChatParticipantKind.child, id: _childId),
          FamilyChatParticipantReference(kind: FamilyChatParticipantKind.membership, id: _otherMembershipId),
        ],
        idempotencyKey: _idempotencyKey,
        idToken: 'fresh-token',
      ),
      throwsA(
        isA<FoundationGateApiException>().having(
          (error) => error.failure,
          'failure',
          FoundationGateApiFailure.invalidInput,
        ),
      ),
    );
    expect(http.calls, isEmpty);
  });

  test('a missing native transport refuses the child surface instead of falling back', () async {
    final client = guardianClient(_RecordingHttpTransport());
    await expectLater(
      client.listDeviceThreads(deviceId: _deviceId),
      throwsA(isA<FoundationGateApiException>()),
    );
  });
}
