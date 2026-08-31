import 'dart:convert';

import 'package:creavers_delivery_mobile/core/config/app_config.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/network/api_client.dart';
import 'package:creavers_delivery_mobile/core/network/http_transport.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_transport.dart';

void main() {
  test('publishes the driver position using the location contract', () async {
    final transport = FakeHttpTransport(
      TransportResponse(statusCode: 200, body: jsonEncode(_locationJson())),
    );
    final client = ApiClient(
      transport,
      config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
    )..accessToken = 'driver-token';
    final service = ApiDriverLocationService(client);
    final capturedAt = DateTime.utc(2026, 8, 31, 11, 45);

    final location = await service.publish(
      DevicePosition(
        latitude: 9.02,
        longitude: 38.754,
        accuracyMeters: 6.5,
        headingDegrees: 68,
        speedMetersPerSecond: 7.2,
        capturedAtUtc: capturedAt,
      ),
    );

    final body =
        jsonDecode(transport.lastRequest!.body!) as Map<String, Object?>;
    expect(transport.lastRequest?.method, 'POST');
    expect(
      transport.lastRequest?.uri.toString(),
      'http://127.0.0.1:5080/api/v1/driver-locations/me',
    );
    expect(body['capturedAtUtc'], capturedAt.toIso8601String());
    expect(location.freshness, LocationFreshness.live);
    expect(location.latitude, 9.02);
  });

  test('loads the authorized driver pin for an order', () async {
    final transport = FakeHttpTransport(
      TransportResponse(statusCode: 200, body: jsonEncode(_locationJson())),
    );
    final client = ApiClient(
      transport,
      config: AppConfig(apiOrigin: Uri.parse('http://127.0.0.1:5080')),
    )..accessToken = 'customer-token';
    final service = ApiDriverLocationService(client);

    final location = await service.fetchForOrder('order-id');

    expect(
      transport.lastRequest?.uri.toString(),
      'http://127.0.0.1:5080/api/v1/driver-locations/orders/order-id',
    );
    expect(location?.displayName, 'Demo Driver');
  });
}

Map<String, Object?> _locationJson() => <String, Object?>{
  'driverId': 'driver-id',
  'displayName': 'Demo Driver',
  'freshness': 'Live',
  'latitude': 9.02,
  'longitude': 38.754,
  'accuracyMeters': 6.5,
  'headingDegrees': 68,
  'speedMetersPerSecond': 7.2,
  'capturedAtUtc': '2026-08-31T11:45:00Z',
  'receivedAtUtc': '2026-08-31T11:45:01Z',
};
