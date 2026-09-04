import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/app/creavers_mobile_app.dart';
import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_onboarding_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final apiClient = ApiClient(DefaultHttpTransport(), config: config);
  final controller = AppController(
    ApiAuthenticationService(apiClient),
    ApiBackendConnectionService(apiClient),
  );

  runApp(
    CreaversMobileApp(
      controller: controller,
      catalogueService: ApiCatalogueService(apiClient),
      customerOrderService: ApiCustomerOrderService(apiClient),
      customerOnboardingService: ApiCustomerOnboardingService(apiClient),
      addressSuggestionService: const LocalAddressSuggestionService(),
      driverOrderService: ApiDriverOrderService(apiClient),
      driverLocationService: ApiDriverLocationService(apiClient),
      deviceLocationService: GeolocatorDeviceLocationService(),
      config: config,
    ),
  );
  controller.checkConnection();
}
