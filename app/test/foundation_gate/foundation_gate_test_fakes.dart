import 'package:family_os/foundation_gate/foundation_gate_http.dart';
import 'package:family_os/foundation_gate/foundation_gate_identity.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

class FakeIdentity implements FoundationGateIdentity {
  FakeIdentity({
    this.token = 'synthetic-token',
    this.subject = 'synthetic-subject',
    this.failure,
  });

  String token;
  String subject;
  Object? failure;
  int signInCalls = 0;
  int currentTokenCalls = 0;
  int signOutCalls = 0;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    if (failure != null) {
      throw failure!;
    }
    return token;
  }

  @override
  Future<String> currentIdToken() async {
    currentTokenCalls += 1;
    if (failure != null) {
      throw failure!;
    }
    return token;
  }

  @override
  Future<String> currentSubject() async {
    if (failure != null) {
      throw failure!;
    }
    return subject;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class FakeTransport implements FoundationGateHttpTransport {
  FakeTransport(this.response, {FoundationGateHttpResponse? postResponse})
    : _postResponse = postResponse;

  FoundationGateHttpResponse response;
  FoundationGateHttpResponse? _postResponse;
  Uri? requestedUri;
  Map<String, String>? requestedHeaders;
  Uri? postedUri;
  Map<String, String>? postedHeaders;
  String? postedBody;
  final List<Map<String, String>> postedHeadersHistory = [];
  Object? failure;
  Object? postFailure;

  set postResponse(FoundationGateHttpResponse? value) => _postResponse = value;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    requestedUri = uri;
    requestedHeaders = headers;
    if (failure != null) {
      throw failure!;
    }
    return response;
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    postedUri = uri;
    postedHeaders = headers;
    postedHeadersHistory.add(Map.unmodifiable(headers));
    postedBody = body;
    if (postFailure != null) {
      throw postFailure!;
    }
    if (failure != null) {
      throw failure!;
    }
    return _postResponse ?? response;
  }
}

FoundationGateApiException apiFailure(FoundationGateApiFailure failure) {
  return FoundationGateApiException(failure);
}
