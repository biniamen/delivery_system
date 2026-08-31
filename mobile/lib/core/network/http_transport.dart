import 'dart:async';

import 'package:http/http.dart' as http;

final class TransportResponse {
  const TransportResponse({
    required this.statusCode,
    required this.body,
    this.headers = const <String, String>{},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract interface class HttpTransport {
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  });
}

final class DefaultHttpTransport implements HttpTransport {
  DefaultHttpTransport({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = body;
    }

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);

    return TransportResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  void close() => _client.close();
}
