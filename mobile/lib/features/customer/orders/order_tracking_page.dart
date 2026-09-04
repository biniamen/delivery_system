import 'dart:async';

import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/services/customer_order_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/shared/widgets/live_driver_map.dart';
import 'package:creavers_delivery_mobile/shared/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';

final class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({
    required this.initialOrder,
    required this.orderService,
    this.locationService,
    super.key,
  });

  final DeliveryOrder initialOrder;
  final CustomerOrderService orderService;
  final DriverLocationService? locationService;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

final class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late DeliveryOrder _order;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DriverLocation? _driverLocation;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_order.status.isTerminal) _refresh(silent: true);
    });
    if (_order.assignedDriverId != null) _refresh(silent: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final refreshed = await widget.orderService.fetchOrder(_order.id);
      DriverLocation? location;
      if (refreshed.assignedDriverId != null &&
          widget.locationService != null) {
        try {
          location = await widget.locationService!.fetchForOrder(_order.id);
        } on Object {
          location = _driverLocation;
        }
      }
      if (mounted) {
        setState(() {
          _order = refreshed;
          _driverLocation = location;
        });
      }
    } on Object catch (error) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh this order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Track order'),
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh order status',
          onPressed: _isRefreshing ? null : _refresh,
          icon: _isRefreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          _TrackingHero(order: _order),
          if (_order.assignedDriverId != null &&
              widget.locationService != null) ...<Widget>[
            const SizedBox(height: 18),
            _LiveDeliveryMapCard(location: _driverLocation),
          ],
          const SizedBox(height: 18),
          _DeliveryProgress(order: _order),
          const SizedBox(height: 18),
          _DeliveryCard(order: _order),
          const SizedBox(height: 18),
          _OrderItemsCard(order: _order),
          const SizedBox(height: 18),
          _ActivityCard(order: _order),
        ],
      ),
    ),
  );
}

final class _LiveDeliveryMapCard extends StatelessWidget {
  const _LiveDeliveryMapCard({required this.location});

  final DriverLocation? location;

  String get _movementLabel {
    final speed = location?.speedMetersPerSecond;
    if (speed == null) return 'Speed unavailable';
    final kilometresPerHour = speed * 3.6;
    return kilometresPerHour < 1
        ? 'Driver stopped'
        : '${kilometresPerHour.round()} km/h';
  }

  String _updatedLabel(BuildContext context) {
    final captured = location?.capturedAtUtc;
    if (captured == null) return 'Waiting for first location update';
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(captured));
    return 'Updated $time · refreshes every 5 sec';
  }

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
                    'Driver map',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  location?.freshness.label ?? 'Waiting',
                  style: TextStyle(
                    color: location?.freshness == LocationFreshness.live
                        ? const Color(0xFF16794B)
                        : AppTheme.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          LiveDriverMap(
            location: location,
            height: 270,
            emptyLabel: 'Waiting for GPS',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  location?.hasCoordinates == true
                      ? location!.displayName
                      : 'The pin appears when your driver starts sharing.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MapFact(icon: Icons.speed_rounded, label: _movementLabel),
                    _MapFact(
                      icon: Icons.gps_fixed_rounded,
                      label: location?.accuracyMeters == null
                          ? 'GPS accuracy pending'
                          : '±${location!.accuracyMeters!.round()} m accuracy',
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  _updatedLabel(context),
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _MapFact extends StatelessWidget {
  const _MapFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.mint,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.deepTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

final class _TrackingHero extends StatelessWidget {
  const _TrackingHero({required this.order});

  final DeliveryOrder order;

  String get _title => switch (order.status) {
    DeliveryOrderStatus.newOrder => 'Order received',
    DeliveryOrderStatus.assigned => 'A driver is assigned',
    DeliveryOrderStatus.accepted => 'Your driver accepted',
    DeliveryOrderStatus.pickedUp => 'Your order is on the way',
    DeliveryOrderStatus.delivered => 'Delivered successfully',
    DeliveryOrderStatus.cancelled => 'Order cancelled',
  };

  String get _message => switch (order.status) {
    DeliveryOrderStatus.newOrder =>
      'Dispatch is reviewing your order and will assign a driver shortly.',
    DeliveryOrderStatus.assigned =>
      'The driver can now accept this delivery in the driver app.',
    DeliveryOrderStatus.accepted =>
      'Your driver is preparing to collect the supermarket order.',
    DeliveryOrderStatus.pickedUp =>
      'The products have been collected and are heading to your address.',
    DeliveryOrderStatus.delivered =>
      'Thank you for choosing Creavers supermarket delivery.',
    DeliveryOrderStatus.cancelled =>
      'This order will not be delivered. Contact dispatch for assistance.',
  };

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[AppTheme.deepTeal, AppTheme.teal],
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
            _title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(_message, style: const TextStyle(color: Color(0xFFE7F2F1))),
        ],
      ),
    ),
  );
}

