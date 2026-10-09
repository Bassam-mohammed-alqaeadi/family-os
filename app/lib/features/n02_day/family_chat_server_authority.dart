import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// The five honest answers a chat surface may give. No local fallback is a sixth state.
enum FamilyChatAuthorityStatus {
  ready,
  notConfigured,
  accessDenied,
  unreachable,
  refused,
}

final class FamilyChatChildOption {
  const FamilyChatChildOption({required this.id, required this.displayName});

  final String id;
  final String? displayName;
}

final class FamilyChatAuthorityAnswer<T> {
  const FamilyChatAuthorityAnswer._({
    required this.status,
    required this.value,
    this.serverCode,
    this.statusCode,
    this.details,
  });

  const FamilyChatAuthorityAnswer.ready(T value)
    : this._(status: FamilyChatAuthorityStatus.ready, value: value);

  const FamilyChatAuthorityAnswer.unavailable(
    FamilyChatAuthorityStatus status, {
    String? serverCode,
    int? statusCode,
    Map<String, Object?>? details,
  }) : this._(
         status: status,
         value: null,
         serverCode: serverCode,
         statusCode: statusCode,
         details: details,
       );

  final FamilyChatAuthorityStatus status;
  final T? value;

  /// Safe machine-readable refusal retained for diagnostics; UI renders localized copy.
  final String? serverCode;
  final int? statusCode;
  final Map<String, Object?>? details;

  bool get isReady => status == FamilyChatAuthorityStatus.ready && value != null;
}

/// One server authority for guardian and paired-child chat surfaces.
///
/// Guardian calls obtain a fresh Firebase ID token for every request and always scope through
/// the selected server family. Child calls use the device id and credential held by the native
/// protected store; this class never accepts a child id or device secret from a widget.
final class FamilyChatServerAuthority {
  FamilyChatServerAuthority({
    required this.api,
    required this.idToken,
    required this.familyId,
    this.childOptions,
  });

  final FamilyChatApiClient api;
  final Future<String> Function() idToken;
  final String? Function() familyId;

  /// Kept as a compatibility seam for older child-picker consumers. New direct/group creation
  /// uses the full participant roster returned by the server instead.
  final Future<FamilyChatAuthorityAnswer<List<FamilyChatChildOption>>> Function()?
  childOptions;

  Future<FamilyChatAuthorityAnswer<List<FamilyChatChildOption>>>
  loadChildOptions() async {
    final selected = familyId()?.trim();
    if (selected == null || !_addressable(selected) || childOptions == null) {
      return _notConfigured();
    }
    try {
      final answer = await childOptions!();
      if (!answer.isReady) return answer;
      final children = answer.value!;
      final uniqueChildren = <String, FamilyChatChildOption>{};
      for (final child in children) {
        final id = child.id.trim();
        if (!_addressable(id)) return _refused();
        uniqueChildren.putIfAbsent(
          id,
          () => FamilyChatChildOption(id: id, displayName: child.displayName),
        );
      }
      return FamilyChatAuthorityAnswer.ready(
        List<FamilyChatChildOption>.unmodifiable(uniqueChildren.values),
      );
    } on Object {
      return const FamilyChatAuthorityAnswer.unavailable(
        FamilyChatAuthorityStatus.unreachable,
      );
    }
  }

  static bool _addressable(String value) => isFoundationGateUuid(value.trim());

  Future<FamilyChatAuthorityAnswer<FamilyCollaborationPolicy>> readCollaborationPolicy() =>
      _guardianCall(
        (family, token) => api.getFamilyCollaborationPolicy(
          familyId: family,
          idToken: token,
        ),
      );

  Future<FamilyChatAuthorityAnswer<FamilyCollaborationPolicy>> updateCollaborationPolicy({
    required int expectedVersion,
    required Map<String, Object?> changes,
  }) => _guardianCall(
    (family, token) => api.updateFamilyCollaborationPolicy(
      familyId: family,
      idToken: token,
      expectedVersion: expectedVersion,
      changes: changes,
    ),
  );

  Future<FamilyChatAuthorityAnswer<FamilyChatThreadList>> listGuardianThreads() =>
      _guardianCall(
        (family, token) => api.listFamilyThreads(
          familyId: family,
          idToken: token,
        ),
      );

  Future<FamilyChatAuthorityAnswer<FamilyChatParticipantList>> listGuardianParticipants() =>
      _guardianCall(
        (family, token) => api.listFamilyParticipants(
          familyId: family,
          idToken: token,
        ),
      );

