enum DeliveryOrderStatus {
  newOrder,
  assigned,
  accepted,
  pickedUp,
  delivered,
  cancelled;

  static DeliveryOrderStatus fromJson(Object? value) =>
      switch (value?.toString().toLowerCase()) {
        'new' => DeliveryOrderStatus.newOrder,
        'assigned' => DeliveryOrderStatus.assigned,
        'accepted' => DeliveryOrderStatus.accepted,
        'pickedup' => DeliveryOrderStatus.pickedUp,
        'delivered' => DeliveryOrderStatus.delivered,
        'cancelled' => DeliveryOrderStatus.cancelled,
        _ => throw FormatException('Unknown order status: $value'),
      };

  String get apiValue => switch (this) {
    DeliveryOrderStatus.newOrder => 'New',
    DeliveryOrderStatus.assigned => 'Assigned',
    DeliveryOrderStatus.accepted => 'Accepted',
    DeliveryOrderStatus.pickedUp => 'PickedUp',
    DeliveryOrderStatus.delivered => 'Delivered',
    DeliveryOrderStatus.cancelled => 'Cancelled',
  };

  String get label => switch (this) {
    DeliveryOrderStatus.newOrder => 'New',
    DeliveryOrderStatus.assigned => 'Assigned',
    DeliveryOrderStatus.accepted => 'Accepted',
    DeliveryOrderStatus.pickedUp => 'Picked up',
    DeliveryOrderStatus.delivered => 'Delivered',
    DeliveryOrderStatus.cancelled => 'Cancelled',
  };

  bool get isTerminal =>
      this == DeliveryOrderStatus.delivered ||
      this == DeliveryOrderStatus.cancelled;
}

enum PaymentMethod {
  demoCash,
  demoCard;

  static PaymentMethod fromJson(Object? value) =>
      switch (value?.toString().toLowerCase()) {
        'democash' => PaymentMethod.demoCash,
        'democard' => PaymentMethod.demoCard,
        _ => throw FormatException('Unknown payment method: $value'),
      };

  String get apiValue => switch (this) {
    PaymentMethod.demoCash => 'DemoCash',
    PaymentMethod.demoCard => 'DemoCard',
  };

  String get label => switch (this) {
    PaymentMethod.demoCash => 'Cash on delivery',
    PaymentMethod.demoCard => 'Demo card',
  };
}

final class CreateOrderLine {
  const CreateOrderLine({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, Object?> toJson() => <String, Object?>{
    'productId': productId,
    'quantity': quantity,
  };
}

final class CreateOrderRequest {
  const CreateOrderRequest({
    required this.idempotencyKey,
    required this.contactName,
    required this.phoneNumber,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.paymentMethod,
    required this.lines,
  });

  final String idempotencyKey;
  final String contactName;
  final String phoneNumber;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final PaymentMethod paymentMethod;
  final List<CreateOrderLine> lines;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'contactName': contactName,
    'phoneNumber': phoneNumber,
    'deliveryAddress': deliveryAddress,
    'deliveryLatitude': deliveryLatitude,
    'deliveryLongitude': deliveryLongitude,
    'paymentMethod': paymentMethod.apiValue,
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
  };
}

final class DeliveryOrderSummary {
  const DeliveryOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.contactName,
    required this.status,
    required this.total,
    required this.createdAtUtc,
    this.assignedDriverId,
  });

  factory DeliveryOrderSummary.fromJson(Map<String, Object?> json) =>
      DeliveryOrderSummary(
        id: json['id']! as String,
        orderNumber: json['orderNumber']! as String,
        contactName: json['contactName']! as String,
        status: DeliveryOrderStatus.fromJson(json['status']),
        total: (json['total']! as num).toDouble(),
        assignedDriverId: json['assignedDriverId'] as String?,
        createdAtUtc: DateTime.parse(json['createdAtUtc']! as String).toUtc(),
      );

  final String id;
  final String orderNumber;
  final String contactName;
  final DeliveryOrderStatus status;
  final double total;
  final String? assignedDriverId;
  final DateTime createdAtUtc;
}

final class DeliveryOrderLine {
  const DeliveryOrderLine({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory DeliveryOrderLine.fromJson(Map<String, Object?> json) =>
      DeliveryOrderLine(
        productId: json['productId']! as String,
        productName: json['productName']! as String,
        unit: json['unit']! as String,
        quantity: json['quantity']! as int,
        unitPrice: (json['unitPrice']! as num).toDouble(),
        lineTotal: (json['lineTotal']! as num).toDouble(),
      );

  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
}

final class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.status,
    required this.changedByUserId,
    required this.changedAtUtc,
    this.note,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, Object?> json) =>
      OrderStatusHistoryEntry(
        status: DeliveryOrderStatus.fromJson(json['status']),
        changedByUserId: json['changedByUserId']! as String,
        changedAtUtc: DateTime.parse(json['changedAtUtc']! as String).toLocal(),
        note: json['note'] as String?,
      );

  final DeliveryOrderStatus status;
  final String changedByUserId;
  final DateTime changedAtUtc;
  final String? note;
}

final class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.contactName,
    required this.phoneNumber,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.lines,
    required this.statusHistory,
    this.assignedDriverId,
    this.deliveryLatitude,
    this.deliveryLongitude,
  });

  factory DeliveryOrder.fromJson(Map<String, Object?> json) => DeliveryOrder(
    id: json['id']! as String,
    orderNumber: json['orderNumber']! as String,
    customerId: json['customerId']! as String,
    assignedDriverId: json['assignedDriverId'] as String?,
    contactName: json['contactName']! as String,
    phoneNumber: json['phoneNumber']! as String,
    deliveryAddress: json['deliveryAddress']! as String,
    deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
    deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
    paymentMethod: PaymentMethod.fromJson(json['paymentMethod']),
    status: DeliveryOrderStatus.fromJson(json['status']),
    subtotal: (json['subtotal']! as num).toDouble(),
    deliveryFee: (json['deliveryFee']! as num).toDouble(),
    total: (json['total']! as num).toDouble(),
    createdAtUtc: DateTime.parse(json['createdAtUtc']! as String).toLocal(),
    updatedAtUtc: DateTime.parse(json['updatedAtUtc']! as String).toLocal(),
    lines: (json['lines']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(DeliveryOrderLine.fromJson)
        .toList(growable: false),
    statusHistory: (json['statusHistory']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(OrderStatusHistoryEntry.fromJson)
        .toList(growable: false),
  );

  final String id;
  final String orderNumber;
  final String customerId;
  final String? assignedDriverId;
  final String contactName;
  final String phoneNumber;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final PaymentMethod paymentMethod;
  final DeliveryOrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final List<DeliveryOrderLine> lines;
  final List<OrderStatusHistoryEntry> statusHistory;
}
