import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'constants.dart';

class MapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;

  const MapPreview({super.key, required this.lat, required this.lng, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: ll.LatLng(lat, lng),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(
              markers: [
                Marker(
                  point: ll.LatLng(lat, lng),
                  child: const Icon(Icons.location_on, color: kGreen, size: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}