  Future<FamilyChatAuthorityAnswer<FamilyChatThread>> createGuardianThread({
    required FamilyChatThreadKind kind,
    required List<FamilyChatParticipantReference> participants,
    required String title,
    required String Function() idempotencyKey,
  }) => _guardianCall(
    (family, token) => api.createFamilyThread(
      familyId: family,
      kind: kind,
      title: title,
      participants: participants,
      idempotencyKey: idempotencyKey(),
      idToken: token,
    ),
  );

  Future<FamilyChatAuthorityAnswer<FamilyChatThread>> createChildThread({
    required FamilyChatThreadKind kind,
    required List<FamilyChatParticipantReference> participants,
    required String title,
    required String Function() idempotencyKey,
  }) => _deviceCall(
    (deviceId) => api.createDeviceThread(
      deviceId: deviceId,
      kind: kind,
      title: title,
      participants: participants,
      idempotencyKey: idempotencyKey(),
    ),
  );

  Future<FamilyChatAuthorityAnswer<FamilyChatThread>> addGuardianThreadMember({
    required String threadId,
    required FamilyChatParticipantKind participantKind,
    required String participantId,
    required String Function() idempotencyKey,
  }) async {
    if (!_addressable(threadId) || !_addressable(participantId)) {
      return const FamilyChatAuthorityAnswer.unavailable(
        FamilyChatAuthorityStatus.refused,
      );
    }
    return _guardianCall(
      (family, token) => api.addFamilyThreadMember(
        familyId: family,
        threadId: threadId,
        participantKind: participantKind,
        participantId: participantId,
        idempotencyKey: idempotencyKey(),
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatThread>> addChildThreadMember({
    required String threadId,
    required FamilyChatParticipantKind participantKind,
    required String participantId,
    required String Function() idempotencyKey,
  }) async {
    if (!_addressable(threadId) || !_addressable(participantId)) return _refused();
    return _deviceCall(
      (deviceId) => api.addDeviceThreadMember(
        deviceId: deviceId,
        threadId: threadId,
        participantKind: participantKind,
        participantId: participantId,
        idempotencyKey: idempotencyKey(),
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatMessagePage>> listGuardianMessages({
    required String threadId,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _guardianCall(
      (family, token) => api.listFamilyMessages(
        familyId: family,
        threadId: threadId,
        afterSeq: afterSeq,
        limit: limit,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatSendResult>> sendGuardianMessage({
    required String threadId,
    required String body,
    required String clientMessageId,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _guardianCall(
      (family, token) => api.sendFamilyMessage(
        familyId: family,
        threadId: threadId,
        body: body,
        clientMessageId: clientMessageId,
        idempotencyKey: idempotencyKey,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatMessage>> editGuardianMessage({
    required String threadId,
    required String messageId,
    required String body,
    required int revision,
  }) async {
    if (!_addressable(threadId) || !_addressable(messageId)) return _refused();
    return _guardianCall(
      (family, token) => api.editFamilyMessage(
        familyId: family,
        threadId: threadId,
        messageId: messageId,
        body: body,
        revision: revision,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatMessage>> deleteGuardianMessage({
    required String threadId,
    required String messageId,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId) || !_addressable(messageId)) return _refused();
    return _guardianCall(
      (family, token) => api.deleteFamilyMessage(
        familyId: family,
        threadId: threadId,
        messageId: messageId,
        idempotencyKey: idempotencyKey,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatReadState>> markGuardianThreadRead({
    required String threadId,
    required int readSeq,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _guardianCall(
      (family, token) => api.markFamilyThreadRead(
        familyId: family,
        threadId: threadId,
        readSeq: readSeq,
        idempotencyKey: idempotencyKey,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatThreadList>> listChildThreads() =>
      _deviceCall(
        (deviceId) => api.listDeviceThreads(deviceId: deviceId),
      );

  Future<FamilyChatAuthorityAnswer<FamilyChatParticipantList>> listChildParticipants() =>
      _deviceCall(
        (deviceId) => api.listDeviceParticipants(deviceId: deviceId),
      );

  Future<FamilyChatAuthorityAnswer<FamilyChatMessagePage>> listChildMessages({
    required String threadId,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _deviceCall(
      (deviceId) => api.listDeviceMessages(
        deviceId: deviceId,
        threadId: threadId,
        afterSeq: afterSeq,
        limit: limit,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatSendResult>> sendChildMessage({
    required String threadId,
    required String body,
    required String clientMessageId,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _deviceCall(
      (deviceId) => api.sendDeviceMessage(
        deviceId: deviceId,
        threadId: threadId,
        body: body,
        clientMessageId: clientMessageId,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatMessage>> editChildMessage({
    required String threadId,
    required String messageId,
    required String body,
    required int revision,
  }) async {
    if (!_addressable(threadId) || !_addressable(messageId)) return _refused();
    return _deviceCall(
      (deviceId) => api.editDeviceMessage(
        deviceId: deviceId,
        threadId: threadId,
        messageId: messageId,
        body: body,
        revision: revision,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatMessage>> deleteChildMessage({
    required String threadId,
    required String messageId,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId) || !_addressable(messageId)) return _refused();
    return _deviceCall(
      (deviceId) => api.deleteDeviceMessage(
        deviceId: deviceId,
        threadId: threadId,
        messageId: messageId,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatReadState>> markChildThreadRead({
    required String threadId,
    required int readSeq,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _deviceCall(
      (deviceId) => api.markDeviceThreadRead(
        deviceId: deviceId,
        threadId: threadId,
        readSeq: readSeq,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatDeliveryState>> markGuardianThreadDelivered({
    required String threadId,
    required int deliveredSeq,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _guardianCall(
      (family, token) => api.markFamilyThreadDelivered(
        familyId: family,
        threadId: threadId,
        deliveredSeq: deliveredSeq,
        idempotencyKey: idempotencyKey,
        idToken: token,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<FamilyChatDeliveryState>> markChildThreadDelivered({
    required String threadId,
    required int deliveredSeq,
    required String idempotencyKey,
  }) async {
    if (!_addressable(threadId)) return _refused();
    return _deviceCall(
      (deviceId) => api.markDeviceThreadDelivered(
        deviceId: deviceId,
        threadId: threadId,
        deliveredSeq: deliveredSeq,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<FamilyChatAuthorityAnswer<T>> _guardianCall<T>(
    Future<T> Function(String familyId, String token) run,
  ) async {
    final selected = familyId()?.trim();
    if (selected == null || !_addressable(selected)) return _notConfigured();
    final String token;
    try {
      token = (await idToken()).trim();
    } on Object {
      return _notConfigured();
    }
    if (token.isEmpty) return _notConfigured();
    try {
      return FamilyChatAuthorityAnswer<T>.ready(await run(selected, token));
    } on ArgumentError {
      return _refused();
    } on FoundationGateApiException catch (error) {
      return _fromApiError<T>(error);
    } on Object {
      return const FamilyChatAuthorityAnswer.unavailable(
        FamilyChatAuthorityStatus.unreachable,
      );
    }
  }

  Future<FamilyChatAuthorityAnswer<T>> _deviceCall<T>(
    Future<T> Function(String deviceId) run,
  ) async {
    if (!api.hasDeviceTransport) return _notConfigured();
    final String? deviceId;
    try {
      deviceId = await api.configuredDeviceId();
    } on Object {
      return const FamilyChatAuthorityAnswer.unavailable(
        FamilyChatAuthorityStatus.unreachable,
      );
    }
    if (deviceId == null || !_addressable(deviceId)) return _notConfigured();
    try {
      return FamilyChatAuthorityAnswer<T>.ready(await run(deviceId));
    } on ArgumentError {
      return _refused();
    } on FoundationGateApiException catch (error) {
      return _fromApiError<T>(error);
    } on Object {
      return const FamilyChatAuthorityAnswer.unavailable(
        FamilyChatAuthorityStatus.unreachable,
      );
    }
  }

  static FamilyChatAuthorityAnswer<T> _fromApiError<T>(
    FoundationGateApiException error,
  ) => FamilyChatAuthorityAnswer<T>.unavailable(
    switch (error.failure) {
      FoundationGateApiFailure.unauthenticated ||
      FoundationGateApiFailure.accessDenied =>
        FamilyChatAuthorityStatus.accessDenied,
      FoundationGateApiFailure.networkUnavailable ||
      FoundationGateApiFailure.serviceUnavailable =>
        FamilyChatAuthorityStatus.unreachable,
      _ => FamilyChatAuthorityStatus.refused,
    },
    serverCode: error.serverCode,
    statusCode: error.statusCode,
    details: error.details,
  );

  static FamilyChatAuthorityAnswer<T> _notConfigured<T>() =>
      FamilyChatAuthorityAnswer<T>.unavailable(
        FamilyChatAuthorityStatus.notConfigured,
      );

  static FamilyChatAuthorityAnswer<T> _refused<T>() =>
      FamilyChatAuthorityAnswer<T>.unavailable(
        FamilyChatAuthorityStatus.refused,
      );
}

FamilyChatServerAuthority? _activeFamilyChatServerAuthority;

FamilyChatServerAuthority? get activeFamilyChatServerAuthority =>
    _activeFamilyChatServerAuthority;

/// One boot-time binding serves every guardian and child chat surface.
void bindFamilyChatServerAuthority(FamilyChatServerAuthority? authority) {
  _activeFamilyChatServerAuthority = authority;
}
