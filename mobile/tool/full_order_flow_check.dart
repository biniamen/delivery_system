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
        deliveryLatitude: 8.9981,
        deliveryLongitude: 38.7877,
        paymentMethod: PaymentMethod.demoCash,
        lines: <CreateOrderLine>[
          CreateOrderLine(productId: products[0].id, quantity: 2),
          CreateOrderLine(productId: products[1].id, quantity: 1),
        ],
      ),
    );
    if (created.deliveryLatitude != 8.9981 ||
        created.deliveryLongitude != 38.7877) {
      throw StateError(
        'The API did not preserve the customer destination pin.',
      );
    }
    stdout.writeln(
      'customer-order=created number=${created.orderNumber} '
      'status=${created.status.apiValue} total=${created.total.toStringAsFixed(2)} '
      'destination=${created.deliveryLatitude},${created.deliveryLongitude}',
    );

    await authentication.login(
      email: 'dispatcher@demo.creavers.local',
      password: password,
    );
    final driverAccountsResponse = await client.get('drivers');
    if (driverAccountsResponse is! List<Object?>) {
      throw StateError('Dispatcher could not load driver accounts.');
    }
    const managedDriverEmail = 'readiness.driver@demo.creavers.local';
    var managedDriver = driverAccountsResponse
        .cast<Map<String, Object?>>()
        .where((driver) => driver['email'] == managedDriverEmail)
        .firstOrNull;
    managedDriver ??=
        (await client.post(
              'drivers',
              body: <String, Object?>{
                'displayName': 'Readiness Driver',
                'email': managedDriverEmail,
                'phoneNumber': '+251900000099',
                'temporaryPassword': password,
              },
            ))!
            as Map<String, Object?>;
    final managedDriverId = managedDriver['id']! as String;
    await client.put(
      'drivers/$managedDriverId/status',
      body: <String, Object?>{'isActive': false},
    );
    final availableWhileInactive =
        (await client.get('drivers/available'))! as List<Object?>;
    if (availableWhileInactive.cast<Map<String, Object?>>().any(
      (driver) => driver['id'] == managedDriverId,
    )) {
      throw StateError('An inactive driver remained available for assignment.');
    }
    await client.put(
      'drivers/$managedDriverId/status',
      body: <String, Object?>{'isActive': true},
    );
    stdout.writeln(
      'driver-management=passed registration=controlled activation=verified',
    );

    final driversResponse = await client.get('drivers/available');
    if (driversResponse is! List<Object?> || driversResponse.isEmpty) {
      throw StateError('No active driver is available for assignment.');
    }
    final driver = driversResponse.first! as Map<String, Object?>;
    final driverId = driver['id']! as String;
    final driverName = driver['displayName']! as String;
    final driverEmail = driver['email']! as String;
    final assignedResponse = await client.put(
      'orders/${created.id}/assignment',
      body: <String, Object?>{'driverId': driverId},
    );
    final assignedJson = assignedResponse! as Map<String, Object?>;
    final assigned = DeliveryOrder.fromJson(assignedJson);
    if (assigned.deliveryLatitude != created.deliveryLatitude ||
        assigned.deliveryLongitude != created.deliveryLongitude) {
      throw StateError('Dispatcher did not receive the saved destination pin.');
    }
    final firstAssignmentHistory =
        assignedJson['assignmentHistory']! as List<Object?>;
    if (firstAssignmentHistory.length != 1) {
      throw StateError('The first assignment was not recorded exactly once.');
    }

    final assignmentRetryResponse = await client.put(
      'orders/${created.id}/assignment',
      body: <String, Object?>{'driverId': driverId},
    );
    final assignmentRetryJson =
        assignmentRetryResponse! as Map<String, Object?>;
    final retryAssignmentHistory =
        assignmentRetryJson['assignmentHistory']! as List<Object?>;
    if (retryAssignmentHistory.length != 1) {
      throw StateError('Retrying assignment duplicated the audit history.');
    }
    stdout.writeln(
      'dispatcher-assignment=saved driver=$driverName '
      'status=${assigned.status.apiValue} retry=idempotent',
    );

    await authentication.login(email: driverEmail, password: password);
    final driverOrderService = ApiDriverOrderService(client);
    final driverOrders = await driverOrderService.fetchAssignedOrders();
    final visibleToDriver = driverOrders.any((order) => order.id == created.id);
    if (!visibleToDriver) {
      throw StateError('The assigned order was not visible to the driver.');
    }
    stdout.writeln(
      'driver-assignment=visible number=${created.orderNumber} '
      'assigned-count=${driverOrders.length}',
    );

    final accepted = await driverOrderService.transitionOrder(
      orderId: created.id,
      status: DeliveryOrderStatus.accepted,
      note: 'Accepted by automated assignment-flow check',
    );
    if (accepted.status != DeliveryOrderStatus.accepted) {
      throw StateError('The assigned driver could not accept the delivery.');
    }
    stdout.writeln(
      'driver-acceptance=completed status=${accepted.status.apiValue}',
    );

    await authentication.login(
      email: 'customer@demo.creavers.local',
      password: password,
    );
    final tracked = await customerOrders.fetchOrder(created.id);
    if (tracked.status != DeliveryOrderStatus.accepted ||
        tracked.assignedDriverId != driverId) {
      throw StateError('Customer tracking did not reflect driver acceptance.');
    }
    stdout.writeln(
      'customer-tracking=updated status=${tracked.status.apiValue} '
      'orderId=${tracked.id}',
    );

    await authentication.login(email: driverEmail, password: password);
    final pickedUp = await driverOrderService.transitionOrder(
      orderId: created.id,
      status: DeliveryOrderStatus.pickedUp,
      note: 'Picked up by automated full-flow check',
    );
    if (pickedUp.status != DeliveryOrderStatus.pickedUp) {
      throw StateError('The driver could not mark the order picked up.');
    }

    await authentication.login(
      email: 'customer@demo.creavers.local',
      password: password,
    );
    final trackedPickup = await customerOrders.fetchOrder(created.id);
    if (trackedPickup.status != DeliveryOrderStatus.pickedUp) {
      throw StateError('Customer tracking did not reflect supermarket pickup.');
    }
    stdout.writeln(
      'customer-tracking=updated status=${trackedPickup.status.apiValue}',
    );

    await authentication.login(email: driverEmail, password: password);
    final delivered = await driverOrderService.transitionOrder(
      orderId: created.id,
      status: DeliveryOrderStatus.delivered,
      note: 'Delivered by automated full-flow check',
    );
    if (delivered.status != DeliveryOrderStatus.delivered) {
      throw StateError('The driver could not complete the delivery.');
    }

    // Retrying the target state simulates a lost mobile response and must not
    // create another audit event.
    final deliveryRetry = await driverOrderService.transitionOrder(
      orderId: created.id,
      status: DeliveryOrderStatus.delivered,
      note: 'Safe delivered retry',
    );

    await authentication.login(
      email: 'customer@demo.creavers.local',
      password: password,
    );
    final completed = await customerOrders.fetchOrder(created.id);
    final lifecycle = completed.statusHistory
        .where(
          (entry) => <DeliveryOrderStatus>{
            DeliveryOrderStatus.assigned,
            DeliveryOrderStatus.accepted,
            DeliveryOrderStatus.pickedUp,
            DeliveryOrderStatus.delivered,
          }.contains(entry.status),
        )
        .toList(growable: false);
    final lifecycleStates = lifecycle.map((entry) => entry.status).toList();
    const expectedLifecycle = <DeliveryOrderStatus>[
      DeliveryOrderStatus.assigned,
      DeliveryOrderStatus.accepted,
      DeliveryOrderStatus.pickedUp,
      DeliveryOrderStatus.delivered,
    ];
    if (completed.status != DeliveryOrderStatus.delivered ||
        lifecycleStates.length != expectedLifecycle.length ||
        !List<bool>.generate(
          expectedLifecycle.length,
          (index) => lifecycleStates[index] == expectedLifecycle[index],
        ).every((matches) => matches) ||
        deliveryRetry.statusHistory.length != delivered.statusHistory.length) {
      throw StateError(
        'The final customer status or delivery audit trail is incomplete.',
      );
    }
    for (var index = 1; index < lifecycle.length; index++) {
      if (lifecycle[index].changedAtUtc.isBefore(
        lifecycle[index - 1].changedAtUtc,
      )) {
        throw StateError('Delivery milestone timestamps are out of order.');
      }
    }

    final confirmation = await customerOrders.confirmDelivery(created.id);
    final confirmationRetry = await customerOrders.confirmDelivery(created.id);
    if (confirmation.status != DeliveryOrderStatus.deliveryConfirmed ||
        confirmationRetry.status != DeliveryOrderStatus.deliveryConfirmed ||
        confirmationRetry.statusHistory.length !=
            confirmation.statusHistory.length ||
        confirmation.statusHistory.last.status !=
            DeliveryOrderStatus.deliveryConfirmed) {
      throw StateError('Customer delivery confirmation is not retry-safe.');
    }

    await authentication.login(
      email: 'dispatcher@demo.creavers.local',
      password: password,
    );
    final dispatcherView = DeliveryOrder.fromJson(
      (await client.get('orders/${created.id}'))! as Map<String, Object?>,
    );
    if (dispatcherView.status != DeliveryOrderStatus.deliveryConfirmed) {
      throw StateError(
        'Dispatcher monitoring did not show customer confirmation.',
      );
    }
    stdout.writeln(
      'delivery-flow=passed status=${confirmation.status.apiValue} '
      'history=${confirmation.statusHistory.length} retry=idempotent '
      'customer=visible dispatcher=visible',
    );
  } finally {
    transport.close();
  }
}
