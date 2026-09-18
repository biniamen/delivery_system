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
  const transitionCases = <DeliveryOrderStatus, String>{
    DeliveryOrderStatus.accepted: 'Accepted',
    DeliveryOrderStatus.pickedUp: 'PickedUp',
    DeliveryOrderStatus.delivered: 'Delivered',
  };

  for (final transitionCase in transitionCases.entries) {
    test(
      'driver transition sends and parses ${transitionCase.value}',
      () async {
        final transport = FakeHttpTransport(
          TransportResponse(
            statusCode: 200,
            body: jsonEncode(
              orderFixture(
                status: transitionCase.value,
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
          status: transitionCase.key,
          note: 'Driver status update',
        );

        final body =
            jsonDecode(transport.lastRequest!.body!) as Map<String, Object?>;
        expect(transport.lastRequest?.method, 'POST');
        expect(body['status'], transitionCase.value);
        expect(order.status, transitionCase.key);
      },
    );
  }
}
