import 'package:flutter/material.dart';

import 'api_service.dart';
import 'chat_page.dart';
import 'constants.dart';
import 'event_card.dart';
import 'event_detail_page.dart';
import 'models.dart';
import 'widgets.dart';

/// ใช้ได้สองโหมด
///  - chatMode = false : แท็บ "กิจกรรมของฉัน" (การ์ดเต็ม กดแล้วเข้าหน้ารายละเอียด)
///  - chatMode = true  : แท็บ "แชท" (รายการห้องแชท กดแล้วเข้าห้อง)
class MyEventsPage extends StatefulWidget {
  final bool chatMode;
  const MyEventsPage({super.key, this.chatMode = false});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List<EventItem> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final evs = await ApiService.getMyEvents(Session.userId);
      if (!mounted) return;
      setState(() {
        _events = evs;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _open(EventItem e) async {
    if (widget.chatMode) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(eventId: e.id, title: e.title),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: e.id)),
      );
      if (mounted) _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chatMode ? 'แชทกิจกรรม' : 'กิจกรรมของฉัน';
    final emptyText = widget.chatMode
        ? 'ยังไม่มีห้องแชท\nเข้าร่วมกิจกรรมเพื่อเริ่มคุยกับเพื่อนในก๊วน'
        : 'คุณยังไม่ได้เข้าร่วมหรือสร้างกิจกรรมใดเลย';

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: RefreshIndicator(
          color: kGreen,
          onRefresh: () => _load(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: kGreen),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: ErrorView(message: _error!, onRetry: _load),
                )
              else if (_events.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 24),
                    child: Center(
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: widget.chatMode
                            ? _chatTile(_events[i])
                            : EventCard(
                                event: _events[i],
                                showRole: true,
                                onTap: () => _open(_events[i]),
                              ),
                      ),
                      childCount: _events.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatTile(EventItem e) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kInk,
                child: Icon(e.icon, color: kLime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.dateLabel} • ${e.currentParticipants} คน',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
