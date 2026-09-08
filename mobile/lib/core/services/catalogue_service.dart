import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';

abstract interface class CatalogueService {
  Future<List<CatalogueCategory>> fetchCatalogue();

  Future<Product> fetchProductById(String id);
}

final class ApiCatalogueService implements CatalogueService {
  ApiCatalogueService(this._client);

  final ApiClient _client;

  @override
  Future<List<CatalogueCategory>> fetchCatalogue() async {
    final response = await _client.get('catalogue');
    if (response is! List<Object?>) {
      throw const ApiException(
        message: 'The catalogue response was not valid.',
      );
    }
    return response
        .cast<Map<String, Object?>>()
        .map(CatalogueCategory.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Product> fetchProductById(String id) async {
    final response = await _client.get('catalogue/products/$id');
    if (response is! Map<String, Object?>) {
      throw const ApiException(
        message: 'The product response was not valid.',
      );
    }
    return Product.fromJson(response);
  }
}
