import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class DriverOrderService {
  Future<List<DeliveryOrderSummary>> fetchAssignedOrders();

  Future<DeliveryOrder> fetchOrder(String orderId);

  Future<DeliveryOrder> transitionOrder({
    required String orderId,
    required DeliveryOrderStatus status,
    String? note,
  });
}

final class ApiDriverOrderService implements DriverOrderService {
  ApiDriverOrderService(this._client);

  final ApiClient _client;

  @override
  Future<List<DeliveryOrderSummary>> fetchAssignedOrders() async {
    final response = await _client.get('orders/assigned-to-me');
    if (response is! List<Object?>) {
      throw const ApiException(message: 'The orders response was not valid.');
    }
    return response
        .cast<Map<String, Object?>>()
        .map(DeliveryOrderSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DeliveryOrder> fetchOrder(String orderId) async {
    final response = await _client.get('orders/$orderId');
    return _parseOrder(response);
  }

  @override
  Future<DeliveryOrder> transitionOrder({
    required String orderId,
    required DeliveryOrderStatus status,
    String? note,
  }) async {
    final response = await _client.post(
      'orders/$orderId/transitions',
      body: <String, Object?>{'status': status.apiValue, 'note': note},
    );
    return _parseOrder(response);
  }

  DeliveryOrder _parseOrder(Object? response) {
    if (response is! Map<String, Object?>) {
      throw const ApiException(message: 'The order response was not valid.');
    }
    return DeliveryOrder.fromJson(response);
  }
}
