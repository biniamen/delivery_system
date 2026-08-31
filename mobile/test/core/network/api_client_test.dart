import 'dart:convert';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_transport.dart';

void main() {
  test(
    'login uses the versioned endpoint and stores the bearer token',
    () async {
      final transport = FakeHttpTransport(
        TransportResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'accessToken': 'test-token',
            'expiresAtUtc': '2026-08-31T00:00:00Z',
            'user': <String, Object?>{
              'id': '00000000-0000-0000-0000-000000000001',
              'email': 'customer@demo.creavers.local',
              'displayName': 'Demo Customer',
              'role': 'Customer',
            },
          }),
        ),
      );
      final client = ApiClient(
        transport,
        config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
      );

      final session = await ApiAuthenticationService(
        client,
      ).login(email: 'customer@demo.creavers.local', password: 'demo-password');

      expect(session.user.role, UserRole.customer);
      expect(client.accessToken, 'test-token');
      expect(transport.lastRequest?.method, 'POST');
      expect(
        transport.lastRequest?.uri.toString(),
        'http://127.0.0.1:5080/api/v1/auth/login',
      );
      expect(transport.lastRequest?.headers['Authorization'], isNull);
    },
  );

  test('authenticated requests include the bearer token', () async {
    final transport = FakeHttpTransport(
      const TransportResponse(statusCode: 200, body: '[]'),
    );
    final client = ApiClient(
      transport,
      config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
    )..accessToken = 'mobile-token';

    await client.get('catalogue');

    expect(
      transport.lastRequest?.headers['Authorization'],
      'Bearer mobile-token',
    );
  });
}
