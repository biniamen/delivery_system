import 'dart:convert';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_transport.dart';
import '../../helpers/order_fixture.dart';

void main() {
  test(
    'driver transition sends the next state and parses updated order',
    () async {
      final transport = FakeHttpTransport(
        TransportResponse(
          statusCode: 200,
          body: jsonEncode(
            orderFixture(
              status: 'Accepted',
              assignedDriverId: '00000000-0000-0000-0000-000000000300',
            ),
          ),
        ),
      );
      final client = ApiClient(
        transport,
        config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
      )..accessToken = 'driver-token';

      final order = await ApiDriverOrderService(client).transitionOrder(
        orderId: '00000000-0000-0000-0000-000000000100',
        status: DeliveryOrderStatus.accepted,
        note: 'Driver accepted',
      );

      final body =
          jsonDecode(transport.lastRequest!.body!) as Map<String, Object?>;
      expect(transport.lastRequest?.method, 'POST');
      expect(body['status'], 'Accepted');
      expect(order.status, DeliveryOrderStatus.accepted);
    },
  );
}
