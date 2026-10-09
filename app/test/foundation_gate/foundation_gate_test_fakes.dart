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

  @override
  Future<String> signUp({required String email, required String password}) {
    // TODO: implement signUp
    throw UnimplementedError();
  }
}

class FakeTransport implements FoundationGateHttpTransport {
  FakeTransport(
    this.response, {
    FoundationGateHttpResponse? postResponse,
    FoundationGateHttpResponse? patchResponse,
    FoundationGateHttpResponse? putResponse,
  }) : _postResponse = postResponse,
       _patchResponse = patchResponse,
       _putResponse = putResponse;

  FoundationGateHttpResponse response;
  FoundationGateHttpResponse? _postResponse;
  FoundationGateHttpResponse? _patchResponse;
  FoundationGateHttpResponse? _putResponse;
  Uri? requestedUri;
  Map<String, String>? requestedHeaders;
  Uri? postedUri;
  Map<String, String>? postedHeaders;
  String? postedBody;
  Uri? patchedUri;
  Map<String, String>? patchedHeaders;
  String? patchedBody;
  final List<Map<String, String>> postedHeadersHistory = [];
  Object? failure;
  Object? postFailure;
  Object? patchFailure;
  Object? putFailure;
  Uri? putUri;
  Map<String, String>? putHeaders;
  String? putBody;

  set postResponse(FoundationGateHttpResponse? value) => _postResponse = value;

  set patchResponse(FoundationGateHttpResponse? value) =>
      _patchResponse = value;

  set putResponse(FoundationGateHttpResponse? value) => _putResponse = value;

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

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    patchedUri = uri;
    patchedHeaders = headers;
    patchedBody = body;
    if (patchFailure != null) {
      throw patchFailure!;
    }
    if (failure != null) {
      throw failure!;
    }
    return _patchResponse ?? response;
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    putUri = uri;
    putHeaders = headers;
    putBody = body;
    if (putFailure != null) {
      throw putFailure!;
    }
    if (failure != null) {
      throw failure!;
    }
    return _putResponse ?? response;
  }
}

FoundationGateApiException apiFailure(FoundationGateApiFailure failure) {
  return FoundationGateApiException(failure);
}
