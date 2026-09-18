Map<String, Object?> orderFixture({
  String status = 'New',
  String? assignedDriverId,
  List<Object?>? statusHistory,
}) => <String, Object?>{
  'id': '00000000-0000-0000-0000-000000000100',
  'orderNumber': 'CRV-20260831-TEST01',
  'customerId': '00000000-0000-0000-0000-000000000001',
  'assignedDriverId': assignedDriverId,
  'contactName': 'Demo Customer',
  'phoneNumber': '+251911234567',
  'deliveryAddress': 'Bole, Addis Ababa',
  'paymentMethod': 'DemoCash',
  'status': status,
  'subtotal': 120,
  'deliveryFee': 80,
  'total': 200,
  'createdAtUtc': '2026-08-31T07:00:00Z',
  'updatedAtUtc': '2026-08-31T07:00:00Z',
  'lines': <Object?>[
    <String, Object?>{
      'productId': '00000000-0000-0000-0000-000000000200',
      'productName': 'Fresh Milk',
      'unit': '1 litre',
      'quantity': 2,
      'unitPrice': 60,
      'lineTotal': 120,
    },
  ],
  'statusHistory':
      statusHistory ??
      <Object?>[
        <String, Object?>{
          'status': 'New',
          'changedByUserId': '00000000-0000-0000-0000-000000000001',
          'changedAtUtc': '2026-08-31T07:00:00Z',
          'note': 'Order placed',
        },
      ],
};
