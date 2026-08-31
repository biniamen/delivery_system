import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class DriverLocationService {
  Future<DriverLocation> publish(DevicePosition position);

  Future<DriverLocation?> fetchForOrder(String orderId);
}

final class ApiDriverLocationService implements DriverLocationService {
  ApiDriverLocationService(this._client);

  final ApiClient _client;

  @override
  Future<DriverLocation> publish(DevicePosition position) async {
    final response = await _client.post(
      'driver-locations/me',
      body: position.toJson(),
    );
    return _parse(response);
  }

  @override
  Future<DriverLocation?> fetchForOrder(String orderId) async {
    final response = await _client.get('driver-locations/orders/$orderId');
    return response == null ? null : _parse(response);
  }

  DriverLocation _parse(Object? response) {
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The location response was not valid.');
    }
    return DriverLocation.fromJson(response);
  }
}
