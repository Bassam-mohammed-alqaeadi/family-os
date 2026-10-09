import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:family_os/core/crypto/sha256.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:http/http.dart' as http;

/// Uploads and fetches the photos and voice notes of a family room, for a guardian in that room.
///
/// The transport elsewhere carries text only, so media uses its own small client. The server's
/// rules still apply in full: the caller's credential is sent, the room is checked on every
/// request, and a removed or unjoined item answers 404 and is shown as unavailable.
///
/// Integrity is checked in both directions with SHA-256 computed on this device:
/// - an upload is accepted only if the server stored exactly the bytes sent (same digest, same
///   length), so a photo that went out is the photo that was stored;
/// - a download is accepted only if its recomputed digest equals the digest the server recorded,
///   and its length and MIME type match what the server declared.
final class FamilyChatMediaClient {
  FamilyChatMediaClient({
    required FoundationGateConfiguration configuration,
    http.Client? client,
  }) : _configuration = configuration,
       _client = client ?? http.Client();

  final FoundationGateConfiguration _configuration;
  final http.Client _client;

  /// The largest voice note the server accepts, in milliseconds.
  static const int maxVoiceNoteMs = 300000;

  /// The largest upload the server accepts, in bytes (the photo limit, which is the larger one).
  static const int maxUploadBytes = 8 * 1024 * 1024;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static final RegExp _clientId = RegExp(r'^[A-Za-z0-9_.:-]{8,64}$');

  /// The path the server issued for this item. It must name the same family, room and item the
  /// caller asked for; a path that does not is refused, so a screen can never be steered into
  /// another room's bytes by a malformed response.
  static final RegExp _contentPath = RegExp(
    r'^/v1/families/([0-9a-f-]{36})/chat/threads/([0-9a-f-]{36})/media/([0-9a-f-]{36})/content$',
    caseSensitive: false,
  );

  /// Stores one photo or voice note in a room the caller is in. [clientMediaId] is the caller's
  /// idempotency id: a retry with the same id and the same bytes returns the same item.
  Future<FamilyChatMedia> uploadGuardianMedia({
    required String familyId,
    required String threadId,
    required String clientMediaId,
    required String contentType,
    required Uint8List bytes,
    required String idToken,
    int? durationMs,
  }) async {
    if (!_uuid.hasMatch(familyId) ||
        !_uuid.hasMatch(threadId) ||
        !_clientId.hasMatch(clientMediaId) ||
        bytes.isEmpty ||
        bytes.length > maxUploadBytes ||
        (durationMs != null && (durationMs < 1 || durationMs > maxVoiceNoteMs))) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidInput);
    }
    if (idToken.trim().isEmpty) {
      throw const FoundationGateApiException(FoundationGateApiFailure.unauthenticated);
    }
    final digest = await Isolate.run(() => sha256Hex(bytes));
    final uri = _configuration.stagingApiOrigin.replace(
      path: '/v1/families/$familyId/chat/threads/$threadId/media',
      queryParameters: <String, String>{
        'clientMediaId': clientMediaId,
        if (durationMs != null) 'durationMs': '$durationMs',
      },
    );

    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: <String, String>{
          'authorization': 'Bearer $idToken',
          'content-type': contentType,
          'accept': 'application/json',
        },
        body: bytes,
      );
    } on Object {
      throw const FoundationGateApiException(FoundationGateApiFailure.networkUnavailable);
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw _statusFailure(response.statusCode);
    }
    final decoded = _decodeObject(response.body);
    final media = FamilyChatMedia.fromJson(decoded['media']);
    // The server must have stored exactly these bytes. Anything else is refused, not shown.
    if (media.sha256 != digest || media.byteSize != bytes.length) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    return media;
  }

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
    if (response.statusCode != 200) throw _statusFailure(response.statusCode);
    final declaredType = response.headers['content-type'];
    final bytes = response.bodyBytes;
    if (bytes.length != media.byteSize ||
        declaredType == null ||
        !declaredType.toLowerCase().startsWith(media.mimeType)) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    final digest = await Isolate.run(() => sha256Hex(bytes));
    if (digest != media.sha256) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    return bytes;
  }

  static Map<String, Object?> _decodeObject(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    if (decoded is! Map) {
      throw const FoundationGateApiException(FoundationGateApiFailure.invalidResponse);
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static FoundationGateApiException _statusFailure(int statusCode) {
    return FoundationGateApiException(
      switch (statusCode) {
        401 => FoundationGateApiFailure.unauthenticated,
        403 => FoundationGateApiFailure.accessDenied,
        404 => FoundationGateApiFailure.notFound,
        409 => FoundationGateApiFailure.conflict,
        400 || 413 || 415 || 422 => FoundationGateApiFailure.invalidInput,
        >= 500 || 429 => FoundationGateApiFailure.serviceUnavailable,
        _ => FoundationGateApiFailure.invalidResponse,
      },
      statusCode: statusCode,
    );
  }

  void close() => _client.close();
}
