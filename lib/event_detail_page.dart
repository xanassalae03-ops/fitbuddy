import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'chat_page.dart';
import 'constants.dart';
import 'event_card.dart';
import 'map_preview.dart';
import 'models.dart';
import 'public_profile_page.dart';
import 'widgets.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventDetail? _detail;
  bool _loading = true;
  bool _joining = false;
  bool _completing = false;
  int? _reviewingUserId;
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
      final d = await ApiService.getEventDetail(
        widget.eventId,
        userId: Session.userId,
      );
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (silent && _detail != null) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ApiService.joinEvent(widget.eventId, Session.userId);
      if (!mounted) return;
      showSnack(context, 'เข้าร่วมกิจกรรมสำเร็จ');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _completeEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันกิจกรรมเสร็จสิ้น'),
        content: const Text(
          'เมื่อยืนยันแล้ว ผู้เข้าร่วมและผู้สร้างจะเริ่มรีวิวกันได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _completing = true);
    try {
      await ApiService.completeEvent(widget.eventId, Session.userId);
      if (!mounted) return;
      showSnack(context, 'ยืนยันกิจกรรมเสร็จสิ้นแล้ว');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _reviewUser(int userId, String displayName) async {
    final review = await showDialog<Map<String, Object>>(
      context: context,
      builder: (_) => _EventReviewDialog(displayName: displayName),
    );
    if (review == null || !mounted) return;

    setState(() => _reviewingUserId = userId);
    try {
      await ApiService.submitEventReview(
        eventId: widget.eventId,
        reviewerId: Session.userId,
        revieweeId: userId,
        rating: review['rating']! as int,
        comment: review['comment']! as String,
      );
      if (!mounted) return;
      showSnack(context, 'บันทึกรีวิวแล้ว');
      await _load(silent: true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _reviewingUserId = null);
    }
  }

  Future<void> _openMaps(EventItem e) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${e.latitude},${e.longitude}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showSnack(context, 'เปิด Google Maps ไม่ได้', error: true);
      }
    } catch (_) {
      if (mounted) showSnack(context, 'เปิด Google Maps ไม่ได้', error: true);
    }
  }

  void _openChat(EventItem e) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(eventId: e.id, title: e.title),
      ),
    );
  }

  void _openPublicProfile(int userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text('รายละเอียดกิจกรรม'),
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : (_error != null && d == null)
          ? Center(
              child: ErrorView(message: _error!, onRetry: _load),
            )
          : _buildContent(d!),
      bottomNavigationBar: d == null ? null : _buildBottomBar(d),
    );
  }

  Widget _buildContent(EventDetail d) {
    final e = d.event;
    final progress = e.maxParticipants > 0
        ? (e.currentParticipants / e.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      color: kGreen,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                EventBanner(event: e, height: 200),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(
                        text: e.statusLabel,
                        bgColor: e.canJoin ? kGreen : kDanger,
                        textColor: Colors.white,
                        showDot: true,
                      ),
                      Pill(
                        text: e.sportName,
                        bgColor: Colors.white.withAlpha(230),
                        textColor: kInk,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            e.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.calendar_today_outlined,
            '${e.dateLabel} • ${e.startTime} - ${e.endTime} น.',
          ),
          _infoRow(
            Icons.location_on_outlined,
            e.locationName.isEmpty ? 'ยังไม่ระบุสถานที่' : e.locationName,
          ),
          _infoRow(Icons.payments_outlined, e.costLabel),
          if (e.hasPin) ...[
            const SizedBox(height: 4),
            MapPreview(
              lat: e.latitude,
              lng: e.longitude,
              height: 180,
              onTap: () => _openMaps(e),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openMaps(e),
              icon: const Icon(Icons.directions),
              label: const Text('นำทางด้วย Google Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBlue,
                side: BorderSide(color: kBlue.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (e.description != null) ...[
            const SizedBox(height: 16),
            const Text(
              'รายละเอียด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(e.description!, style: const TextStyle(height: 1.5)),
          ],
          const SizedBox(height: 20),
          _card(
            child: Row(
              children: [
                InkWell(
                  onTap: () => _openPublicProfile(e.host.id),
                  customBorder: const CircleBorder(),
                  child: AvatarCircle(
                    url: e.host.avatarUrl,
                    name: e.host.displayName,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ผู้จัด',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      InkWell(
                        onTap: () => _openPublicProfile(e.host.id),
                        child: Text(
                          e.host.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: kGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  e.host.trustScore.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ผู้เข้าร่วม',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${e.currentParticipants}/${e.maxParticipants} คน',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: kGreen,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in d.participants)
                      InkWell(
                        onTap: () => _openPublicProfile(p.userId),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AvatarCircle(
                                url: p.avatarUrl,
                                name: p.displayName,
                                radius: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (p.isHost) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _reviewSection(d),
        ],
      ),
    );
  }

  Widget _reviewSection(EventDetail detail) {
    final event = detail.event;
    if (event.status != 'COMPLETED') return const SizedBox.shrink();

    if (!detail.reviewsEnabled) {
      return _card(
        child: const Text(
          'ระบบรีวิวยังไม่พร้อม กรุณาติดต่อผู้ดูแลระบบ',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final isHost = event.host.id == Session.userId;
    final members = detail.participants.where((p) => !p.isHost).toList();
    if (!isHost &&
        !detail.participants.any((p) => p.userId == Session.userId)) {
      return const SizedBox.shrink();
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHost ? 'รีวิวผู้เข้าร่วม' : 'รีวิวผู้สร้างกิจกรรม',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (isHost) ...[
            if (members.isEmpty)
              const Text(
                'กิจกรรมนี้ไม่มีผู้เข้าร่วมให้รีวิว',
                style: TextStyle(color: Colors.grey),
              )
            else
              for (final participant in members) ...[
                if (participant != members.first) const Divider(height: 20),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _openPublicProfile(participant.userId),
                      customBorder: const CircleBorder(),
                      child: AvatarCircle(
                        url: participant.avatarUrl,
                        name: participant.displayName,
                        radius: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openPublicProfile(participant.userId),
                        child: Text(participant.displayName),
                      ),
                    ),
                    _reviewAction(
                      participant.userId,
                      participant.displayName,
                      detail.myReviewRatings[participant.userId],
                    ),
                  ],
                ),
              ],
          ] else ...[
            Row(
              children: [
                InkWell(
                  onTap: () => _openPublicProfile(event.host.id),
                  customBorder: const CircleBorder(),
                  child: AvatarCircle(
                    url: event.host.avatarUrl,
                    name: event.host.displayName,
                    radius: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openPublicProfile(event.host.id),
                    child: Text(event.host.displayName),
                  ),
                ),
                _reviewAction(
                  event.host.id,
                  event.host.displayName,
                  detail.myReviewRatings[event.host.id],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewAction(int userId, String displayName, int? rating) {
    if (rating != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 3),
          Text('$rating/5'),
        ],
      );
    }
    return TextButton.icon(
      onPressed: _reviewingUserId == userId
          ? null
          : () => _reviewUser(userId, displayName),
      icon: const Icon(Icons.star_outline, size: 18),
      label: const Text('ให้คะแนน'),
    );
  }

  Widget _buildBottomBar(EventDetail d) {
    final e = d.event;
    final joined = d.myTicketCode != null;
    final isHost = e.host.id == Session.userId;

    Widget button;
    if (isHost && e.status != 'COMPLETED' && e.status != 'CANCELLED') {
      button = ElevatedButton.icon(
        onPressed: _completing ? null : _completeEvent,
        icon: _completing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: kInk),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(_completing ? 'กำลังบันทึก...' : 'ยืนยันกิจกรรมเสร็จสิ้น'),
        style: _btnStyle(kGreen),
      );
    } else if (joined) {
      button = ElevatedButton.icon(
        onPressed: () => _openChat(e),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('เข้าห้องแชทกิจกรรม'),
        style: _btnStyle(kBlue),
      );
    } else if (e.canJoin) {
      button = ElevatedButton(
        onPressed: _joining ? null : _join,
        style: _btnStyle(kGreen),
        child: _joining
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('เข้าร่วมกิจกรรม'),
      );
    } else {
      button = ElevatedButton(
        onPressed: null,
        style: _btnStyle(Colors.grey),
        child: Text(e.statusLabel),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, height: 50, child: button),
        ),
      ),
    );
  }

  ButtonStyle _btnStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: color == kGreen ? kInk : Colors.white,
    disabledBackgroundColor: Colors.grey.shade300,
    disabledForegroundColor: Colors.grey.shade600,
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kGreen),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _EventReviewDialog extends StatefulWidget {
  final String displayName;

  const _EventReviewDialog({required this.displayName});

  @override
  State<_EventReviewDialog> createState() => _EventReviewDialogState();
}

class _EventReviewDialogState extends State<_EventReviewDialog> {
  final _commentController = TextEditingController();
  var _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('รีวิว ${widget.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ให้คะแนนประสบการณ์ของคุณ'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var value = 1; value <= 5; value++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                ),
            ],
          ),
          TextField(
            controller: _commentController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ความเห็น (ไม่บังคับ)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<Map<String, Object>>(context, {
            'rating': _rating,
            'comment': _commentController.text,
          }),
          child: const Text('ส่งรีวิว'),
        ),
      ],
    );
  }
}
