import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:flutter/material.dart';

final class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});

  final DeliveryOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      DeliveryOrderStatus.assigned => (
        const Color(0xFFE7F0FF),
        const Color(0xFF215FA6),
      ),
      DeliveryOrderStatus.accepted => (
        const Color(0xFFFFF0D1),
        const Color(0xFF8A5900),
      ),
      DeliveryOrderStatus.pickedUp => (
        const Color(0xFFEDE7FF),
        const Color(0xFF5D3CA3),
      ),
      DeliveryOrderStatus.delivered => (
        const Color(0xFFDDF5EA),
        const Color(0xFF146B50),
      ),
      DeliveryOrderStatus.cancelled => (
        const Color(0xFFFFE3E1),
        const Color(0xFFA12C26),
      ),
      DeliveryOrderStatus.newOrder => (
        const Color(0xFFECEFF3),
        const Color(0xFF425466),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          status.label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
