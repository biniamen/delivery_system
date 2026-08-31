import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/models/auth_session.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_order_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/features/driver/driver_order_detail_page.dart';
import 'package:creavers_delivery_mobile/features/driver/location/driver_location_controller.dart';
import 'package:creavers_delivery_mobile/shared/widgets/empty_state_card.dart';
import 'package:creavers_delivery_mobile/shared/widgets/live_driver_map.dart';
import 'package:creavers_delivery_mobile/shared/widgets/loading_view.dart';
import 'package:creavers_delivery_mobile/shared/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';

final class DriverHomePage extends StatefulWidget {
  const DriverHomePage({
    required this.controller,
    required this.session,
    required this.orderService,
    required this.locationService,
    required this.deviceLocationService,
    super.key,
  });

  final AppController controller;
  final AuthSession session;
  final DriverOrderService orderService;
  final DriverLocationService locationService;
  final DeviceLocationService deviceLocationService;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

final class _DriverHomePageState extends State<DriverHomePage> {
  late Future<List<DeliveryOrderSummary>> _orders;
  late final DriverLocationController _location;
  String? _transitioningOrderId;

  @override
  void initState() {
    super.initState();
    _orders = widget.orderService.fetchAssignedOrders();
    _location = DriverLocationController(
      widget.deviceLocationService,
      widget.locationService,
    );
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = widget.orderService.fetchAssignedOrders();
    setState(() => _orders = next);
    await next;
  }

  DeliveryOrderStatus? _nextStatus(DeliveryOrderStatus current) =>
      switch (current) {
        DeliveryOrderStatus.assigned => DeliveryOrderStatus.accepted,
        DeliveryOrderStatus.accepted => DeliveryOrderStatus.pickedUp,
        DeliveryOrderStatus.pickedUp => DeliveryOrderStatus.delivered,
        _ => null,
      };

  String _actionLabel(DeliveryOrderStatus next) => switch (next) {
    DeliveryOrderStatus.accepted => 'Accept delivery',
    DeliveryOrderStatus.pickedUp => 'Mark picked up',
    DeliveryOrderStatus.delivered => 'Mark delivered',
    _ => 'Update',
  };

  Future<void> _advance(DeliveryOrderSummary order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;
    setState(() => _transitioningOrderId = order.id);
    try {
      await widget.orderService.transitionOrder(
        orderId: order.id,
        status: next,
        note: 'Updated from the Creavers driver app',
      );
      await _refresh();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update the order: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _transitioningOrderId = null);
    }
  }

