import 'dart:io';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';

Future<void> main(List<String> arguments) async {
  final originArgument = arguments
      .where((argument) => argument.startsWith('--origin='))
      .firstOrNull;
  final origin =
      originArgument?.substring('--origin='.length) ?? 'http://127.0.0.1:5080';
  final password = Platform.environment['CREAVERS_TEST_PASSWORD'];
  if (password == null || password.isEmpty) {
    stderr.writeln('Set CREAVERS_TEST_PASSWORD before running this check.');
    exitCode = 2;
    return;
  }

  final transport = DefaultHttpTransport();
  final client = ApiClient(
    transport,
    config: AppConfig(apiOrigin: Uri.parse(origin)),
  );
  final authentication = ApiAuthenticationService(client);

  try {
    await authentication.login(
      email: 'customer@demo.creavers.local',
      password: password,
    );
    final categories = await ApiCatalogueService(client).fetchCatalogue();
    final products = categories
        .expand((category) => category.products)
        .toList();
    if (products.length < 2) {
      throw StateError('At least two products are required.');
    }

    final customerOrders = ApiCustomerOrderService(client);
    final created = await customerOrders.createOrder(
      CreateOrderRequest(
        idempotencyKey:
            'full-flow-${DateTime.now().toUtc().microsecondsSinceEpoch}',
        contactName: 'Demo Customer',
        phoneNumber: '+251911234567',
        deliveryAddress: 'Bole Atlas demo delivery stop, Addis Ababa',
        paymentMethod: PaymentMethod.demoCash,
        lines: <CreateOrderLine>[
          CreateOrderLine(productId: products[0].id, quantity: 2),
          CreateOrderLine(productId: products[1].id, quantity: 1),
        ],
      ),
    );
    stdout.writeln(
      'customer-order=created number=${created.orderNumber} '
      'status=${created.status.apiValue} total=${created.total.toStringAsFixed(2)}',
    );

    await authentication.login(
      email: 'dispatcher@demo.creavers.local',
      password: password,
    );
    final driversResponse = await client.get('drivers/available');
    if (driversResponse is! List<Object?> || driversResponse.isEmpty) {
      throw StateError('No active driver is available for assignment.');
    }
    final driver = driversResponse.first! as Map<String, Object?>;
    final driverId = driver['id']! as String;
    final driverName = driver['displayName']! as String;
    final assignedResponse = await client.put(
      'orders/${created.id}/assignment',
      body: <String, Object?>{'driverId': driverId},
    );
    final assigned = DeliveryOrder.fromJson(
      assignedResponse! as Map<String, Object?>,
    );
    stdout.writeln(
      'dispatcher-assignment=saved driver=$driverName '
      'status=${assigned.status.apiValue}',
    );

    await authentication.login(
      email: 'driver@demo.creavers.local',
      password: password,
    );
    final driverOrders = await ApiDriverOrderService(client)
        .fetchAssignedOrders();
    final visibleToDriver = driverOrders.any((order) => order.id == created.id);
    if (!visibleToDriver) {
      throw StateError('The assigned order was not visible to the driver.');
    }
    stdout.writeln(
      'driver-assignment=visible number=${created.orderNumber} '
      'assigned-count=${driverOrders.length}',
    );

    await authentication.login(
      email: 'customer@demo.creavers.local',
      password: password,
    );
    final tracked = await customerOrders.fetchOrder(created.id);
    if (tracked.status != DeliveryOrderStatus.assigned ||
        tracked.assignedDriverId != driverId) {
      throw StateError('Customer tracking did not reflect the assignment.');
    }
    stdout.writeln(
      'customer-tracking=updated status=${tracked.status.apiValue} '
      'flow=passed orderId=${tracked.id}',
    );
  } finally {
    transport.close();
  }
}
