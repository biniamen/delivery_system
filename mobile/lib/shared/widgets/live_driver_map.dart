import 'package:creavers_delivery_mobile/core/config/map_config.dart';
import 'package:creavers_delivery_mobile/core/models/driver_location.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

final class LiveDriverMap extends StatefulWidget {
  const LiveDriverMap({
    required this.location,
    this.height = 250,
    this.emptyLabel = 'Waiting for a driver position',
    super.key,
  });

  final DriverLocation? location;
  final double height;
  final String emptyLabel;

  @override
  State<LiveDriverMap> createState() => _LiveDriverMapState();
}

final class _LiveDriverMapState extends State<LiveDriverMap> {
  static const _addisAbaba = LatLng(9.0192, 38.7525);
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant LiveDriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.location;
    if (location?.hasCoordinates == true &&
        (oldWidget.location?.latitude != location?.latitude ||
            oldWidget.location?.longitude != location?.longitude)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_point(location!), 15);
      });
    }
  }

  LatLng _point(DriverLocation location) =>
      LatLng(location.latitude!, location.longitude!);

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final hasPosition = location?.hasCoordinates == true;
    final center = hasPosition ? _point(location!) : _addisAbaba;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 14),
              children: <Widget>[
                TileLayer(
                  urlTemplate: MapConfig.tileUrl,
                  userAgentPackageName: 'com.creavers.delivery.mobile',
                ),
                if (hasPosition)
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: center,
                        width: 58,
                        height: 58,
                        child: const _DriverPin(),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: <SourceAttribution>[
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x1F14273A), blurRadius: 12),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: location?.freshness == LocationFreshness.live
                              ? const Color(0xFF23A66F)
                              : AppTheme.warmGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        hasPosition
                            ? location!.freshness.label
                            : widget.emptyLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
