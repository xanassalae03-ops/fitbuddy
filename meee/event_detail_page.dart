import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'models.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
  final Map<String, dynamic> currentUser;

  const EventDetailPage({super.key, required this.eventId, required this.currentUser});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiService.getEventDetail(widget.eventId, userId: userIdOf(widget.currentUser));
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar('รายละเอียดกิจกรรม'),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(d.event.title, style: const TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${d.event.eventDate} • ${d.event.locationName}', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 16),
                AuthCard(
                  child: Row(
                    children: [
                      UserAvatar(url: d.event.host.avatar, size: 48),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.event.host.displayName, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
                          Text('Trust Score: ${d.event.host.trustScore}', style: const TextStyle(color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}