  Future<void> _openOrder(DeliveryOrderSummary order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DriverOrderDetailPage(
          orderId: order.id,
          orderService: widget.orderService,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Driver route'),
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh assignments',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.controller.logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: FutureBuilder<List<DeliveryOrderSummary>>(
      future: _orders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(label: 'Loading assigned deliveries…');
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: EmptyStateCard(
              icon: Icons.sync_problem_outlined,
              title: 'Assignments unavailable',
              message: snapshot.error.toString(),
              action: FilledButton.tonal(
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
            ),
          );
        }

        final orders = snapshot.data ?? const <DeliveryOrderSummary>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: <Widget>[
              _DriverWelcome(
                displayName: widget.session.user.displayName,
                assignmentCount: orders
                    .where((order) => !order.status.isTerminal)
                    .length,
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _location,
                builder: (context, _) =>
                    _LocationSharingCard(controller: _location),
              ),
              const SizedBox(height: 22),
              if (orders.isEmpty)
                const EmptyStateCard(
                  icon: Icons.route_outlined,
                  title: 'No assigned deliveries',
                  message: 'New assignments from dispatch will appear here.',
                )
              else
                for (final order in orders) ...<Widget>[
                  _OrderCard(
                    order: order,
                    nextStatus: _nextStatus(order.status),
                    isUpdating: _transitioningOrderId == order.id,
                    actionLabel: _nextStatus(order.status) == null
                        ? null
                        : _actionLabel(_nextStatus(order.status)!),
                    onAdvance: () => _advance(order),
                    onOpen: () => _openOrder(order),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    ),
  );
}

final class _DriverWelcome extends StatelessWidget {
  const _DriverWelcome({
    required this.displayName,
    required this.assignmentCount,
  });

  final String displayName;
  final int assignmentCount;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[AppTheme.deepTeal, Color(0xFF16757A)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 27,
            backgroundColor: AppTheme.warmGold,
            child: Icon(Icons.local_shipping_outlined, color: AppTheme.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ready, $displayName?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$assignmentCount active assignment${assignmentCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Color(0xFFD4E8E8)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _LocationSharingCard extends StatelessWidget {
  const _LocationSharingCard({required this.controller});

  final DriverLocationController controller;

  String get _message => switch (controller.state) {
    LocationSharingState.idle => 'Share only while you are on duty.',
    LocationSharingState.starting => 'Checking GPS and permission…',
    LocationSharingState.sharing =>
      controller.latest == null
          ? 'Finding your position…'
          : 'Visible to dispatch and assigned customers.',
    LocationSharingState.serviceDisabled =>
      'Turn on device location, then retry.',
    LocationSharingState.denied => 'Location permission was not granted.',
    LocationSharingState.deniedForever =>
      'Allow location in device settings, then retry.',
    LocationSharingState.failed =>
      controller.errorMessage ?? 'Location sharing stopped unexpectedly.',
  };

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: controller.isSharing
                      ? const Color(0xFFE4F6ED)
                      : AppTheme.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.square(
                  dimension: 42,
                  child: Icon(
                    controller.isSharing
                        ? Icons.gps_fixed_rounded
                        : Icons.location_searching_rounded,
                    color: controller.isSharing
                        ? const Color(0xFF16794B)
                        : AppTheme.deepTeal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Live location',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (controller.isSharing) const _LivePill(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _message,
                      style: const TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (controller.latest != null) ...<Widget>[
            const SizedBox(height: 14),
            LiveDriverMap(location: controller.latest, height: 190),
            const SizedBox(height: 9),
            Text(
              '±${controller.latest!.accuracyMeters?.round() ?? 0} m · updated ${_time(context, controller.latest!.receivedAtUtc)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          if (controller.isSharing)
            OutlinedButton.icon(
              onPressed: controller.stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop sharing'),
            )
          else
            FilledButton.icon(
              onPressed: controller.state == LocationSharingState.starting
                  ? null
                  : controller.start,
              icon: controller.state == LocationSharingState.starting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.near_me_outlined),
              label: const Text('Start sharing'),
            ),
        ],
      ),
    ),
  );

  String _time(BuildContext context, DateTime? value) => value == null
      ? 'now'
      : MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(value));
}

final class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE4F6ED),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'LIVE',
        style: TextStyle(
          color: Color(0xFF16794B),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .08,
        ),
      ),
    ),
  );
}

final class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.nextStatus,
    required this.isUpdating,
    required this.actionLabel,
    required this.onAdvance,
    required this.onOpen,
  });

  final DeliveryOrderSummary order;
  final DeliveryOrderStatus? nextStatus;
  final bool isUpdating;
  final String? actionLabel;
  final VoidCallback onAdvance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          _OrderDetail(icon: Icons.person_outline, value: order.contactName),
          const SizedBox(height: 8),
          _OrderDetail(
            icon: Icons.payments_outlined,
            value: 'ETB ${order.total.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _OrderDetail(
            icon: Icons.schedule,
            value:
                '${order.createdAtUtc.day}/${order.createdAtUtc.month}/${order.createdAtUtc.year}',
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.route_outlined),
            label: const Text('Open delivery details'),
          ),
          if (nextStatus != null) ...<Widget>[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: isUpdating ? null : onAdvance,
              icon: isUpdating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(isUpdating ? 'Updating…' : actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

final class _OrderDetail extends StatelessWidget {
  const _OrderDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Expanded(child: Text(value)),
    ],
  );
}
