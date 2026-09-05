import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/customer_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/order_fixture.dart';

void main() {
  testWidgets('customer can add a product, checkout and reach tracking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      _UnusedAuthenticationService(),
      _OnlineConnectionService(),
    );
    final session = AuthSession(
      accessToken: 'customer-token',
      expiresAtUtc: _expiry,
      user: AppUser(
        id: '00000000-0000-0000-0000-000000000001',
        email: 'customer@demo.creavers.local',
        displayName: 'Demo Customer',
        role: UserRole.customer,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CustomerHomePage(
          controller: controller,
          session: session,
          catalogueService: _SingleProductCatalogue(),
          orderService: _SuccessfulCustomerOrderService(),
          addressSuggestionService: const LocalAddressSuggestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fresh Milk'), findsOneWidget);
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('View basket'), findsOneWidget);

    await tester.tap(find.text('View basket'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Checkout · ETB 140.00'),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '+251911234567');
    await tester.enterText(fields.at(2), 'Saris');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Suggested locations'), findsOneWidget);
    expect(find.text('Saris Abo'), findsOneWidget);
    await tester.tap(find.text('Saris Abo'));
    await tester.pump();
    expect(find.text('Exact delivery pin saved'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    final placeOrderButton = find.widgetWithText(
      FilledButton,
      'Place order · ETB 140.00',
    );
    await tester.ensureVisible(placeOrderButton);
    await tester.tap(placeOrderButton);
    await tester.pumpAndSettle();

    expect(find.text('Track order'), findsOneWidget);
    expect(find.text('CRV-20260831-TEST01'), findsOneWidget);
    expect(find.text('Order received'), findsOneWidget);
  });
}

final _expiry = DateTime.utc(2026, 9);

final class _SingleProductCatalogue implements CatalogueService {
  @override
  Future<List<CatalogueCategory>> fetchCatalogue() async =>
      const <CatalogueCategory>[
        CatalogueCategory(
          id: 'category-id',
          name: 'Dairy',
          slug: 'dairy',
          products: <Product>[
            Product(
              id: '00000000-0000-0000-0000-000000000200',
              name: 'Fresh Milk',
              description: 'Pasteurized milk',
              unit: '1 litre',
              price: 60,
              imageUrl: '/images/milk.png',
            ),
          ],
        ),
      ];
}

final class _SuccessfulCustomerOrderService implements CustomerOrderService {
  late final DeliveryOrder _order = DeliveryOrder.fromJson(orderFixture());

  @override
  Future<DeliveryOrder> createOrder(CreateOrderRequest request) async => _order;

  @override
  Future<DeliveryOrder> fetchOrder(String orderId) async => _order;

  @override
  Future<List<DeliveryOrderSummary>> fetchMyOrders() async =>
      const <DeliveryOrderSummary>[];
}

final class _UnusedAuthenticationService implements AuthenticationService {
  @override
  void clearSession() {}

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

final class _OnlineConnectionService implements BackendConnectionService {
  @override
  Future<BackendConnectionResult> check() async =>
      const BackendConnectionResult(
        isReachable: true,
        message: 'Backend connected',
        statusCode: 200,
      );
}
