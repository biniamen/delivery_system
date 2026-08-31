import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:geolocator/geolocator.dart';

enum DeviceLocationPermission { denied, deniedForever, whileInUse, always }

abstract interface class DeviceLocationService {
  Future<bool> isServiceEnabled();

  Future<DeviceLocationPermission> checkPermission();

  Future<DeviceLocationPermission> requestPermission();

  Stream<DevicePosition> watch();
}

final class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<DeviceLocationPermission> checkPermission() async =>
      _mapPermission(await Geolocator.checkPermission());

  @override
  Future<DeviceLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  @override
  Stream<DevicePosition> watch() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).map(
        (position) => DevicePosition(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy.clamp(0, 2000).toDouble(),
          headingDegrees: position.heading >= 0 && position.heading < 360
              ? position.heading
              : null,
          speedMetersPerSecond: position.speed >= 0 && position.speed <= 100
              ? position.speed
              : null,
          capturedAtUtc: position.timestamp.toUtc(),
        ),
      );

  DeviceLocationPermission _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always => DeviceLocationPermission.always,
        LocationPermission.whileInUse => DeviceLocationPermission.whileInUse,
        LocationPermission.deniedForever =>
          DeviceLocationPermission.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => DeviceLocationPermission.denied,
      };
}
