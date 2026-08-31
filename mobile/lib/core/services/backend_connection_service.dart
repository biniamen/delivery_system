import 'package:creavers_delivery_mobile/core/network/api_client.dart';

final class BackendConnectionResult {
  const BackendConnectionResult({
    required this.isReachable,
    required this.message,
    this.statusCode,
  });

  final bool isReachable;
  final String message;
  final int? statusCode;
}

abstract interface class BackendConnectionService {
  Future<BackendConnectionResult> check();
}

final class ApiBackendConnectionService implements BackendConnectionService {
  ApiBackendConnectionService(this._client);

  final ApiClient _client;

  @override
  Future<BackendConnectionResult> check() async {
    try {
      final response = await _client.health();
      final healthy = response.statusCode == 200;
      return BackendConnectionResult(
        isReachable: healthy,
        statusCode: response.statusCode,
        message: healthy ? 'Backend connected' : 'Backend returned an error',
      );
    } on Object catch (error) {
      return BackendConnectionResult(
        isReachable: false,
        message: 'Backend unavailable: $error',
      );
    }
  }
}
