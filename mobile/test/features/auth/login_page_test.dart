import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:creavers_delivery_mobile/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows customer and driver demo entry points', (tester) async {
    final controller = AppController(
      _UnusedAuthenticationService(),
      _OnlineConnectionService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          controller: controller,
          apiOrigin: Uri.parse('http://10.0.2.2:5080'),
        ),
      ),
    );

    expect(find.text('Delivery in your hands.'), findsOneWidget);
    expect(find.text('Customer demo'), findsOneWidget);
    expect(find.text('Driver demo'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
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
