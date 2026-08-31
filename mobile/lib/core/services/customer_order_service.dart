import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class CustomerOrderService {
  Future<DeliveryOrder> createOrder(CreateOrderRequest request);

  Future<DeliveryOrder> fetchOrder(String orderId);
}

final class ApiCustomerOrderService implements CustomerOrderService {
  ApiCustomerOrderService(this._client);

  final ApiClient _client;

  @override
  Future<DeliveryOrder> createOrder(CreateOrderRequest request) async {
    final response = await _client.post('orders', body: request.toJson());
    return _parseOrder(response);
  }

  @override
  Future<DeliveryOrder> fetchOrder(String orderId) async {
    final response = await _client.get('orders/$orderId');
    return _parseOrder(response);
  }

  DeliveryOrder _parseOrder(Object? response) {
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The order response was not valid.');
    }
    return DeliveryOrder.fromJson(response);
  }
}
