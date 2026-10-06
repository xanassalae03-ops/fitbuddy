import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'widgets.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String? name;
  const PickedLocation(this.lat, this.lng, this.name);
}

class _PlaceSuggestion {
  final String name;
  final String type;
  final ll.LatLng position;

  const _PlaceSuggestion({
    required this.name,
    required this.type,
    required this.position,
  });
}

/// หน้าปักหมุดสถานที่ด้วยแผนที่จริง (OpenStreetMap ผ่าน flutter_map — ไม่ใช้ API Key)
///
/// วิธีใช้: "เลื่อนแผนที่ให้หมุดตรงกลางชี้ตำแหน่งที่ต้องการ" (แบบเดียวกับแอปเรียกรถ/
/// ส่งอาหารทั่วไป) หรือค้นหาชื่อสถานที่จากช่องค้นหาด้านบน
class LocationPickerPage extends StatefulWidget {
  /// ตำแหน่งเริ่มต้น ถ้ามี (เช่นเคยปักหมุดไว้แล้ว)
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // ค่าเริ่มต้น: หาดใหญ่ สงขลา (ใช้เมื่อยังไม่เคยปักหมุดมาก่อน)
  static const _fallback = ll.LatLng(7.0084, 100.4767);

  final _searchCtrl = TextEditingController();
  final _mapController = MapController();

  late ll.LatLng _center;
  String? _placeName;
  bool _resolvingName = false;
  bool _searching = false;
  DateTime? _lastSearchAt;
  List<_PlaceSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _center = (widget.initialLat != null && widget.initialLng != null)
        ? ll.LatLng(widget.initialLat!, widget.initialLng!)
        : _fallback;
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(ll.LatLng pos) async {
    setState(() => _resolvingName = true);
    try {
      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      if (places.isNotEmpty) {
        final p = places.first;
        final parts = [
          p.name,
          p.thoroughfare,
          p.subLocality,
          p.locality,
        ].where((s) => s != null && s.trim().isNotEmpty).toSet().toList();
        setState(() => _placeName = parts.isEmpty ? null : parts.join(', '));
      } else {
        setState(() => _placeName = null);
      }
    } catch (_) {
      // ทำไม่ได้ก็ไม่เป็นไร ให้ผู้ใช้พิมพ์ชื่อสถานที่เองในหน้าก่อนหน้าได้
      if (mounted) setState(() => _placeName = null);
    } finally {
      if (mounted) setState(() => _resolvingName = false);
    }
  }

  void _onMapEvent(MapEvent event) {
    // อัปเดตตำแหน่งหมุด (จุดกึ่งกลางจอ) แบบเรียลไทม์ระหว่างลาก
    setState(() => _center = event.camera.center);
    // ค่อย reverse-geocode ตอนหยุดลากแล้ว กันยิง request รัวๆ ระหว่างลาก
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _reverseGeocode(_center);
    }
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      // Public Nominatim permits at most one request per second.
      final previous = _lastSearchAt;
      if (previous != null) {
        final elapsed = DateTime.now().difference(previous);
        if (elapsed < const Duration(seconds: 1)) {
          await Future.delayed(const Duration(seconds: 1) - elapsed);
        }
      }
      _lastSearchAt = DateTime.now();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '5',
        'addressdetails': '1',
        'accept-language': 'th',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'FitBuddy/1.0 (OpenStreetMap search)'},
      );
      if (response.statusCode != 200) {
        throw const FormatException('Place search failed');
      }
      final results = (jsonDecode(response.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => _PlaceSuggestion(
              name: item['display_name'] as String? ?? '',
              type: item['type'] as String? ?? '',
              position: ll.LatLng(
                double.parse(item['lat'] as String),
                double.parse(item['lon'] as String),
              ),
            ),
          )
          .where((item) => item.name.isNotEmpty)
          .toList();
      if (!mounted) return;
      if (results.isEmpty) {
        showSnack(context, 'ไม่พบสถานที่ที่ค้นหา', error: true);
        return;
      }
      setState(() => _suggestions = results);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'ค้นหาสถานที่ไม่สำเร็จ ลองพิมพ์ชื่อให้ชัดเจนขึ้น',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(_center.latitude, _center.longitude, _placeName),
    );
  }

  void _selectSuggestion(_PlaceSuggestion place) {
    _mapController.move(place.position, 16);
    setState(() {
      _center = place.position;
      _placeName = place.name;
      _searchCtrl.text = place.name;
      _suggestions = [];
    });
    _reverseGeocode(place.position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitbuddy.app',
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
          // หมุดคงที่ตรงกึ่งกลางจอ — เลื่อนแผนที่เพื่อ "ปักหมุด" แทนการลากหมุดเอง
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, color: kGreen.withAlpha(230), size: 46),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: kInk),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 2,
                      child: TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาสถานที่...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: _searching
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.search, color: Colors.grey),
                            onPressed: _searching ? null : _search,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 76,
              left: 12,
              right: 12,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined,
                            color: kGreen),
                        title: Text(place.name,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: place.type.isEmpty ? null : Text(place.type),
                        onTap: () => _selectSuggestion(place),
                      );
                    },
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: kGreen, size: 20),
                        const SizedBox(width: 6),
                        const Text('ตำแหน่งที่เลือก',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _resolvingName
                        ? const Text('กำลังค้นหาชื่อสถานที่...',
                            style: TextStyle(color: Colors.grey, fontSize: 13))
                        : Text(
                            _placeName ??
                                '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ใช้ตำแหน่งนี้',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}