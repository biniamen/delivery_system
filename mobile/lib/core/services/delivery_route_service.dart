import 'package:creavers_delivery_mobile/core/models/delivery_route.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class DeliveryRouteService {
  Future<DeliveryRoute?> fetchForOrder(String orderId);
}

final class ApiDeliveryRouteService implements DeliveryRouteService {
  ApiDeliveryRouteService(this._client);

  final ApiClient _client;

  @override
  Future<DeliveryRoute?> fetchForOrder(String orderId) async {
    final response = await _client.get('maps/orders/$orderId/route');
    if (response == null) return null;
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The route response was not valid.');
    }
    return DeliveryRoute.fromJson(response);
  }
}
