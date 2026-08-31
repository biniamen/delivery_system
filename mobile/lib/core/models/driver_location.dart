enum LocationFreshness {
  unavailable,
  live,
  recent,
  stale;

  static LocationFreshness fromJson(Object? value) =>
      switch (value?.toString().toLowerCase()) {
        'live' => LocationFreshness.live,
        'recent' => LocationFreshness.recent,
        'stale' => LocationFreshness.stale,
        _ => LocationFreshness.unavailable,
      };

  String get label => switch (this) {
    LocationFreshness.unavailable => 'Waiting',
    LocationFreshness.live => 'Live',
    LocationFreshness.recent => 'Recent',
    LocationFreshness.stale => 'Offline',
  };
}

final class DriverLocation {
  const DriverLocation({
    required this.driverId,
    required this.displayName,
    required this.freshness,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.headingDegrees,
    this.speedMetersPerSecond,
    this.capturedAtUtc,
    this.receivedAtUtc,
  });

  factory DriverLocation.fromJson(Map<String, Object?> json) => DriverLocation(
    driverId: json['driverId']! as String,
    displayName: json['displayName']! as String,
    freshness: LocationFreshness.fromJson(json['freshness']),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
    headingDegrees: (json['headingDegrees'] as num?)?.toDouble(),
    speedMetersPerSecond: (json['speedMetersPerSecond'] as num?)?.toDouble(),
    capturedAtUtc: _date(json['capturedAtUtc']),
    receivedAtUtc: _date(json['receivedAtUtc']),
  );

  final String driverId;
  final String displayName;
  final LocationFreshness freshness;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? headingDegrees;
  final double? speedMetersPerSecond;
  final DateTime? capturedAtUtc;
  final DateTime? receivedAtUtc;

  bool get hasCoordinates => latitude != null && longitude != null;

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value.toString()).toLocal();
}

final class DevicePosition {
  const DevicePosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAtUtc,
    this.headingDegrees,
    this.speedMetersPerSecond,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double? headingDegrees;
  final double? speedMetersPerSecond;
  final DateTime capturedAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'headingDegrees': headingDegrees,
    'speedMetersPerSecond': speedMetersPerSecond,
    'capturedAtUtc': capturedAtUtc.toUtc().toIso8601String(),
  };
}
