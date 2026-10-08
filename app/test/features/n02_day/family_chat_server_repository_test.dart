import 'dart:collection';
import 'dart:convert';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/child_conversation_screen.dart';
import 'package:family_os/features/n02_day/conversation_screen.dart';
import 'package:family_os/features/n02_day/conversations_list_screen.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/features/n02_day/family_chat_server_repository.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _familyId = '11111111-1111-4111-8111-111111111111';
const _threadId = '22222222-2222-4222-8222-222222222222';
const _childId = '33333333-3333-4333-8333-333333333333';
const _membershipId = '44444444-4444-4444-8444-444444444444';
const _siblingId = '55555555-5555-4555-8555-555555555555';
const _deviceId = '77777777-7777-4777-8777-777777777777';
const _messageTime = '2026-10-08T08:30:00.000Z';

Map<String, Object?> _message(int seq, {String? body, int revision = 1}) =>
    <String, Object?>{
      'id': '00000000-0000-4000-8000-${seq.toString().padLeft(12, '0')}',
      'seq': seq,
      'authorKind': 'membership',
      'authorId': _membershipId,
      'body': body ?? 'Message $seq',
      'revision': revision,
      'editedAt': revision > 1 ? _messageTime : null,
      'deleted': false,
      'deletedAt': null,
      'deletedByKind': null,
      'deletedById': null,
      'createdAt': _messageTime,
      'readCount': 1,
    };

Map<String, Object?> _thread(
  int lastSeq, {
  String kind = 'child',
  String? title,
}) => <String, Object?>{
  'id': _threadId,
  'kind': kind,
  'title': title ?? (kind == 'family' ? 'Family' : 'Amani'),
  'createdAt': _messageTime,
  'lastReadSeq': 0,
  'unreadCount': lastSeq,
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
  'lastMessage': lastSeq == 0 ? null : _message(lastSeq),
};

Map<String, Object?> _childThread(int lastSeq, {String? title}) => <String, Object?>{
  ..._thread(lastSeq, kind: 'direct', title: title ?? ''),
  'participants': <Object?>[
    <String, Object?>{
      'kind': 'membership',
      'id': _membershipId,
      'role': 'primary_guardian',
      'displayName': 'Father',
      'isSelf': false,
    },
    <String, Object?>{
      'kind': 'child',
      'id': _childId,
      'role': 'child',
      'displayName': 'Amani',
      'isSelf': true,
    },
  ],
};

Map<String, Object?> _readState(int seq) => <String, Object?>{
  'threadId': _threadId,
  'participantKind': 'membership',
  'participantId': _membershipId,
  'lastReadSeq': seq,
};

Map<String, Object?> _childReadState(int seq) => <String, Object?>{
  'threadId': _threadId,
  'participantKind': 'child',
  'participantId': _childId,
  'lastReadSeq': seq,
};

Map<String, Object?> _capabilities() => <String, Object?>{
  'transport': 'polling',
  'listPollSeconds': 30,
  'threadPollSeconds': 15,
  'contentTypes': <String>['text/plain'],
  'attachments': false,
  'audio': false,
  'presence': false,
  'richReactions': false,
  'webSockets': false,
  'serverSentEvents': false,
};

FoundationGateHttpResponse _response(int status, Object body) =>
    FoundationGateHttpResponse(statusCode: status, body: jsonEncode(body));

class _RecordedCall {
  const _RecordedCall(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class _QueueTransport implements FoundationGateHttpTransport {
  final Queue<FoundationGateHttpResponse> responses =
      Queue<FoundationGateHttpResponse>();
  final List<_RecordedCall> calls = <_RecordedCall>[];

  Future<FoundationGateHttpResponse> _next(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    calls.add(_RecordedCall(method, uri, Map.unmodifiable(headers), body));
    if (responses.isEmpty) throw StateError('No response queued for $method.');
    return responses.removeFirst();
  }

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) =>
      _next('GET', uri, headers, null);

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _next('POST', uri, headers, body);

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _next('PATCH', uri, headers, body);

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) =>
      _next('PUT', uri, headers, body);
}

