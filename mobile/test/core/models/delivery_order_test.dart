import 'package:creavers_delivery_mobile/core/models/delivery_order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/order_fixture.dart';

void main() {
  test(
    'delivery timeline returns the latest persisted milestone timestamp',
    () {
      final order = DeliveryOrder.fromJson(
        orderFixture(
          status: 'PickedUp',
          assignedDriverId: '00000000-0000-0000-0000-000000000300',
          statusHistory: <Object?>[
            _history('New', '2026-09-16T07:00:00Z'),
            _history('Assigned', '2026-09-16T07:05:00Z'),
            _history('Assigned', '2026-09-16T07:08:00Z'),
            _history('Accepted', '2026-09-16T07:10:00Z'),
            _history('PickedUp', '2026-09-16T07:25:00Z'),
          ],
        ),
      );

      expect(
        order.historyFor(DeliveryOrderStatus.assigned)?.changedAtUtc,
        DateTime.parse('2026-09-16T07:08:00Z').toLocal(),
      );
      expect(
        order.historyFor(DeliveryOrderStatus.pickedUp)?.changedAtUtc,
        DateTime.parse('2026-09-16T07:25:00Z').toLocal(),
      );
      expect(order.historyFor(DeliveryOrderStatus.delivered), isNull);
    },
  );
}

Map<String, Object?> _history(String status, String changedAtUtc) =>
    <String, Object?>{
      'status': status,
      'changedByUserId': '00000000-0000-0000-0000-000000000300',
      'changedAtUtc': changedAtUtc,
      'note': '$status milestone',
    };
