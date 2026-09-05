import 'dart:async';

import 'package:creavers_delivery_mobile/core/models/address_suggestion.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:creavers_delivery_mobile/features/customer/checkout/delivery_location_picker_page.dart';
import 'package:flutter/material.dart';

final class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.cart,
    required this.session,
    required this.orderService,
    required this.addressSuggestionService,
    this.deviceLocationService,
    super.key,
  });

  final CartController cart;
  final AuthSession session;
  final CustomerOrderService orderService;
  final AddressSuggestionService addressSuggestionService;
  final DeviceLocationService? deviceLocationService;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

final class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _addressController = TextEditingController();
  late final String _idempotencyKey;
  PaymentMethod _paymentMethod = PaymentMethod.demoCash;
  bool _isSubmitting = false;
  String? _errorMessage;
  Timer? _addressDebounce;
  List<AddressSuggestion> _addressSuggestions = const <AddressSuggestion>[];
  bool _isSearchingAddress = false;
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.session.user.displayName,
    );
    _phoneController = TextEditingController(
      text: widget.session.user.phoneNumber ?? '',
    );
    _idempotencyKey =
        'mobile-${widget.session.user.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    _addressDebounce?.cancel();
    if (_deliveryLatitude != null || _deliveryLongitude != null) {
      _deliveryLatitude = null;
      _deliveryLongitude = null;
    }
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _addressSuggestions = const <AddressSuggestion>[];
        _isSearchingAddress = false;
      });
      return;
    }

    setState(() => _isSearchingAddress = true);
    _addressDebounce = Timer(const Duration(milliseconds: 280), () async {
      try {
        final suggestions = await widget.addressSuggestionService.search(query);
        if (!mounted || _addressController.text.trim() != query) return;
        setState(() {
          _addressSuggestions = suggestions;
          _isSearchingAddress = false;
        });
      } on Object {
        if (!mounted || _addressController.text.trim() != query) return;
        setState(() {
          _addressSuggestions = const <AddressSuggestion>[];
          _isSearchingAddress = false;
        });
      }
    });
  }

  Future<void> _selectAddress(AddressSuggestion suggestion) async {
    _addressDebounce?.cancel();
    _addressController.text = suggestion.fullAddress;
    setState(() {
      _addressSuggestions = const <AddressSuggestion>[];
      _isSearchingAddress = true;
    });
    FocusScope.of(context).unfocus();
    try {
      final resolved = await widget.addressSuggestionService.resolve(
        suggestion,
      );
      if (!mounted) return;
      _addressController.text = resolved.fullAddress;
      setState(() {
        _isSearchingAddress = false;
        _deliveryLatitude = resolved.latitude;
        _deliveryLongitude = resolved.longitude;
      });
      _formKey.currentState?.validate();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isSearchingAddress = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openLocationPicker() async {
    final selection = await Navigator.of(context)
        .push<DeliveryLocationSelection>(
          MaterialPageRoute<DeliveryLocationSelection>(
            builder: (_) => DeliveryLocationPickerPage(
              addressSuggestionService: widget.addressSuggestionService,
              initialAddress: _addressController.text.trim(),
              initialLatitude: _deliveryLatitude,
              initialLongitude: _deliveryLongitude,
              deviceLocationService: widget.deviceLocationService,
            ),
          ),
        );
    if (selection == null || !mounted) return;
    setState(() {
      _deliveryLatitude = selection.latitude;
      _deliveryLongitude = selection.longitude;
      _addressSuggestions = const <AddressSuggestion>[];
    });
    if (selection.formattedAddress?.trim().isNotEmpty == true) {
      _addressController.text = selection.formattedAddress!;
    }
    _formKey.currentState?.validate();
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
          deliveryLatitude: _deliveryLatitude!,
          deliveryLongitude: _deliveryLongitude!,
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
            onChanged: _onAddressChanged,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Delivery address',
              hintText: 'Start with an area, for example Saris',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: _isSearchingAddress
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a complete delivery address.';
              }
              if (_deliveryLatitude == null || _deliveryLongitude == null) {
                return 'Choose a recommendation or select the exact point on the map.';
              }
              return null;
            },
          ),
          if (_addressSuggestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _AddressSuggestions(
              suggestions: _addressSuggestions,
              onSelected: _selectAddress,
            ),
          ],
          const SizedBox(height: 10),
          _DeliveryPinCard(
            latitude: _deliveryLatitude,
            longitude: _deliveryLongitude,
            onChoose: _openLocationPicker,
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

final class _AddressSuggestions extends StatelessWidget {
  const _AddressSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<AddressSuggestion> suggestions;
  final ValueChanged<AddressSuggestion> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x1414273A),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 13, 16, 7),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.deepTeal,
              ),
              SizedBox(width: 7),
              Text(
                'Suggested locations',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        for (var index = 0; index < suggestions.length; index++) ...<Widget>[
          if (index > 0) const Divider(height: 1),
          InkWell(
            onTap: () => onSelected(suggestions[index]),
            borderRadius: index == suggestions.length - 1
                ? const BorderRadius.vertical(bottom: Radius.circular(18))
                : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.mint,
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppTheme.deepTeal,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          suggestions[index].title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestions[index].subtitle,
                          style: const TextStyle(
                            color: AppTheme.inkSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.north_west_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

final class _DeliveryPinCard extends StatelessWidget {
  const _DeliveryPinCard({
    required this.latitude,
    required this.longitude,
    required this.onChoose,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onChoose;

  bool get _hasPin => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _hasPin ? AppTheme.mint : const Color(0xFFFFF8E7),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: _hasPin ? const Color(0xFFB5DDD7) : const Color(0xFFF0D69C),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: _hasPin ? AppTheme.deepTeal : AppTheme.warmGold,
            child: Icon(
              _hasPin
                  ? Icons.location_on_rounded
                  : Icons.add_location_alt_outlined,
              color: _hasPin ? Colors.white : AppTheme.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _hasPin
                      ? 'Exact delivery pin saved'
                      : 'Exact delivery pin required',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasPin
                      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                      : 'Choose any destination directly from the map.',
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChoose,
            child: Text(_hasPin ? 'Change' : 'Open map'),
          ),
        ],
      ),
    ),
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
