import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'constants.dart';

/// แผนที่ขนาดเล็กแสดงหมุดตำแหน่งเดียว (เลื่อน/ซูมไม่ได้) กดแล้วเรียก onTap
/// ใช้ OpenStreetMap ผ่าน flutter_map — ไม่ต้องขอ API Key
class MapPreview extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;
  final VoidCallback? onTap;

  const MapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 160,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = ll.LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            IgnorePointer(
              // ปิดจอยสติ๊กแตะ/ลาก/ซูม เพราะเป็นแค่รูปตัวอย่าง กดเพื่อเปิดหน้าปักหมุดแทน
              child: FlutterMap(
                key: ValueKey('$lat,$lng'),
                options: MapOptions(
                  initialCenter: pos,
                  initialZoom: 16,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fitbuddy.app',
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: pos,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child:
                          const Icon(Icons.location_on, color: kGreen, size: 40),
                    ),
                  ]),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
