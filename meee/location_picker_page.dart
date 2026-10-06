import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'app_theme.dart';
import 'constants.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String? name;
  const PickedLocation(this.lat, this.lng, this.name);
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  ll.LatLng _center = const ll.LatLng(7.0084, 100.4767);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('ปักหมุดสถานที่'),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (pos, _) {
                _center = pos.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitbuddy.app',
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_on, color: kError, size: 40),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: AuthPrimaryButton(
              label: 'ใช้ตำแหน่งนี้',
              onPressed: () => Navigator.pop(
                context,
                PickedLocation(_center.latitude, _center.longitude, 'สถานที่เลือก'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}