import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_route.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/delivery_route_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/shared/widgets/live_driver_map.dart';
import 'package:creavers_delivery_mobile/shared/widgets/loading_view.dart';
import 'package:creavers_delivery_mobile/shared/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';

final class DriverOrderDetailPage extends StatefulWidget {
  const DriverOrderDetailPage({
    required this.orderId,
    required this.orderService,
    this.locationService,
    this.deliveryRouteService,
    super.key,
  });

  final String orderId;
  final DriverOrderService orderService;
  final DriverLocationService? locationService;
  final DeliveryRouteService? deliveryRouteService;

  @override
  State<DriverOrderDetailPage> createState() => _DriverOrderDetailPageState();
}

final class _DriverOrderDetailPageState extends State<DriverOrderDetailPage> {
  late Future<DeliveryOrder> _orderFuture;
  DeliveryOrder? _order;
  bool _isUpdating = false;
  DriverLocation? _driverLocation;
  DeliveryRoute? _route;

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrderData();
  }

  Future<void> _refresh() async {
    final next = _loadOrderData();
    setState(() => _orderFuture = next);
    final order = await next;
    if (mounted) setState(() => _order = order);
  }

  Future<DeliveryOrder> _loadOrderData() async {
    final order = await widget.orderService.fetchOrder(widget.orderId);
    DriverLocation? location = _driverLocation;
    DeliveryRoute? route = _route;
    if (widget.locationService != null) {
      try {
        location = await widget.locationService!.fetchForOrder(order.id);
      } on Object {
        // Retain the most recent valid location if GPS is temporarily delayed.
      }
    }
    if (widget.deliveryRouteService != null) {
      try {
        route = await widget.deliveryRouteService!.fetchForOrder(order.id);
      } on Object {
        // Route is supplemental; delivery workflow remains available offline.
      }
    }
    if (mounted) {
      setState(() {
        _driverLocation = location;
        _route = route;
      });
    }
    return order;
  }

  DeliveryOrderStatus? _nextStatus(DeliveryOrderStatus status) =>
      switch (status) {
        DeliveryOrderStatus.assigned => DeliveryOrderStatus.accepted,
        DeliveryOrderStatus.accepted => DeliveryOrderStatus.pickedUp,
        DeliveryOrderStatus.pickedUp => DeliveryOrderStatus.delivered,
        _ => null,
      };

  String _actionLabel(DeliveryOrderStatus status) => switch (status) {
    DeliveryOrderStatus.accepted => 'Accept this delivery',
    DeliveryOrderStatus.pickedUp => 'Confirm supermarket pickup',
    DeliveryOrderStatus.delivered => 'Confirm delivered',
    _ => 'Update order',
  };

  Future<void> _advance() async {
    final order = _order;
    if (order == null) return;
    final next = _nextStatus(order.status);
    if (next == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.mint,
                child: Icon(_actionIcon(next), color: AppTheme.deepTeal),
              ),
              const SizedBox(height: 16),
              Text(
                _actionLabel(next),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'This update is recorded in the delivery audit trail and becomes visible to dispatch and the customer.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.inkSoft),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm update'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not yet'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final updated = await widget.orderService.transitionOrder(
        orderId: order.id,
        status: next,
        note: 'Updated from the Creavers driver app',
      );
      if (mounted) {
        setState(() {
          _order = updated;
          _orderFuture = Future<DeliveryOrder>.value(updated);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked ${next.label.toLowerCase()}.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  IconData _actionIcon(DeliveryOrderStatus status) => switch (status) {
    DeliveryOrderStatus.accepted => Icons.thumb_up_outlined,
    DeliveryOrderStatus.pickedUp => Icons.inventory_2_outlined,
    DeliveryOrderStatus.delivered => Icons.task_alt,
    _ => Icons.arrow_forward,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Delivery details'),
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh delivery',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<DeliveryOrder>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(label: 'Loading delivery details…');
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.sync_problem_outlined, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Delivery details unavailable',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        _order ??= snapshot.data;
        final order = _order!;
        final next = _nextStatus(order.status);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              _DriverDeliveryHero(order: order),
              const SizedBox(height: 16),
              _DriverNavigationCard(
                order: order,
                location: _driverLocation,
                route: _route,
              ),
              const SizedBox(height: 16),
              _DriverStopCard(order: order),
              const SizedBox(height: 16),
              _DriverItemsCard(order: order),
              if (next != null) ...<Widget>[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _isUpdating ? null : _advance,
                  icon: _isUpdating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_actionIcon(next)),
                  label: Text(
                    _isUpdating ? 'Updating delivery…' : _actionLabel(next),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

final class _DriverNavigationCard extends StatelessWidget {
  const _DriverNavigationCard({
    required this.order,
    required this.location,
    required this.route,
  });

  final DeliveryOrder order;
  final DriverLocation? location;
  final DeliveryRoute? route;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Live route',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (route case final currentRoute?)
                  Text(
                    '${currentRoute.durationText} · ${currentRoute.distanceText}',
                    style: const TextStyle(
                      color: AppTheme.deepTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          LiveDriverMap(
            location: location,
            destinationLatitude: order.deliveryLatitude,
            destinationLongitude: order.deliveryLongitude,
            route: route,
            height: 280,
            emptyLabel: 'Start GPS sharing',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 10, 6, 2),
            child: Text(
              'Traffic-aware route refreshes as your reported position changes.',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _DriverDeliveryHero extends StatelessWidget {
  const _DriverDeliveryHero({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[AppTheme.ink, AppTheme.deepTeal],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: Color(0xFFD6E8E6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            order.contactName,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            '${order.lines.length} product lines · ETB ${order.total.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFFE7F2F1)),
          ),
        ],
      ),
    ),
  );
}

final class _DriverStopCard extends StatelessWidget {
  const _DriverStopCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Customer stop',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _StopRow(icon: Icons.phone_outlined, value: order.phoneNumber),
          const SizedBox(height: 13),
          _StopRow(
            icon: Icons.location_on_outlined,
            value: order.deliveryAddress,
          ),
          const SizedBox(height: 13),
          _StopRow(
            icon: Icons.payments_outlined,
            value: order.paymentMethod.label,
          ),
        ],
      ),
    ),
  );
}

final class _DriverItemsCard extends StatelessWidget {
  const _DriverItemsCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Pickup checklist',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.check_box_outline_blank,
                    color: AppTheme.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${line.quantity} × ${line.unit}',
                    style: const TextStyle(color: AppTheme.inkSoft),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

final class _StopRow extends StatelessWidget {
  const _StopRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.mint,
          borderRadius: BorderRadius.circular(11),
        ),
        child: SizedBox.square(
          dimension: 36,
          child: Icon(icon, color: AppTheme.deepTeal, size: 19),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(value),
        ),
      ),
    ],
  );
}
