import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/catalogue.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/catalogue_service.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_controller.dart';
import 'package:creavers_delivery_mobile/features/customer/cart/cart_page.dart';
import 'package:creavers_delivery_mobile/features/customer/orders/customer_orders_page.dart';
import 'package:creavers_delivery_mobile/features/customer/orders/order_tracking_page.dart';
import 'package:creavers_delivery_mobile/shared/widgets/empty_state_card.dart';
import 'package:creavers_delivery_mobile/shared/widgets/loading_view.dart';
import 'package:creavers_delivery_mobile/shared/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';

final class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    required this.controller,
    required this.session,
    required this.catalogueService,
    required this.orderService,
    required this.addressSuggestionService,
    this.locationService,
    super.key,
  });

  final AppController controller;
  final AuthSession session;
  final CatalogueService catalogueService;
  final CustomerOrderService orderService;
  final AddressSuggestionService addressSuggestionService;
  final DriverLocationService? locationService;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

final class _CustomerHomePageState extends State<CustomerHomePage> {
  late Future<List<CatalogueCategory>> _catalogue;
  late final CartController _cart;
  late final TextEditingController _searchController;
  DeliveryOrder? _latestOrder;
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _cart = CartController();
    _searchController = TextEditingController();
    _catalogue = widget.catalogueService.fetchCatalogue();
    _loadLatestOrder();
  }

  @override
  void dispose() {
    _cart.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = widget.catalogueService.fetchCatalogue();
    setState(() => _catalogue = next);
    await Future.wait<Object?>(<Future<Object?>>[next, _loadLatestOrder()]);
  }

  Future<void> _loadLatestOrder() async {
    try {
      final summaries = await widget.orderService.fetchMyOrders();
      if (summaries.isEmpty) return;
      final latest = await widget.orderService.fetchOrder(summaries.first.id);
      if (mounted) setState(() => _latestOrder = latest);
    } on Object {
      // Keep shopping available if order history is temporarily unreachable.
    }
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomerOrdersPage(
          orderService: widget.orderService,
          locationService: widget.locationService,
        ),
      ),
    );
    await _loadLatestOrder();
  }

  Future<void> _openCart() async {
    final order = await Navigator.of(context).push<DeliveryOrder>(
      MaterialPageRoute<DeliveryOrder>(
        builder: (_) => CartPage(
          cart: _cart,
          session: widget.session,
          orderService: widget.orderService,
          addressSuggestionService: widget.addressSuggestionService,
        ),
      ),
    );
    if (order == null || !mounted) return;
    setState(() => _latestOrder = order);
    await _trackOrder();
  }

  Future<void> _trackOrder() async {
    final order = _latestOrder;
    if (order == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderTrackingPage(
          initialOrder: order,
          orderService: widget.orderService,
          locationService: widget.locationService,
        ),
      ),
    );
    try {
      final refreshed = await widget.orderService.fetchOrder(order.id);
      if (mounted) setState(() => _latestOrder = refreshed);
    } on Object {
      // The tracking screen already exposes refresh errors; keep the last state.
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _cart,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const _CompactBrand(),
        actions: <Widget>[
          IconButton(
            tooltip: 'My orders',
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Refresh catalogue',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.mint,
              child: Text(
                widget.session.user.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.deepTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') widget.controller.logout();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<CatalogueCategory>>(
        future: _catalogue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Preparing the fresh catalogue…');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: EmptyStateCard(
                icon: Icons.cloud_off_outlined,
                title: 'Catalogue unavailable',
                message: snapshot.error.toString(),
                action: FilledButton.tonal(
                  onPressed: _refresh,
                  child: const Text('Try again'),
                ),
              ),
            );
          }

          final categories = snapshot.data ?? const <CatalogueCategory>[];
          final visibleCategories = _filterCategories(categories);
          final visibleProductCount = visibleCategories.fold<int>(
            0,
            (total, category) => total + category.products.length,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 8, 20, _cart.isEmpty ? 36 : 120),
              children: <Widget>[
                _CustomerHero(
                  displayName: widget.session.user.displayName,
                  productCount: categories.fold<int>(
                    0,
                    (total, category) => total + category.products.length,
                  ),
                ),
                if (_latestOrder case final order?) ...<Widget>[
                  const SizedBox(height: 16),
                  _LatestOrderCard(order: order, onTrack: _trackOrder),
                ],
                const SizedBox(height: 20),
                _CatalogueSearch(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      ),
                      for (final category in categories) ...<Widget>[
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: category.name,
                          selected: _selectedCategoryId == category.id,
                          onTap: () =>
                              setState(() => _selectedCategoryId = category.id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Browse',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '$visibleProductCount items',
                      style: const TextStyle(color: AppTheme.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visibleCategories.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.search_off_rounded,
                    title: 'No match',
                    message: 'Try another product or category.',
                  )
                else
                  for (final category in visibleCategories) ...<Widget>[
                    _CategorySection(category: category, cart: _cart),
                    const SizedBox(height: 24),
                  ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x2914273A),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _openCart,
                  borderRadius: BorderRadius.circular(19),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    child: Row(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppTheme.warmGold,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: 34,
                            child: Center(
                              child: Text(
                                '${_cart.itemCount}',
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Text(
                            'View basket',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          'ETB ${_cart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );

  List<CatalogueCategory> _filterCategories(
    List<CatalogueCategory> categories,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    return categories
        .where(
          (category) =>
              _selectedCategoryId == null || category.id == _selectedCategoryId,
        )
        .map(
          (category) => CatalogueCategory(
            id: category.id,
            name: category.name,
            slug: category.slug,
            products: query.isEmpty
                ? category.products
                : category.products
                      .where(
                        (product) =>
                            product.name.toLowerCase().contains(query) ||
                            product.description.toLowerCase().contains(query),
                      )
                      .toList(growable: false),
          ),
        )
        .where((category) => category.products.isNotEmpty)
        .toList(growable: false);
  }
}

final class _CatalogueSearch extends StatelessWidget {
  const _CatalogueSearch({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Search products',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
            ),
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
    ),
  );
}

final class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppTheme.ink,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
    selectedColor: AppTheme.deepTeal,
    side: const BorderSide(color: AppTheme.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
  );
}

final class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.deepTeal,
          borderRadius: BorderRadius.all(Radius.circular(11)),
        ),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: Text(
              'C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
      SizedBox(width: 10),
      Text('Creavers', style: TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

final class _CustomerHero extends StatelessWidget {
  const _CustomerHero({required this.displayName, required this.productCount});

  final String displayName;
  final int productCount;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[AppTheme.deepTeal, AppTheme.teal],
      ),
      borderRadius: BorderRadius.circular(27),
    ),
    child: Stack(
      children: <Widget>[
        const Positioned(
          right: -28,
          bottom: -34,
          child: Icon(
            Icons.shopping_basket,
            color: Color(0x1AFFFFFF),
            size: 150,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warmGold),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'FRESH · FAST · TRACKED',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFD6E8E6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Good shopping,\n$displayName.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$productCount essentials ready to order.',
                style: const TextStyle(color: Color(0xFFE7F2F1)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _LatestOrderCard extends StatelessWidget {
  const _LatestOrderCard({required this.order, required this.onTrack});

  final DeliveryOrder order;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: InkWell(
      onTap: onTrack,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              backgroundColor: AppTheme.mint,
              child: Icon(Icons.local_shipping_outlined),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Your latest order',
                    style: TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            OrderStatusChip(status: order.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

final class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.cart});

  final CatalogueCategory category;
  final CartController cart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${category.products.length} items',
            style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 11),
      for (final product in category.products) ...<Widget>[
        _ProductCard(product: product, cart: cart),
        const SizedBox(height: 10),
      ],
    ],
  );
}

final class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.cart});

  final Product product;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final quantity = cart.quantityFor(product);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(17),
              ),
              child: SizedBox.square(
                dimension: 62,
                child: Center(
                  child: Text(
                    product.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.deepTeal,
                      fontSize: 24,
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
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.unit,
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: <Widget>[
                      Text(
                        'ETB ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.deepTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.circle,
                            color: product.stockQuantity <= 10
                                ? AppTheme.warmGold
                                : const Color(0xFF23A66F),
                            size: 7,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.stockQuantity <= 10
                                ? '${product.stockQuantity} left'
                                : 'In stock',
                            style: const TextStyle(
                              color: AppTheme.inkSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (quantity == 0)
              FilledButton.tonal(
                onPressed: () => cart.add(product),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Add'),
              )
            else
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
                      onPressed: () => cart.decrement(product),
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
                      onPressed: !cart.canAdd(product)
                          ? null
                          : () => cart.add(product),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
