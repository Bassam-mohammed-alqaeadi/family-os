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

  /// A partial update of one existing record.
  ///
  /// PATCH rather than POST for the same reason the contract uses it: the operation names
  /// the exact row it changes in the path, and sends only the fields it is allowed to
  /// change. A POST to the same path would have made "which fields may move" a question
  /// about the body instead of a question about the contract.
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  });

  /// A replacement of one resource that the contract addresses by its own path.
  ///
  /// PUT rather than PATCH where the operation IS the whole record: an app's rule is
  /// allowed/free/blocked/pending and nothing else, so "here is the rule" is a truer
  /// statement than "here is a change to a rule".
  Future<FoundationGateHttpResponse> put(
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

  @override
  Future<FoundationGateHttpResponse> patch(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final response = await _client.patch(uri, headers: headers, body: body);
    return FoundationGateHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  @override
  Future<FoundationGateHttpResponse> put(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final response = await _client.put(uri, headers: headers, body: body);
    return FoundationGateHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
