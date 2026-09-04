import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:creavers_delivery_mobile/features/customer/checkout/checkout_page.dart';
import 'package:creavers_delivery_mobile/shared/widgets/empty_state_card.dart';
import 'package:flutter/material.dart';

final class CartPage extends StatelessWidget {
  const CartPage({
    required this.cart,
    required this.session,
    required this.orderService,
    required this.addressSuggestionService,
    super.key,
  });

  final CartController cart;
  final AuthSession session;
  final CustomerOrderService orderService;
  final AddressSuggestionService addressSuggestionService;

  Future<void> _checkout(BuildContext context) async {
    final order = await Navigator.of(context).push<DeliveryOrder>(
      MaterialPageRoute<DeliveryOrder>(
        builder: (_) => CheckoutPage(
          cart: cart,
          session: session,
          orderService: orderService,
          addressSuggestionService: addressSuggestionService,
        ),
      ),
    );
    if (order != null && context.mounted) Navigator.of(context).pop(order);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: cart,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Your basket'),
        actions: <Widget>[
          if (!cart.isEmpty)
            TextButton(onPressed: cart.clear, child: const Text('Clear')),
        ],
      ),
      body: cart.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyStateCard(
                icon: Icons.shopping_basket_outlined,
                title: 'Your basket is empty',
                message: 'Add fresh products from the shop to get started.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: <Widget>[
                Text(
                  '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} selected',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                for (final line in cart.lines) ...<Widget>[
                  _CartLineCard(line: line, cart: cart),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                _PriceSummary(cart: cart),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: FilledButton.icon(
                onPressed: () => _checkout(context),
                icon: const Icon(Icons.lock_outline),
                label: Text('Checkout · ETB ${cart.total.toStringAsFixed(2)}'),
              ),
            ),
    ),
  );
}

final class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line, required this.cart});

  final CartLine line;
  final CartController cart;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox.square(
              dimension: 58,
              child: Center(
                child: Text(
                  line.product.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.deepTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${line.product.unit} · ETB ${line.product.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.inkSoft),
                ),
                const SizedBox(height: 10),
                _QuantityControl(
                  quantity: line.quantity,
                  onAdd: () => cart.add(line.product),
                  onRemove: () => cart.decrement(line.product),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ETB ${line.lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.deepTeal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.canvas,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: quantity == 1 ? 'Remove item' : 'Decrease quantity',
          onPressed: onRemove,
          icon: Icon(quantity == 1 ? Icons.delete_outline : Icons.remove),
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase quantity',
          onPressed: quantity >= CartController.maximumQuantity ? null : onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

final class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.cart});

  final CartController cart;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          _SummaryRow(label: 'Subtotal', value: cart.subtotal),
          const SizedBox(height: 10),
          const _SummaryRow(
            label: 'Delivery fee',
            value: CartController.deliveryFee,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _SummaryRow(label: 'Total', value: cart.total, emphasized: true),
        ],
      ),
    ),
  );
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: emphasized ? AppTheme.ink : AppTheme.inkSoft,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        'ETB ${value.toStringAsFixed(2)}',
        style: TextStyle(
          color: emphasized ? AppTheme.deepTeal : AppTheme.ink,
          fontSize: emphasized ? 18 : 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
