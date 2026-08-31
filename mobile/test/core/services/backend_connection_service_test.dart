import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_transport.dart';

void main() {
  test('health check targets the backend liveness endpoint', () async {
    final transport = FakeHttpTransport(
      const TransportResponse(statusCode: 200, body: 'Healthy'),
    );
    final client = ApiClient(
      transport,
      config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
    );

    final result = await ApiBackendConnectionService(client).check();

    expect(result.isReachable, isTrue);
    expect(
      transport.lastRequest?.uri.toString(),
      'http://127.0.0.1:5080/health/live',
    );
  });
}
