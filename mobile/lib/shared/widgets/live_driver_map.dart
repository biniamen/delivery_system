import 'package:creavers_delivery_mobile/core/config/map_config.dart';
import 'package:creavers_delivery_mobile/core/models/delivery_route.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

final class LiveDriverMap extends StatefulWidget {
  const LiveDriverMap({
    required this.location,
    this.destinationLatitude,
    this.destinationLongitude,
    this.route,
    this.height = 250,
    this.emptyLabel = 'Waiting for a driver position',
    super.key,
  });

  final DriverLocation? location;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final DeliveryRoute? route;
  final double height;
  final String emptyLabel;

  @override
  State<LiveDriverMap> createState() => _LiveDriverMapState();
}

final class _LiveDriverMapState extends State<LiveDriverMap> {
  static const _addisAbaba = ll.LatLng(9.0192, 38.7525);
  final MapController _openMapController = MapController();
  gm.GoogleMapController? _googleMapController;

  @override
  void didUpdateWidget(covariant LiveDriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final locationChanged =
        oldWidget.location?.latitude != widget.location?.latitude ||
        oldWidget.location?.longitude != widget.location?.longitude;
    final routeChanged =
        oldWidget.route?.calculatedAtUtc != widget.route?.calculatedAtUtc;
    if (locationChanged || routeChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
    }
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  ll.LatLng _driverPoint(DriverLocation location) =>
      ll.LatLng(location.latitude!, location.longitude!);

  ll.LatLng? get _destinationPoint {
    final latitude = widget.destinationLatitude;
    final longitude = widget.destinationLongitude;
    return latitude == null || longitude == null
        ? null
        : ll.LatLng(latitude, longitude);
  }

  List<ll.LatLng> get _routePoints =>
      widget.route?.path
          .map((point) => ll.LatLng(point.latitude, point.longitude))
          .toList(growable: false) ??
      const <ll.LatLng>[];

  List<ll.LatLng> get _visiblePoints {
    final points = <ll.LatLng>[..._routePoints];
    final location = widget.location;
    if (location?.hasCoordinates == true) points.add(_driverPoint(location!));
    if (_destinationPoint case final destination?) points.add(destination);
    return points;
  }

  Future<void> _fitMap() async {
    if (!mounted) return;
    final points = _visiblePoints;
    if (points.isEmpty) return;
    if (MapConfig.googleMapsEnabled) {
      final controller = _googleMapController;
      if (controller == null) return;
      if (points.length == 1) {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngZoom(_googlePoint(points.first), 15),
        );
        return;
      }
      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;
      for (final point in points.skip(1)) {
        minLat = point.latitude < minLat ? point.latitude : minLat;
        maxLat = point.latitude > maxLat ? point.latitude : maxLat;
        minLng = point.longitude < minLng ? point.longitude : minLng;
        maxLng = point.longitude > maxLng ? point.longitude : maxLng;
      }
      if (minLat == maxLat || minLng == maxLng) {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngZoom(_googlePoint(points.first), 15),
        );
      } else {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngBounds(
            gm.LatLngBounds(
              southwest: gm.LatLng(minLat, minLng),
              northeast: gm.LatLng(maxLat, maxLng),
            ),
            54,
          ),
        );
      }
    } else if (points.length == 1) {
      _openMapController.move(points.first, 15);
    } else {
      _openMapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(48),
        ),
      );
    }
  }

  gm.LatLng _googlePoint(ll.LatLng point) =>
      gm.LatLng(point.latitude, point.longitude);

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final hasPosition = location?.hasCoordinates == true;
    final center = hasPosition ? _driverPoint(location!) : _addisAbaba;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: MapConfig.googleMapsEnabled
                  ? _googleMap(center)
                  : _openMap(center),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _LiveBadge(
                label: hasPosition
                    ? location!.freshness.label
                    : widget.emptyLabel,
                live: location?.freshness == LocationFreshness.live,
              ),
            ),
            if (widget.route case final route?)
              Positioned(
                right: 12,
                bottom: 12,
                child: _RouteBadge(route: route),
              ),
          ],
        ),
      ),
    );
  }

  Widget _googleMap(ll.LatLng center) {
    final location = widget.location;
    final destination = _destinationPoint;
    final routePoints = _routePoints;
    return gm.GoogleMap(
      mapId: MapConfig.googleMapId == 'DEMO_MAP_ID'
          ? null
          : MapConfig.googleMapId,
      initialCameraPosition: gm.CameraPosition(
        target: _googlePoint(center),
        zoom: 14,
      ),
      trafficEnabled: true,
      compassEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _googleMapController = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
      },
      markers: <gm.Marker>{
        if (location?.hasCoordinates == true)
          gm.Marker(
            markerId: const gm.MarkerId('driver'),
            position: gm.LatLng(location!.latitude!, location.longitude!),
            rotation: location.headingDegrees ?? 0,
            flat: true,
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueCyan,
            ),
            infoWindow: gm.InfoWindow(
              title: location.displayName,
              snippet: location.freshness.label,
            ),
          ),
        if (destination != null)
          gm.Marker(
            markerId: const gm.MarkerId('destination'),
            position: _googlePoint(destination),
            infoWindow: const gm.InfoWindow(title: 'Customer destination'),
          ),
      },
      polylines: routePoints.length < 2
          ? const <gm.Polyline>{}
          : <gm.Polyline>{
              gm.Polyline(
                polylineId: const gm.PolylineId('delivery-route'),
                points: routePoints.map(_googlePoint).toList(growable: false),
                width: 6,
                color: AppTheme.deepTeal,
                geodesic: true,
              ),
            },
    );
  }

  Widget _openMap(ll.LatLng center) {
    final location = widget.location;
    final destination = _destinationPoint;
    final routePoints = _routePoints;
    return FlutterMap(
      mapController: _openMapController,
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: <Widget>[
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: 'com.creavers.delivery.mobile',
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: routePoints,
                strokeWidth: 6,
                color: AppTheme.deepTeal,
              ),
            ],
          ),
        MarkerLayer(
          markers: <Marker>[
            if (location?.hasCoordinates == true)
              Marker(
                point: _driverPoint(location!),
                width: 58,
                height: 58,
                child: const _DriverPin(),
              ),
            if (destination != null)
              Marker(
                point: destination,
                width: 50,
                height: 50,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  color: Color(0xFFE24D48),
                  size: 48,
                ),
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

final class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label, required this.live});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x1F14273A), blurRadius: 12),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: live ? const Color(0xFF23A66F) : AppTheme.warmGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

final class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.route});

  final DeliveryRoute route;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.deepTeal,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x3014273A), blurRadius: 14),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      child: Text(
        '${route.durationText} · ${route.distanceText}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

final class _DriverPin extends StatelessWidget {
  const _DriverPin();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.deepTeal,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D14273A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const SizedBox.square(
        dimension: 44,
        child: Icon(
          Icons.local_shipping_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    ),
  );
}
