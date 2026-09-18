import 'dart:convert';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_transport.dart';
import '../../helpers/order_fixture.dart';

void main() {
  test(
    'creates an order with the backend contract and parses the response',
    () async {
      final transport = FakeHttpTransport(
        TransportResponse(statusCode: 201, body: jsonEncode(orderFixture())),
      );
      final client = ApiClient(
        transport,
        config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
      )..accessToken = 'customer-token';
      final service = ApiCustomerOrderService(client);

      final order = await service.createOrder(
        const CreateOrderRequest(
          idempotencyKey: 'mobile-test-key',
          contactName: 'Demo Customer',
          phoneNumber: '+251911234567',
          deliveryAddress: 'Bole, Addis Ababa',
          deliveryLatitude: 8.9981,
          deliveryLongitude: 38.7877,
          paymentMethod: PaymentMethod.demoCash,
          lines: <CreateOrderLine>[
            CreateOrderLine(
              productId: '00000000-0000-0000-0000-000000000200',
              quantity: 2,
            ),
          ],
        ),
      );

      final body =
          jsonDecode(transport.lastRequest!.body!) as Map<String, Object?>;
      expect(transport.lastRequest?.method, 'POST');
      expect(
        transport.lastRequest?.uri.toString(),
        'http://127.0.0.1:5080/api/v1/orders',
      );
      expect(body['paymentMethod'], 'DemoCash');
      expect(body['deliveryLatitude'], 8.9981);
      expect(body['deliveryLongitude'], 38.7877);
      expect((body['lines']! as List<Object?>).length, 1);
      expect(order.orderNumber, 'CRV-20260831-TEST01');
      expect(order.total, 200);
    },
  );

  test('loads the signed-in customer order history', () async {
    final summary = <String, Object?>{
      'id': '00000000-0000-0000-0000-000000000300',
      'orderNumber': 'CRV-20260904-MINE01',
      'contactName': 'Demo Customer',
      'status': 'Assigned',
      'total': 340,
      'assignedDriverId': '00000000-0000-0000-0000-000000000003',
      'createdAtUtc': '2026-09-04T09:00:00Z',
    };
    final transport = FakeHttpTransport(
      TransportResponse(statusCode: 200, body: jsonEncode(<Object?>[summary])),
    );
    final client = ApiClient(
      transport,
      config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
    )..accessToken = 'customer-token';

    final orders = await ApiCustomerOrderService(client).fetchMyOrders();

    expect(transport.lastRequest?.method, 'GET');
    expect(
      transport.lastRequest?.uri.toString(),
      'http://127.0.0.1:5080/api/v1/orders/mine',
    );
    expect(orders, hasLength(1));
    expect(orders.single.status, DeliveryOrderStatus.assigned);
  });

  test(
    'customer confirms receipt through the delivery confirmation endpoint',
    () async {
      final transport = FakeHttpTransport(
        TransportResponse(
          statusCode: 200,
          body: jsonEncode(orderFixture(status: 'DeliveryConfirmed')),
        ),
      );
      final client = ApiClient(
        transport,
        config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
      )..accessToken = 'customer-token';

      final order = await ApiCustomerOrderService(client)
          .confirmDelivery('00000000-0000-0000-0000-000000000100');

      expect(transport.lastRequest?.method, 'POST');
      expect(
        transport.lastRequest?.uri.toString(),
        'http://127.0.0.1:5080/api/v1/orders/00000000-0000-0000-0000-000000000100/delivery-confirmation',
      );
      expect(order.status, DeliveryOrderStatus.deliveryConfirmed);
    },
  );
}
