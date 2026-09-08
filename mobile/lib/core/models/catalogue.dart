final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
    required this.imageUrl,
    this.stockQuantity = 50,
  });

  factory Product.fromJson(Map<String, Object?> json) => Product(
    id: json['id']! as String,
    name: json['name']! as String,
    description: json['description']! as String,
    unit: json['unit']! as String,
    price: (json['price']! as num).toDouble(),
    imageUrl: json['imageUrl']! as String,
    stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final String description;
  final String unit;
  final double price;
  final String imageUrl;
  final int stockQuantity;
}

final class CatalogueCategory {
  const CatalogueCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.products,
  });

  factory CatalogueCategory.fromJson(Map<String, Object?> json) =>
      CatalogueCategory(
        id: json['id']! as String,
        name: json['name']! as String,
        slug: json['slug']! as String,
        products: (json['products']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(Product.fromJson)
            .toList(growable: false),
      );

  final String id;
  final String name;
  final String slug;
  final List<Product> products;
}
