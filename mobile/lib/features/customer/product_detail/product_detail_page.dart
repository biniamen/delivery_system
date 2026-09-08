import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:flutter/material.dart';

final class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.product,
    required this.cart,
    required this.catalogueService,
    super.key,
  });

  final Product product;
  final CartController cart;
  final CatalogueService catalogueService;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

final class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _futureProduct;

  @override
  void initState() {
    super.initState();
    _futureProduct = widget.catalogueService.fetchProductById(widget.product.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product.name),
    ),
    body: FutureBuilder<Product>(
      future: _futureProduct,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = snapshot.data ?? widget.product;
        final quantity = widget.cart.quantityFor(product);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(27),
              ),
              child: SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    product.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.deepTeal,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.unit,
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  'ETB ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 12),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.circle, color: Color(0xFF23A66F), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'In stock',
                      style: TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (product.description.isNotEmpty) ...<Widget>[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(color: AppTheme.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
            if (quantity == 0)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => widget.cart.add(product)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: AppTheme.deepTeal,
                  ),
                  child: const Text(
                    'Add to basket',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              Row(
                children: <Widget>[
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.deepTeal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: quantity == 1 ? 'Remove item' : 'Decrease',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => widget.cart.decrement(product)),
                          icon: Icon(
                            quantity == 1 ? Icons.delete_outline : Icons.remove,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Increase',
                          visualDensity: VisualDensity.compact,
                          onPressed: quantity >= CartController.maximumQuantity
                              ? null
                              : () => setState(() => widget.cart.add(product)),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
          ],
        );
      },
    ),
  );
}
