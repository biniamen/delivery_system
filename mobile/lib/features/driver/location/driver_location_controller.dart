import 'dart:async';

import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/services/driver_location_service.dart';
import 'package:flutter/foundation.dart';

enum LocationSharingState {
  idle,
  starting,
  sharing,
  serviceDisabled,
  denied,
  deniedForever,
  failed,
}

final class DriverLocationController extends ChangeNotifier {
  DriverLocationController(this._device, this._api);

  final DeviceLocationService _device;
  final DriverLocationService _api;
  StreamSubscription<DevicePosition>? _subscription;
  Timer? _publishTimer;
  bool _publishing = false;
  DevicePosition? _queuedPosition;
  DateTime? _lastPublishedAt;
  LocationSharingState _state = LocationSharingState.idle;
  DriverLocation? _latest;
  String? _errorMessage;

  LocationSharingState get state => _state;
  DriverLocation? get latest => _latest;
  String? get errorMessage => _errorMessage;
  bool get isSharing => _state == LocationSharingState.sharing;

  Future<void> start() async {
    if (_state == LocationSharingState.starting || isSharing) return;
    _state = LocationSharingState.starting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!await _device.isServiceEnabled()) {
        _state = LocationSharingState.serviceDisabled;
        notifyListeners();
        return;
      }

      var permission = await _device.checkPermission();
      if (permission == DeviceLocationPermission.denied) {
        permission = await _device.requestPermission();
      }
      if (permission == DeviceLocationPermission.deniedForever) {
        _state = LocationSharingState.deniedForever;
        notifyListeners();
        return;
      }
      if (permission == DeviceLocationPermission.denied) {
        _state = LocationSharingState.denied;
        notifyListeners();
        return;
      }

      _state = LocationSharingState.sharing;
      notifyListeners();
      _subscription = _device.watch().listen(
        _queuePublish,
        onError: (Object error) {
          _errorMessage = 'Location updates stopped. Check GPS and try again.';
          _state = LocationSharingState.failed;
          notifyListeners();
        },
      );
    } on Object {
      _errorMessage = 'Location could not be started.';
      _state = LocationSharingState.failed;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _publishTimer?.cancel();
    _subscription = null;
    _publishTimer = null;
    _queuedPosition = null;
    _state = LocationSharingState.idle;
    notifyListeners();
  }

  void _queuePublish(DevicePosition position) {
    _queuedPosition = position;
    if (_publishing || _publishTimer?.isActive == true) return;

    final elapsed = _lastPublishedAt == null
        ? const Duration(seconds: 5)
        : DateTime.now().difference(_lastPublishedAt!);
    final wait = const Duration(seconds: 5) - elapsed;
    if (wait > Duration.zero) {
      _publishTimer = Timer(wait, () {
        _publishTimer = null;
        unawaited(_publishQueued());
      });
      return;
    }
    unawaited(_publishQueued());
  }

  Future<void> _publishQueued() async {
    _publishing = true;
    final position = _queuedPosition;
    _queuedPosition = null;
    try {
      if (position != null) _latest = await _api.publish(position);
      _lastPublishedAt = DateTime.now();
      _errorMessage = null;
      notifyListeners();
    } on Object {
      _lastPublishedAt = DateTime.now();
      _errorMessage = 'GPS is active, but the last update was not sent.';
      notifyListeners();
    }
    _publishing = false;
    final queued = _queuedPosition;
    if (queued != null) _queuePublish(queued);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _publishTimer?.cancel();
    super.dispose();
  }
}
