import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/authentication_service.dart';
import 'package:creavers_delivery_mobile/core/services/backend_connection_service.dart';
import 'package:flutter/foundation.dart';

enum BackendConnectionState { checking, online, offline }

final class AppController extends ChangeNotifier {
  AppController(this._authenticationService, this._connectionService);

  final AuthenticationService _authenticationService;
  final BackendConnectionService _connectionService;

  AuthSession? _session;
  bool _isBusy = false;
  String? _errorMessage;
  BackendConnectionState _connectionState = BackendConnectionState.checking;
  String _connectionMessage = 'Checking backend connection…';

  AuthSession? get session => _session;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  BackendConnectionState get connectionState => _connectionState;
  String get connectionMessage => _connectionMessage;

  Future<void> checkConnection() async {
    _connectionState = BackendConnectionState.checking;
    _connectionMessage = 'Checking backend connection…';
    notifyListeners();

    final result = await _connectionService.check();
    _connectionState = result.isReachable
        ? BackendConnectionState.online
        : BackendConnectionState.offline;
    _connectionMessage = result.message;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authenticated = await _authenticationService.login(
        email: email,
        password: password,
      );
      if (authenticated.user.role == UserRole.dispatcher) {
        _authenticationService.clearSession();
        throw const ApiException(
          message: 'Dispatchers should use the web dispatcher portal.',
        );
      }
      _session = authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } on Object {
      _errorMessage = 'Unable to sign in. Check the connection and try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void logout() {
    _authenticationService.clearSession();
    _session = null;
    _errorMessage = null;
    notifyListeners();
  }
}
