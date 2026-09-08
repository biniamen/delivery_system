import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_onboarding_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/delivery_route_service.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/auth/login_page.dart';
import 'package:creavers_delivery_mobile/features/customer/customer_home_page.dart';
import 'package:creavers_delivery_mobile/features/driver/driver_home_page.dart';
import 'package:flutter/material.dart';

final class CreaversMobileApp extends StatelessWidget {
  const CreaversMobileApp({
    required this.controller,
    required this.catalogueService,
    required this.customerOrderService,
    required this.customerOnboardingService,
    required this.addressSuggestionService,
    required this.deliveryRouteService,
    required this.driverOrderService,
    required this.driverLocationService,
    required this.deviceLocationService,
    required this.config,
    super.key,
  });

  final AppController controller;
  final CatalogueService catalogueService;
  final CustomerOrderService customerOrderService;
  final CustomerOnboardingService customerOnboardingService;
  final AddressSuggestionService addressSuggestionService;
  final DeliveryRouteService deliveryRouteService;
  final DriverOrderService driverOrderService;
  final DriverLocationService driverLocationService;
  final DeviceLocationService deviceLocationService;
  final AppConfig config;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      title: 'Creavers Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _home(),
    ),
  );

  Widget _home() {
    final session = controller.session;
    if (session == null) {
      return LoginPage(
        controller: controller,
        apiOrigin: config.apiOrigin,
        onboardingService: customerOnboardingService,
      );
    }
    return switch (session.user.role) {
      UserRole.customer => CustomerHomePage(
        controller: controller,
        session: session,
        catalogueService: catalogueService,
        orderService: customerOrderService,
        addressSuggestionService: addressSuggestionService,
        deviceLocationService: deviceLocationService,
        locationService: driverLocationService,
        deliveryRouteService: deliveryRouteService,
      ),
      UserRole.driver => DriverHomePage(
        controller: controller,
        session: session,
        orderService: driverOrderService,
        locationService: driverLocationService,
        deviceLocationService: deviceLocationService,
        deliveryRouteService: deliveryRouteService,
      ),
      UserRole.dispatcher => LoginPage(
        controller: controller,
        apiOrigin: config.apiOrigin,
        onboardingService: customerOnboardingService,
      ),
      UserRole.storeAdmin => LoginPage(
        controller: controller,
        apiOrigin: config.apiOrigin,
        onboardingService: customerOnboardingService,
      ),
    };
  }
}
