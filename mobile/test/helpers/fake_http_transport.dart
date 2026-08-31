import 'package:creavers_delivery_mobile/core/network/http_transport.dart';

final class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

final class FakeHttpTransport implements HttpTransport {
  FakeHttpTransport(this.response);

  TransportResponse response;
  RecordedRequest? lastRequest;

  @override
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    lastRequest = RecordedRequest(
      method: method,
      uri: uri,
      headers: Map<String, String>.unmodifiable(headers),
      body: body,
    );
    return response;
  }
}
