import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class AuthenticationService {
  Future<AuthSession> login({required String email, required String password});

  void clearSession();
}

final class ApiAuthenticationService implements AuthenticationService {
  ApiAuthenticationService(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      'auth/login',
      authenticated: false,
      body: <String, Object?>{'email': email.trim(), 'password': password},
    );
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The login response was not valid.');
    }

    final session = AuthSession.fromJson(response);
    _client.accessToken = session.accessToken;
    return session;
  }

  @override
  void clearSession() {
    _client.accessToken = null;
  }
}
