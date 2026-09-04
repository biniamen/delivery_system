import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/customer/orders/order_tracking_page.dart';
import 'package:creavers_delivery_mobile/shared/widgets/empty_state_card.dart';
import 'package:creavers_delivery_mobile/shared/widgets/loading_view.dart';
import 'package:creavers_delivery_mobile/shared/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';

final class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({
    required this.orderService,
    this.locationService,
    super.key,
  });

  final CustomerOrderService orderService;
  final DriverLocationService? locationService;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

final class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  late Future<List<DeliveryOrderSummary>> _orders;
  String? _openingOrderId;

  @override
  void initState() {
    super.initState();
    _orders = widget.orderService.fetchMyOrders();
  }

  Future<void> _refresh() async {
    final next = widget.orderService.fetchMyOrders();
    setState(() => _orders = next);
    await next;
  }

  Future<void> _openOrder(DeliveryOrderSummary summary) async {
    if (_openingOrderId != null) return;
    setState(() => _openingOrderId = summary.id);
    try {
      final order = await widget.orderService.fetchOrder(summary.id);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => OrderTrackingPage(
            initialOrder: order,
            orderService: widget.orderService,
            locationService: widget.locationService,
          ),
        ),
      );
      if (mounted) await _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this order. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My orders')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<DeliveryOrderSummary>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(label: 'Loading your orders…');
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                EmptyStateCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Orders unavailable',
                  message: 'Check your connection, then pull down to retry.',
                  action: FilledButton(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            );
          }

          final orders = snapshot.data ?? const <DeliveryOrderSummary>[];
          if (orders.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const <Widget>[
                SizedBox(height: 72),
                EmptyStateCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Your placed orders will appear here with live delivery progress.',
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            itemCount: orders.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              if (index == 0) return _OrdersHero(orderCount: orders.length);
              final order = orders[index - 1];
              return _OrderCard(
                order: order,
                isOpening: _openingOrderId == order.id,
                onTap: () => _openOrder(order),
              );
            },
          );
        },
      ),
    ),
  );
}

final class _OrdersHero extends StatelessWidget {
  const _OrdersHero({required this.orderCount});

  final int orderCount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[AppTheme.deepTeal, AppTheme.teal],
      ),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: <Widget>[
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0x20FFFFFF),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 52,
            child: Icon(Icons.route_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$orderCount ${orderCount == 1 ? 'order' : 'orders'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Track every delivery from dispatch to your door.',
                style: TextStyle(color: Color(0xFFDCECEA), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isOpening,
    required this.onTap,
  });

  final DeliveryOrderSummary order;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: AppTheme.inkSoft,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(order.createdAtUtc.toLocal()),
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'ETB ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.deepTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                if (isOpening)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  static String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${months[value.month - 1]} ${value.day} · $hour:$minute $suffix';
  }
}
