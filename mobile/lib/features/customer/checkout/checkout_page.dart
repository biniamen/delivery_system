import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:flutter/material.dart';

final class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.cart,
    required this.session,
    required this.orderService,
    super.key,
  });

  final CartController cart;
  final AuthSession session;
  final CustomerOrderService orderService;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

final class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  late final String _idempotencyKey;
  PaymentMethod _paymentMethod = PaymentMethod.demoCash;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.session.user.displayName,
    );
    _idempotencyKey =
        'mobile-${widget.session.user.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate() || widget.cart.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final order = await widget.orderService.createOrder(
        CreateOrderRequest(
          idempotencyKey: _idempotencyKey,
          contactName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          paymentMethod: _paymentMethod,
          lines: widget.cart.lines
              .map(
                (line) => CreateOrderLine(
                  productId: line.product.id,
                  quantity: line.quantity,
                ),
              )
              .toList(growable: false),
        ),
      );
      widget.cart.clear();
      if (mounted) Navigator.of(context).pop(order);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage = 'The order could not be placed. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^(\+251|0)?9\d{8}$').hasMatch(phone)) {
      return 'Use an Ethiopian number such as +251911234567.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          const _CheckoutProgress(),
          const SizedBox(height: 24),
          Text(
            'Delivery details',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'We use these details only to complete this demonstration order.',
            style: TextStyle(color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Contact name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the delivery contact name.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+251911234567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              hintText: 'Street, landmark and area',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a complete delivery address.'
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Payment method',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          SegmentedButton<PaymentMethod>(
            segments: const <ButtonSegment<PaymentMethod>>[
              ButtonSegment<PaymentMethod>(
                value: PaymentMethod.demoCash,
                icon: Icon(Icons.payments_outlined),
                label: Text('Cash'),
              ),
              ButtonSegment<PaymentMethod>(
                value: PaymentMethod.demoCard,
                icon: Icon(Icons.credit_card_outlined),
                label: Text('Demo card'),
              ),
            ],
            selected: <PaymentMethod>{_paymentMethod},
            onSelectionChanged: _isSubmitting
                ? null
                : (selection) =>
                      setState(() => _paymentMethod = selection.first),
          ),
          const SizedBox(height: 8),
          const Text(
            'No real payment is collected in this prototype.',
            style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _OrderReview(cart: widget.cart),
          if (_errorMessage case final message?) ...<Widget>[
            const SizedBox(height: 16),
            _CheckoutError(message: message),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _placeOrder,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSubmitting
                  ? 'Placing order…'
                  : 'Place order · ETB ${widget.cart.total.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    ),
  );
}

final class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress();

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const _ProgressStep(
        icon: Icons.shopping_basket_outlined,
        label: 'Basket',
      ),
      Expanded(child: Divider(color: Theme.of(context).colorScheme.primary)),
      const _ProgressStep(
        icon: Icons.location_on_outlined,
        label: 'Delivery',
        active: true,
      ),
      const Expanded(child: Divider()),
      const _ProgressStep(icon: Icons.check, label: 'Placed'),
    ],
  );
}

final class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      CircleAvatar(
        radius: 17,
        backgroundColor: active ? AppTheme.deepTeal : AppTheme.mint,
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : AppTheme.deepTeal,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          color: active ? AppTheme.ink : AppTheme.inkSoft,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

final class _OrderReview extends StatelessWidget {
  const _OrderReview({required this.cart});

  final CartController cart;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.deepTeal,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Order review',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _ReviewRow(label: '${cart.itemCount} items', value: cart.subtotal),
          const _ReviewRow(
            label: 'Delivery fee',
            value: CartController.deliveryFee,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF4D8584)),
          ),
          _ReviewRow(label: 'Total', value: cart.total, strong: true),
        ],
      ),
    ),
  );
}

final class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? Colors.white : const Color(0xFFD6E8E6),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          'ETB ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: strong ? AppTheme.warmGold : Colors.white,
            fontSize: strong ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

final class _CheckoutError extends StatelessWidget {
  const _CheckoutError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
