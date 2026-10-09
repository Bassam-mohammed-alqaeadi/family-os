import 'dart:typed_data';

import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:http/http.dart' as http;

/// Fetches the bytes of one media item for a guardian who is in the room.
///
/// The transport elsewhere carries text only, so media uses its own small client. The server's
/// rules still apply in full: the caller's credential is sent, the room is checked on every
/// request, and a removed or unjoined item answers 404 and is shown as unavailable.
///
/// Integrity is checked against what the server declared (exact byte length and MIME type). The
/// SHA-256 the server records is not recomputed here, because this package set does not include
/// a hash implementation; the TLS connection and the server's own check stand in for it.
final class FamilyChatMediaClient {
  FamilyChatMediaClient({
    required FoundationGateConfiguration configuration,
    http.Client? client,
  }) : _configuration = configuration,
       _client = client ?? http.Client();

  final FoundationGateConfiguration _configuration;
  final http.Client _client;

  /// The path the server issued for this item. It must name the same family, room and item the
  /// caller asked for; a path that does not is refused, so a screen can never be steered into
  /// another room's bytes by a malformed response.
  static final RegExp _contentPath = RegExp(
    r'^/v1/families/([0-9a-f-]{36})/chat/threads/([0-9a-f-]{36})/media/([0-9a-f-]{36})/content$',
    caseSensitive: false,
  );

  Future<Uint8List> fetchGuardianMedia({
    required String familyId,
    required String threadId,
    required FamilyChatMedia media,
    required String idToken,
  }) async {
    final path = media.contentPath;
    if (media.removed || path == null) {
      throw const FoundationGateApiException(FoundationGateApiFailure.notFound);
    }
    final match = _contentPath.firstMatch(path);
    if (match == null ||
        match.group(1) != familyId ||
        match.group(2) != threadId ||
        match.group(3) != media.id) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    if (idToken.trim().isEmpty) {
      throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
    }

    final http.Response response;
    try {
      response = await _client.get(
        _configuration.stagingApiOrigin.replace(path: path),
        headers: <String, String>{
          'authorization': 'Bearer $idToken',
          'accept': '*/*',
        },
      );
    } on Object {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }
    if (response.statusCode != 200) {
      throw FoundationGateApiException(
        switch (response.statusCode) {
          401 => FoundationGateApiFailure.unauthenticated,
          403 => FoundationGateApiFailure.accessDenied,
          404 => FoundationGateApiFailure.notFound,
          >= 500 || 429 => FoundationGateApiFailure.serviceUnavailable,
          _ => FoundationGateApiFailure.invalidResponse,
        },
        statusCode: response.statusCode,
      );
    }
    final declaredType = response.headers['content-type'];
    final bytes = response.bodyBytes;
    if (bytes.length != media.byteSize ||
        declaredType == null ||
        !declaredType.toLowerCase().startsWith(media.mimeType)) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    return bytes;
  }

  void close() => _client.close();
}
