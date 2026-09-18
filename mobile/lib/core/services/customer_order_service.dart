import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class CustomerOrderService {
  Future<DeliveryOrder> createOrder(CreateOrderRequest request);

  Future<DeliveryOrder> fetchOrder(String orderId);

  Future<DeliveryOrder> confirmDelivery(String orderId);

  Future<List<DeliveryOrderSummary>> fetchMyOrders();
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

  @override
  Future<DeliveryOrder> confirmDelivery(String orderId) async {
    final response = await _client.post(
      'orders/$orderId/delivery-confirmation',
    );
    return _parseOrder(response);
  }

  @override
  Future<List<DeliveryOrderSummary>> fetchMyOrders() async {
    final response = await _client.get('orders/mine');
    if (response is! List<Object?>) {
      throw const ApiException(message: 'The order list was not valid.');
    }
    return response
        .cast<Map<String, Object?>>()
        .map(DeliveryOrderSummary.fromJson)
        .toList(growable: false);
  }

  DeliveryOrder _parseOrder(Object? response) {
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The order response was not valid.');
    }
    return DeliveryOrder.fromJson(response);
  }
}
