import 'dart:convert';
import 'dart:typed_data';

import 'package:family_os/core/crypto/sha256.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/family_chat_media_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _family = '11111111-1111-4111-8111-111111111111';
const _thread = '22222222-2222-4222-8222-222222222222';
const _mediaId = '33333333-3333-4333-8333-333333333333';
const _clientMediaId = 'client-media-0001';

FoundationGateConfiguration _config() =>
    FoundationGateConfiguration.fromStagingApiOrigin(Uri.parse('https://api.example.test'));

Map<String, Object?> _mediaJson({
  required String sha256,
  required int byteSize,
  String mimeType = 'image/jpeg',
}) => <String, Object?>{
  'id': _mediaId,
  'kind': 'image',
  'mimeType': mimeType,
  'byteSize': byteSize,
  'durationMs': null,
  'sha256': sha256,
  'status': 'available',
  'contentPath': '/v1/families/$_family/chat/threads/$_thread/media/$_mediaId/content',
};

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  final photo = Uint8List.fromList(utf8.encode('a small photo, byte for byte'));
  final photoDigest = sha256Hex(photo);

  group('upload', () {
    test('posts the raw bytes with the declared type and returns the stored item', () async {
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/families/$_family/chat/threads/$_thread/media');
          expect(request.url.queryParameters['clientMediaId'], _clientMediaId);
          expect(request.url.queryParameters.containsKey('durationMs'), isFalse);
          expect(request.headers['content-type'], 'image/jpeg');
          expect(request.headers['authorization'], 'Bearer token-123');
          expect(request.bodyBytes, photo);
          return _json({'media': _mediaJson(sha256: photoDigest, byteSize: photo.length)}, 201);
        }),
      );

      final media = await client.uploadGuardianMedia(
        familyId: _family,
        threadId: _thread,
        clientMediaId: _clientMediaId,
        contentType: 'image/jpeg',
        bytes: photo,
        idToken: 'token-123',
      );

      expect(media.id, _mediaId);
      expect(media.sha256, photoDigest);
      expect(media.isAvailable, isTrue);
    });

    test('a voice note carries its declared length in the query', () async {
      final audio = Uint8List.fromList(List<int>.filled(64, 7));
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          expect(request.url.queryParameters['durationMs'], '4200');
          expect(request.headers['content-type'], 'audio/mp4');
          final json = _mediaJson(sha256: sha256Hex(audio), byteSize: audio.length, mimeType: 'audio/mp4')
            ..['kind'] = 'audio'
            ..['durationMs'] = 4200;
          return _json({'media': json}, 201);
        }),
      );

      final media = await client.uploadGuardianMedia(
        familyId: _family,
        threadId: _thread,
        clientMediaId: _clientMediaId,
        contentType: 'audio/mp4',
        bytes: audio,
        durationMs: 4200,
        idToken: 'token-123',
      );
      expect(media.durationMs, 4200);
    });

    test('refuses an answer whose digest is not the digest of the bytes sent', () async {
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          final other = sha256Hex(utf8.encode('different bytes'));
          return _json({'media': _mediaJson(sha256: other, byteSize: photo.length)}, 201);
        }),
      );

      await expectLater(
        client.uploadGuardianMedia(
          familyId: _family,
          threadId: _thread,
          clientMediaId: _clientMediaId,
          contentType: 'image/jpeg',
          bytes: photo,
          idToken: 'token-123',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.invalidResponse,
          ),
        ),
      );
    });

    test('invalid input never reaches the network', () async {
      var calls = 0;
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          calls++;
          return _json({}, 500);
        }),
      );

      await expectLater(
        client.uploadGuardianMedia(
          familyId: _family,
          threadId: _thread,
          clientMediaId: _clientMediaId,
          contentType: 'audio/mp4',
          bytes: photo,
          durationMs: FamilyChatMediaClient.maxVoiceNoteMs + 1,
          idToken: 'token-123',
        ),
        throwsA(isA<FoundationGateApiException>()),
      );
      expect(calls, 0);
    });
  });

  group('download', () {
    FamilyChatMedia media({required String sha256}) => FamilyChatMedia(
      id: _mediaId,
      kind: FamilyChatMessageKind.image,
      mimeType: 'image/jpeg',
      byteSize: photo.length,
      durationMs: null,
      sha256: sha256,
      removed: false,
      contentPath: '/v1/families/$_family/chat/threads/$_thread/media/$_mediaId/content',
    );

    test('returns bytes whose recomputed digest matches the recorded one', () async {
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer token-123');
          return http.Response.bytes(photo, 200, headers: {'content-type': 'image/jpeg'});
        }),
      );

      final bytes = await client.fetchGuardianMedia(
        familyId: _family,
        threadId: _thread,
        media: media(sha256: photoDigest),
        idToken: 'token-123',
      );
      expect(bytes, photo);
    });

    test('refuses bytes that have the declared length but a different digest', () async {
      final tampered = Uint8List.fromList(List<int>.from(photo)..[0] ^= 0x01);
      final client = FamilyChatMediaClient(
        configuration: _config(),
        client: MockClient((request) async {
          return http.Response.bytes(tampered, 200, headers: {'content-type': 'image/jpeg'});
        }),
      );

      await expectLater(
        client.fetchGuardianMedia(
          familyId: _family,
          threadId: _thread,
          media: media(sha256: photoDigest),
          idToken: 'token-123',
        ),
        throwsA(
          isA<FoundationGateApiException>().having(
            (error) => error.failure,
            'failure',
            FoundationGateApiFailure.invalidResponse,
          ),
        ),
      );
    });
  });
}