void main() {
  test('loads the latest bounded page, records reads, and polls edits/new messages by afterSeq', () async {
    var tokenNumber = 0;
    final transport = _QueueTransport();
    final initialMessages = List<Object?>.generate(50, (index) => _message(index + 31));
    final polledMessages = List<Object?>.generate(51, (index) {
      final seq = index + 31;
      return seq == 31
          ? _message(seq, body: 'Edited recently', revision: 2)
          : _message(seq);
    });
    transport.responses
      ..add(_response(200, <String, Object?>{
        'threads': [_thread(80)],
        'capabilities': _capabilities(),
      }))
      ..add(
        _response(200, <String, Object?>{
          'messages': initialMessages,
          'readState': _readState(20),
          'hasMore': true,
        }),
      )
      ..add(_response(200, <String, Object?>{'readState': _readState(80)}))
      ..add(
        _response(200, <String, Object?>{
          'messages': polledMessages,
          'readState': _readState(80),
          'hasMore': false,
        }),
      )
      ..add(_response(200, <String, Object?>{'readState': _readState(81)}));
    final api = FamilyChatApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: transport,
    );
    final authority = FamilyChatServerAuthority(
      api: api,
      idToken: () async => 'guardian-token-${++tokenNumber}',
      familyId: () => _familyId,
    );
    final repository = FamilyChatServerConversationRepository(
      authority: authority,
      surface: FamilyChatSurface.guardian,
    );

    final first = await repository.load(_threadId);
    expect(first, isNotNull);
    expect(first!.serverAuthoritative, isTrue);
    expect(first.messages, hasLength(50));
    expect(first.messages.first.seq, 31);
    expect(first.messages.last.seq, 80);
    expect(first.lastReadSeq, 80);
    expect(first.hasMoreMessages, isFalse);
    expect(transport.calls[1].uri.queryParameters, <String, String>{
      'afterSeq': '30',
      'limit': '50',
    });
    expect(jsonDecode(transport.calls[2].body!), <String, Object?>{'readSeq': 80});

    final refreshed = await repository.refresh(_threadId);
    expect(refreshed, isNotNull);
    expect(refreshed!.messages, hasLength(51));
    expect(
      refreshed.messages.firstWhere((message) => message.seq == 31).body,
      'Edited recently',
    );
    expect(refreshed.messages.last.seq, 81);
    expect(refreshed.lastReadSeq, 81);
    expect(transport.calls[3].uri.queryParameters, <String, String>{
      'afterSeq': '30',
      'limit': '100',
    });
    expect(transport.calls.map((call) => call.headers['authorization']), <String?>[
      'Bearer guardian-token-1',
      'Bearer guardian-token-2',
      'Bearer guardian-token-3',
      'Bearer guardian-token-4',
      'Bearer guardian-token-5',
    ]);
  });

  test('direct and group conversations send explicit peers without forcing guardians into them', () async {
    final transport = _QueueTransport();
    transport.responses
      ..add(_response(201, <String, Object?>{'thread': _thread(0, kind: 'direct')}))
      ..add(_response(201, <String, Object?>{'thread': _thread(0, kind: 'group')}));
    final authority = FamilyChatServerAuthority(
      api: FamilyChatApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'guardian-token',
      familyId: () => _familyId,
      childOptions: () async => FamilyChatAuthorityAnswer.ready(
        const <FamilyChatChildOption>[
          FamilyChatChildOption(id: _childId, displayName: 'Amani'),
        ],
      ),
    );
    final repository = FamilyChatThreadListRepository(
      authority: authority,
      surface: FamilyChatSurface.guardian,
    );

    await repository.createThread(
      kind: FamilyChatThreadKind.direct,
      title: '',
      participants: const <FamilyChatParticipantReference>[
        FamilyChatParticipantReference(kind: FamilyChatParticipantKind.child, id: _childId),
      ],
    );
    await repository.createThread(
      kind: FamilyChatThreadKind.group,
      title: 'Amani and sibling',
      participants: const <FamilyChatParticipantReference>[
        FamilyChatParticipantReference(kind: FamilyChatParticipantKind.child, id: _childId),
        FamilyChatParticipantReference(kind: FamilyChatParticipantKind.child, id: _siblingId),
      ],
    );

    expect(jsonDecode(transport.calls[0].body!), <String, Object?>{
      'kind': 'direct',
      'participants': <Object?>[
        <String, Object?>{'kind': 'child', 'id': _childId},
      ],
    });
    expect(jsonDecode(transport.calls[1].body!), <String, Object?>{
      'kind': 'group',
      'title': 'Amani and sibling',
      'participants': <Object?>[
        <String, Object?>{'kind': 'child', 'id': _childId},
        <String, Object?>{'kind': 'child', 'id': _siblingId},
      ],
    });
    expect(
      transport.calls.every((call) {
        final body = jsonDecode(call.body!) as Map<String, Object?>;
        return !body.containsKey('participantMembershipIds');
      }),
      isTrue,
    );
  });

  test('child roster loading distinguishes an empty server roster from a failed read', () async {
    FamilyChatAuthorityAnswer<List<FamilyChatChildOption>> rosterAnswer =
        const FamilyChatAuthorityAnswer<List<FamilyChatChildOption>>.ready(
          <FamilyChatChildOption>[],
        );
    final authority = FamilyChatServerAuthority(
      api: FamilyChatApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: _QueueTransport(),
      ),
      idToken: () async => 'guardian-token',
      familyId: () => _familyId,
      childOptions: () async => rosterAnswer,
    );
    final repository = FamilyChatThreadListRepository(
      authority: authority,
      surface: FamilyChatSurface.guardian,
    );

    expect(await repository.loadChildOptions(), isEmpty);
    rosterAnswer = const FamilyChatAuthorityAnswer<List<FamilyChatChildOption>>
        .unavailable(FamilyChatAuthorityStatus.unreachable);
    await expectLater(
      repository.loadChildOptions(),
      throwsA(
        isA<FamilyChatRepositoryFailure>().having(
          (error) => error.status,
          'status',
          FamilyChatAuthorityStatus.unreachable,
        ),
      ),
    );
  });

  testWidgets('new chat lets a guardian choose a direct peer or a group from the server roster', (
    tester,
  ) async {
    final siblingId = '55555555-5555-4555-8555-555555555555';
    final transport = _QueueTransport()
      ..responses.add(_response(200, <String, Object?>{
        'threads': <Object?>[],
        'capabilities': _capabilities(),
      }))
      ..responses.add(_response(200, <String, Object?>{
        'participants': <Object?>[
          <String, Object?>{
            'kind': 'membership',
            'id': _membershipId,
            'role': 'primary_guardian',
            'displayName': 'Father',
            'isSelf': true,
          },
          <String, Object?>{
            'kind': 'child',
            'id': _childId,
            'role': 'child',
            'displayName': 'Amani',
            'isSelf': false,
          },
          <String, Object?>{
            'kind': 'child',
            'id': siblingId,
            'role': 'child',
            'displayName': 'Bashir',
            'isSelf': false,
          },
        ],
      }));
    final authority = FamilyChatServerAuthority(
      api: FamilyChatApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'guardian-token',
      familyId: () => _familyId,
    );
    final repository = FamilyChatThreadListRepository(
      authority: authority,
      surface: FamilyChatSurface.guardian,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConversationsListScreen(
          repository: repository,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ConversationsListScreen)),
    );

    await tester.tap(find.byKey(ConversationsListKeys.newChatCta));
    await tester.pumpAndSettle();
    expect(find.byKey(ConversationsListKeys.createChatDialog), findsOneWidget);
    expect(find.byKey(ConversationsListKeys.createChatType), findsOneWidget);
    expect(find.text('Amani'), findsOneWidget);
    expect(find.text('Bashir'), findsOneWidget);
    expect(find.textContaining('guardian'), findsNothing);
    expect(
      tester.widget<FilledButton>(
        find.byKey(ConversationsListKeys.createChatConfirm),
      ).onPressed,
      isNull,
      reason: 'the server roster is required and a direct chat names exactly one peer',
    );

    await tester.tap(find.byKey(ConversationsListKeys.createChatType));
    await tester.pumpAndSettle();
    expect(find.text(l10n.familyChatDirectThread), findsWidgets);
    expect(find.text(l10n.familyChatGroupThread), findsOneWidget);
    await tester.tap(find.text(l10n.familyChatGroupThread));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('family_chat_participant_child:$_childId')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(ConversationsListKeys.createChatConfirm),
      ).onPressed,
      isNull,
      reason: 'a user-created group needs at least two selected peers',
    );
    await tester.tap(find.byKey(ValueKey('family_chat_participant_child:$siblingId')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(ConversationsListKeys.createChatConfirm),
      ).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(ConversationsListKeys.createChatType));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.familyChatDirectThread).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(ConversationsListKeys.createChatConfirm),
      ).onPressed,
      isNotNull,
      reason: 'switching back to direct keeps only one explicitly selected peer',
    );
    await tester.tap(find.text(l10n.familyChatCancel).last);
    await tester.pumpAndSettle();
  });

  testWidgets('server conversation states stored text honestly and disables unsupported media', (
    tester,
  ) async {
    final transport = _QueueTransport();
    transport.responses
      ..add(_response(200, <String, Object?>{
        'threads': [_thread(1)],
        'capabilities': _capabilities(),
      }))
      ..add(
        _response(200, <String, Object?>{
          'messages': [_message(1)],
          'readState': _readState(0),
          'hasMore': false,
        }),
      )
      ..add(_response(200, <String, Object?>{'readState': _readState(1)}))
      ..add(
        _response(200, <String, Object?>{
          'messages': [_message(1), _message(2)],
          'readState': _readState(1),
          'hasMore': false,
        }),
      )
      ..add(_response(200, <String, Object?>{'readState': _readState(2)}));
    final authority = FamilyChatServerAuthority(
      api: FamilyChatApiClient(
        configuration: FoundationGateConfiguration.fromStagingApiOrigin(
          Uri.parse('https://staging.example.test'),
        ),
        transport: transport,
      ),
      idToken: () async => 'guardian-token',
      familyId: () => _familyId,
    );
    final repository = FamilyChatServerConversationRepository(
      authority: authority,
      surface: FamilyChatSurface.guardian,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConversationScreen(
          chatWith: _threadId,
          repository: repository,
          roleOverride: AppRole.father,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ConversationKeys.serverStoredTag), findsOneWidget);
    expect(find.text('Server-stored text'), findsOneWidget);
    expect(find.byKey(ConversationKeys.encryptedTag), findsNothing);
    expect(find.byKey(ConversationKeys.mediaUnavailable), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(ConversationKeys.attach)).onPressed,
      isNull,
    );
    expect(find.text('Message 1'), findsOneWidget);
    expect(transport.calls, hasLength(3));

    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.text('Message 2'), findsOneWidget);
    expect(transport.calls, hasLength(5));
  });

  testWidgets('paired child thread uses native auth and makes text-only server storage clear', (
    tester,
  ) async {
    final deviceTransport = _QueueDeviceTransport();
    deviceTransport.responses
      ..add(
        _response(
          200,
          <String, Object?>{
            'threads': [_childThread(1, title: '')],
            'capabilities': _capabilities(),
          },
        ),
      )
      ..add(
        _response(200, <String, Object?>{
          'messages': [_message(1)],
          'readState': _childReadState(0),
          'hasMore': false,
        }),
      )
      ..add(
        _response(200, <String, Object?>{
          'readState': _childReadState(1),
        }),
      );
    final deviceApi = FamilyChatApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: _QueueTransport(),
      deviceTransport: deviceTransport,
    );
    final authority = FamilyChatServerAuthority(
      api: deviceApi,
      idToken: () async => throw StateError('child chat must not ask for a guardian token'),
      familyId: () => null,
    );
    final repository = FamilyChatServerConversationRepository(
      authority: authority,
      surface: FamilyChatSurface.child,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFamilyTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChildConversationScreen(
          chatWith: _threadId,
          repository: repository,
          roleOverride: AppRole.child,
          onSos: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ChildConversationKeys.body), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ChildConversationKeys.title)).data,
      'Father',
      reason: 'an untitled direct room uses its server-disclosed peer name',
    );
    expect(find.byKey(ChildConversationKeys.serverStorageNotice), findsOneWidget);
    expect(find.byKey(ChildConversationKeys.mediaUnavailable), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ChildConversationScreen)),
    );
    expect(
      find.byTooltip(l10n.familyChatMediaUnavailableSemantics),
      findsNWidgets(2),
    );
    expect(find.text('Message 1'), findsOneWidget);
    expect(find.text('primary_guardian'), findsNothing);
    expect(find.text(l10n.dayBoardGuardianFallback), findsOneWidget);
    expect(
      deviceTransport.requests.map((request) => request.operation),
      <String>['listThreads', 'listMessages', 'markRead'],
    );
  });

  test('device surface preserves native-only auth and does not ask Firebase for a family', () async {
    final reply = _response(200, <String, Object?>{
      'threads': <Object?>[],
      'capabilities': _capabilities(),
    });
    final requests = <FamilyChatDeviceRequest>[];
    final api = FamilyChatApiClient(
      configuration: FoundationGateConfiguration.fromStagingApiOrigin(
        Uri.parse('https://staging.example.test'),
      ),
      transport: _QueueTransport(),
      deviceTransport: _FakeDeviceTransport(reply, requests),
    );
    final authority = FamilyChatServerAuthority(
      api: api,
      idToken: () async => throw StateError('guardian token must not be asked for'),
      familyId: () => null,
    );
    final answer = await authority.listChildThreads();

    expect(answer.isReady, isTrue);
    expect(answer.value!.threads, isEmpty);
    expect(requests.single.operation, 'listThreads');
    expect(requests.single.deviceId, _deviceId);
    expect(requests.single.body, isNull);
  });
}

class _QueueDeviceTransport implements FamilyChatDeviceTransport {
  final Queue<FoundationGateHttpResponse> responses =
      Queue<FoundationGateHttpResponse>();
  final List<FamilyChatDeviceRequest> requests = <FamilyChatDeviceRequest>[];

  @override
  Future<String?> configuredDeviceId() async => _deviceId;

  @override
  Future<FoundationGateHttpResponse> send(FamilyChatDeviceRequest request) async {
    requests.add(request);
    if (responses.isEmpty) {
      throw StateError('No response queued for ${request.operation}.');
    }
    return responses.removeFirst();
  }
}

class _FakeDeviceTransport implements FamilyChatDeviceTransport {
  _FakeDeviceTransport(this.response, this.requests);

  final FoundationGateHttpResponse response;
  final List<FamilyChatDeviceRequest> requests;

  @override
  Future<String?> configuredDeviceId() async => _deviceId;

  @override
  Future<FoundationGateHttpResponse> send(FamilyChatDeviceRequest request) async {
    requests.add(request);
    return response;
  }
}
