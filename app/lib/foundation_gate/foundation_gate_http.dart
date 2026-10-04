import 'package:http/http.dart' as http;

class FoundationGateHttpResponse {
  const FoundationGateHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

abstract interface class FoundationGateHttpTransport {
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  });

  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  });
}

class PackageFoundationGateHttpTransport
    implements FoundationGateHttpTransport {
  PackageFoundationGateHttpTransport({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<FoundationGateHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final response = await _client.get(uri, headers: headers);
    return FoundationGateHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  @override
  Future<FoundationGateHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final response = await _client.post(uri, headers: headers, body: body);
    return FoundationGateHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
