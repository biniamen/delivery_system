import 'dart:io';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';

Future<void> main(List<String> arguments) async {
  final originArgument = arguments
      .where((argument) => argument.startsWith('--origin='))
      .firstOrNull;
  final origin =
      originArgument?.substring('--origin='.length) ?? 'http://127.0.0.1:5080';
  final transport = DefaultHttpTransport();
  final client = ApiClient(
    transport,
    config: AppConfig(apiOrigin: Uri.parse(origin)),
  );

  try {
    final connection = await ApiBackendConnectionService(client).check();
    stdout.writeln(
      'health=${connection.isReachable ? 'ok' : 'failed'} '
      'origin=$origin status=${connection.statusCode ?? 'unavailable'}',
    );
    if (!connection.isReachable) {
      exitCode = 1;
      return;
    }

    final email = Platform.environment['CREAVERS_TEST_EMAIL'];
    final password = Platform.environment['CREAVERS_TEST_PASSWORD'];
    if (email != null && password != null) {
      final session = await ApiAuthenticationService(client)
          .login(email: email, password: password);
      stdout.writeln(
        'authentication=ok role=${session.user.role.name} '
        'user=${session.user.displayName}',
      );

      switch (session.user.role) {
        case UserRole.customer:
          final categories = await ApiCatalogueService(client).fetchCatalogue();
          final productCount = categories.fold<int>(
            0,
            (total, category) => total + category.products.length,
          );
          stdout.writeln(
            'catalogue=ok categories=${categories.length} '
            'products=$productCount',
          );
        case UserRole.driver:
          final orders = await ApiDriverOrderService(client)
              .fetchAssignedOrders();
          stdout.writeln('assigned-orders=ok count=${orders.length}');
        case UserRole.dispatcher:
          stdout.writeln('role-check=ok portal=dispatcher-web');
      }
    }
  } finally {
    transport.close();
  }
}
