import 'dart:convert';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';

final class ApiClient {
  ApiClient(this._transport, {required this.config});

  final AppConfig config;
  final HttpTransport _transport;
  String? accessToken;

  Future<Object?> get(String path, {bool authenticated = true}) =>
      _request(method: 'GET', uri: _apiUri(path), authenticated: authenticated);

  Future<Object?> post(
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
  }) => _request(
    method: 'POST',
    uri: _apiUri(path),
    body: body,
    authenticated: authenticated,
  );

  Future<Object?> put(
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
  }) => _request(
    method: 'PUT',
    uri: _apiUri(path),
    body: body,
    authenticated: authenticated,
  );

  Future<TransportResponse> health() => _transport.send(
    method: 'GET',
    uri: config.apiOrigin.resolve('/health/live'),
    headers: const <String, String>{'Accept': 'text/plain'},
  );

  Uri _apiUri(String path) => config.apiBaseUri.resolve(
    path.startsWith('/') ? path.substring(1) : path,
  );

  Future<Object?> _request({
    required String method,
    required Uri uri,
    required bool authenticated,
    Map<String, Object?>? body,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = accessToken;
      if (token == null || token.isEmpty) {
        throw const ApiException(message: 'Please sign in before continuing.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _transport.send(
      method: method,
      uri: uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );

    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final problem = decoded is Map<String, Object?> ? decoded : null;
      throw ApiException(
        statusCode: response.statusCode,
        message:
            problem?['detail']?.toString() ??
            problem?['title']?.toString() ??
            'The server could not complete the request.',
        traceId: problem?['traceId']?.toString(),
      );
    }
    return decoded;
  }
}
