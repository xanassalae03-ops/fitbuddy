import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'chat_page.dart';
import 'constants.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'models.dart';

class MyEventsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool chatMode;

  const MyEventsPage({super.key, required this.user, this.chatMode = false});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List<EventItem> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final evs = await ApiService.getMyEvents(userIdOf(widget.user));
      if (mounted) setState(() { _events = evs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chatMode ? 'แชทกิจกรรม' : 'กิจกรรมของฉัน';

    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(title),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final e = _events[i];
                if (widget.chatMode) {
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: CircleAvatar(backgroundColor: kMint, child: Icon(e.icon, color: kGreenDark)),
                    title: Text(e.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.eventDate} • ${e.currentParticipants} คน'),
                    trailing: const Icon(Icons.chevron_right, color: kIconMuted),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatPage(eventId: e.id, title: e.title, currentUser: widget.user)),
                    ),
                  );
                }
                return EventCard(
                  event: e,
                  showRole: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailPage(eventId: e.id, currentUser: widget.user)),
                  ),
                );
              },
            ),
    );
  }
}