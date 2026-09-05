import 'dart:async';

import 'package:creavers_delivery_mobile/core/config/map_config.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/services/address_suggestion_service.dart';
import 'package:creavers_delivery_mobile/core/services/device_location_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

final class DeliveryLocationSelection {
  const DeliveryLocationSelection({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
}

final class DeliveryLocationPickerPage extends StatefulWidget {
  const DeliveryLocationPickerPage({
    required this.addressSuggestionService,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.deviceLocationService,
    super.key,
  });

  final AddressSuggestionService addressSuggestionService;
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;
  final DeviceLocationService? deviceLocationService;

  @override
  State<DeliveryLocationPickerPage> createState() =>
      _DeliveryLocationPickerPageState();
}

final class _DeliveryLocationPickerPageState
    extends State<DeliveryLocationPickerPage> {
  static const _addisAbaba = ll.LatLng(9.0192, 38.7525);
  static final _addisBounds = gm.LatLngBounds(
    southwest: const gm.LatLng(8.7, 38.5),
    northeast: const gm.LatLng(9.3, 39.1),
  );

  final MapController _openMapController = MapController();
  gm.GoogleMapController? _googleMapController;
  ll.LatLng? _selectedPoint;
  String? _formattedAddress;
  bool _locating = false;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = ll.LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _formattedAddress = widget.initialAddress;
    } else if (widget.initialAddress?.trim().isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locateAddress());
    }
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _locateAddress() async {
    final address = widget.initialAddress?.trim();
    if (address == null || address.isEmpty || _resolvingAddress) return;
    setState(() => _resolvingAddress = true);
    try {
      final location = await widget.addressSuggestionService.geocode(address);
      if (location?.hasCoordinates != true || !mounted) return;
      final point = ll.LatLng(location!.latitude!, location.longitude!);
      setState(() {
        _selectedPoint = point;
        _formattedAddress = location.fullAddress;
      });
      await _moveTo(point, 16);
    } on Object {
      if (mounted) {
        _showMessage(
          'Address not found. Tap the exact destination on the map.',
        );
      }
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _selectPoint(ll.LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _formattedAddress = null;
      _resolvingAddress = true;
    });
    try {
      final address = await widget.addressSuggestionService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted && _selectedPoint == point) {
        setState(() => _formattedAddress = address);
      }
    } on Object {
      // Coordinates remain authoritative when a readable address is unavailable.
    } finally {
      if (mounted && _selectedPoint == point) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final service = widget.deviceLocationService;
    if (service == null || _locating) return;
    setState(() => _locating = true);
    try {
      if (!await service.isServiceEnabled()) {
        throw StateError('Turn on location services and try again.');
      }
      var permission = await service.checkPermission();
      if (permission == DeviceLocationPermission.denied) {
        permission = await service.requestPermission();
      }
      if (permission == DeviceLocationPermission.deniedForever) {
        throw StateError(
          'Location permission is blocked. Enable it in device settings.',
        );
      }
      if (permission == DeviceLocationPermission.denied) {
        throw StateError('Location permission was not granted.');
      }

      final DevicePosition position = await service.watch().first.timeout(
        const Duration(seconds: 12),
      );
      final point = ll.LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      await _selectPoint(point);
      await _moveTo(point, 17);
    } on TimeoutException {
      _showMessage(
        'Your location took too long. Tap the destination on the map.',
      );
    } on StateError catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage(
        'Could not read your location. Tap the destination on the map.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _moveTo(ll.LatLng point, double zoom) async {
    if (MapConfig.googleMapsEnabled) {
      await _googleMapController?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(
          gm.LatLng(point.latitude, point.longitude),
          zoom,
        ),
      );
    } else {
      _openMapController.move(point, zoom);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirm() {
    final point = _selectedPoint;
    if (point == null) return;
    Navigator.of(context).pop(
      DeliveryLocationSelection(
        latitude: point.latitude,
        longitude: point.longitude,
        formattedAddress: _formattedAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? _addisAbaba;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery point')),
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _map(initialCenter)),
          Positioned(
            left: 16,
            right: 16,
            top: 14,
            child: _InstructionCard(isResolving: _resolvingAddress),
          ),
          Positioned(
            right: 16,
            bottom: 174,
            child: FloatingActionButton.small(
              heroTag: 'current-location',
              onPressed: widget.deviceLocationService == null || _locating
                  ? null
                  : _useCurrentLocation,
              tooltip: 'Use my current location',
              child: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: _SelectionCard(
                point: _selectedPoint,
                formattedAddress: _formattedAddress,
                resolving: _resolvingAddress,
                onConfirm: _confirm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _map(ll.LatLng initialCenter) {
    if (MapConfig.googleMapsEnabled) {
      final selected = _selectedPoint;
      return gm.GoogleMap(
        mapId: MapConfig.googleMapId == 'DEMO_MAP_ID'
            ? null
            : MapConfig.googleMapId,
        initialCameraPosition: gm.CameraPosition(
          target: gm.LatLng(initialCenter.latitude, initialCenter.longitude),
          zoom: selected == null ? 13 : 16,
        ),
        cameraTargetBounds: gm.CameraTargetBounds(_addisBounds),
        minMaxZoomPreference: const gm.MinMaxZoomPreference(10, 20),
        trafficEnabled: true,
        compassEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) => _googleMapController = controller,
        onTap: (point) =>
            _selectPoint(ll.LatLng(point.latitude, point.longitude)),
        markers: selected == null
            ? const <gm.Marker>{}
            : <gm.Marker>{
                gm.Marker(
                  markerId: const gm.MarkerId('destination'),
                  position: gm.LatLng(selected.latitude, selected.longitude),
                  infoWindow: gm.InfoWindow(
                    title: 'Delivery destination',
                    snippet: _formattedAddress,
                  ),
                ),
              },
      );
    }

    return FlutterMap(
      mapController: _openMapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: _selectedPoint == null ? 13 : 16,
        minZoom: 10,
        maxZoom: 19,
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const ll.LatLng(8.7, 38.5),
            const ll.LatLng(9.3, 39.1),
          ),
        ),
        onTap: (_, point) => _selectPoint(point),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: 'com.creavers.delivery.mobile',
        ),
        if (_selectedPoint case final point?)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: point,
                width: 62,
                height: 62,
                alignment: Alignment.topCenter,
                child: const _DestinationPin(),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: <SourceAttribution>[
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

final class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.isResolving});

  final bool isResolving;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xF7FFFFFF),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x2414273A), blurRadius: 20),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: <Widget>[
          if (isResolving)
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.touch_app_rounded, color: AppTheme.deepTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isResolving
                  ? 'Confirming the readable address…'
                  : 'Tap the exact entrance where the driver should arrive.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.point,
    required this.formattedAddress,
    required this.resolving,
    required this.onConfirm,
  });

  final ll.LatLng? point;
  final String? formattedAddress;
  final bool resolving;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x3014273A),
          blurRadius: 28,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            point == null ? 'No destination selected' : 'Exact destination',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (point != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              formattedAddress ??
                  '${point!.latitude.toStringAsFixed(6)}, ${point!.longitude.toStringAsFixed(6)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: point == null || resolving ? null : onConfirm,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(resolving ? 'Confirming address…' : 'Use this point'),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.location_pin,
    color: Color(0xFFE24D48),
    size: 58,
    shadows: <Shadow>[
      Shadow(color: Color(0x5914273A), blurRadius: 12, offset: Offset(0, 5)),
    ],
  );
}