final class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.order});

  final DeliveryOrder order;

  static const _steps = <(DeliveryOrderStatus, String, IconData)>[
    (DeliveryOrderStatus.newOrder, 'Placed', Icons.receipt_long_outlined),
    (DeliveryOrderStatus.assigned, 'Assigned', Icons.person_pin_outlined),
    (DeliveryOrderStatus.accepted, 'Accepted', Icons.thumb_up_outlined),
    (DeliveryOrderStatus.pickedUp, 'Picked up', Icons.local_shipping_outlined),
    (DeliveryOrderStatus.delivered, 'Delivered', Icons.home_outlined),
  ];

  int get _currentIndex => _steps.indexWhere((step) => step.$1 == order.status);

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Delivery progress',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _steps.length; index++)
            _ProgressRow(
              icon: _steps[index].$3,
              label: _steps[index].$2,
              completed:
                  order.status != DeliveryOrderStatus.cancelled &&
                  index <= _currentIndex,
              current: index == _currentIndex,
              showLine: index < _steps.length - 1,
            ),
        ],
      ),
    ),
  );
}

final class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.label,
    required this.completed,
    required this.current,
    required this.showLine,
  });

  final IconData icon;
  final String label;
  final bool completed;
  final bool current;
  final bool showLine;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: 38,
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: completed ? AppTheme.deepTeal : AppTheme.mint,
                child: Icon(
                  completed ? Icons.check : icon,
                  size: 17,
                  color: completed ? Colors.white : AppTheme.inkSoft,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    color: completed ? AppTheme.deepTeal : AppTheme.border,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 24),
            child: Text(
              label,
              style: TextStyle(
                color: completed ? AppTheme.ink : AppTheme.inkSoft,
                fontWeight: current ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
        if (current)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Current',
              style: TextStyle(
                color: AppTheme.deepTeal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    ),
  );
}

final class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

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
            'Delivery details',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.person_outline, value: order.contactName),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.phone_outlined, value: order.phoneNumber),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.location_on_outlined,
            value: order.deliveryAddress,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.payments_outlined,
            value: order.paymentMethod.label,
          ),
        ],
      ),
    ),
  );
}

final class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Order summary',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text('${order.lines.length} lines'),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${line.quantity} × ${line.productName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('ETB ${line.lineTotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
          const Divider(height: 24),
          _MoneyRow(label: 'Subtotal', value: order.subtotal),
          const SizedBox(height: 8),
          _MoneyRow(label: 'Delivery fee', value: order.deliveryFee),
          const SizedBox(height: 12),
          _MoneyRow(label: 'Total', value: order.total, strong: true),
        ],
      ),
    ),
  );
}

final class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.order});

  final DeliveryOrder order;

  String _date(BuildContext context, DateTime value) {
    final date = MaterialLocalizations.of(context).formatShortDate(value);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(value));
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Order activity',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          for (final entry in order.statusHistory.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: AppTheme.deepTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.status.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _date(context, entry.changedAtUtc),
                          style: const TextStyle(
                            color: AppTheme.inkSoft,
                            fontSize: 12,
                          ),
                        ),
                        if (entry.note case final note?)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(note),
                          ),
                      ],
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

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 20, color: AppTheme.deepTeal),
      const SizedBox(width: 12),
      Expanded(child: Text(value)),
    ],
  );
}

final class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: strong ? AppTheme.ink : AppTheme.inkSoft,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        'ETB ${value.toStringAsFixed(2)}',
        style: TextStyle(
          color: strong ? AppTheme.deepTeal : AppTheme.ink,
          fontSize: strong ? 18 : 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
