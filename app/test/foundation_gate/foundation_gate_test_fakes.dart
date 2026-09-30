import 'package:family_os/foundation_gate/family_discovery_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_identity.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

class FakeIdentity implements FoundationGateIdentity {
  FakeIdentity({this.token = 'synthetic-token', this.failure});

  String token;
  Object? failure;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<String> signIn({required String email, required String password}) async {
    signInCalls += 1;
    if (failure != null) {
      throw failure!;
    }
    return token;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class FakeTransport implements FoundationGateHttpTransport {
  FakeTransport(this.response);

  FoundationGateHttpResponse response;
  Uri? requestedUri;
  Map<String, String>? requestedHeaders;
  Object? failure;

  @override
  Future<FoundationGateHttpResponse> get(Uri uri, {required Map<String, String> headers}) async {
    requestedUri = uri;
    requestedHeaders = headers;
    if (failure != null) {
      throw failure!;
    }
    return response;
  }
}

FoundationGateApiException apiFailure(FoundationGateApiFailure failure) {
  return FoundationGateApiException(failure);
}
