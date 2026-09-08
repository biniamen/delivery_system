final class RoutePoint {
  const RoutePoint({required this.latitude, required this.longitude});

  factory RoutePoint.fromJson(Map<String, Object?> json) => RoutePoint(
    latitude: (json['latitude']! as num).toDouble(),
    longitude: (json['longitude']! as num).toDouble(),
  );

  final double latitude;
  final double longitude;
}

final class DeliveryRoute {
  const DeliveryRoute({
    required this.orderId,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
    required this.path,
    required this.provider,
    required this.calculatedAtUtc,
  });

  factory DeliveryRoute.fromJson(Map<String, Object?> json) => DeliveryRoute(
    orderId: json['orderId']! as String,
    originLatitude: (json['originLatitude']! as num).toDouble(),
    originLongitude: (json['originLongitude']! as num).toDouble(),
    destinationLatitude: (json['destinationLatitude']! as num).toDouble(),
    destinationLongitude: (json['destinationLongitude']! as num).toDouble(),
    distanceMeters: json['distanceMeters']! as int,
    durationSeconds: json['durationSeconds']! as int,
    distanceText: json['distanceText']! as String,
    durationText: json['durationText']! as String,
    path: (json['path']! as List<Object?>)
        .whereType<Map<String, Object?>>()
        .map(RoutePoint.fromJson)
        .toList(growable: false),
    provider: json['provider']! as String,
    calculatedAtUtc: DateTime.parse(json['calculatedAtUtc']! as String)
        .toLocal(),
  );

  final String orderId;
  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final int distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;
  final List<RoutePoint> path;
  final String provider;
  final DateTime calculatedAtUtc;
}
