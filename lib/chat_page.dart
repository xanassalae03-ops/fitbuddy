import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'constants.dart';
import 'models.dart';
import 'public_profile_page.dart';
import 'widgets.dart';

/// ห้องแชทของกิจกรรม ใช้ polling ทุก 3 วินาที (after_id ดึงเฉพาะข้อความใหม่)
class ChatPage extends StatefulWidget {
  final int eventId;
  final String title;
  const ChatPage({super.key, required this.eventId, required this.title});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _timer;

  bool _loading = true;
  bool _sending = false;
  bool _polling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final afterId = _messages.isEmpty ? 0 : _messages.last.id;
      final fresh = await ApiService.getChatMessages(
        widget.eventId,
        afterId: afterId,
      );
      if (!mounted) return;
      setState(() {
        _messages.addAll(fresh);
        _loading = false;
        _error = null;
      });
      if (fresh.isNotEmpty) _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      // ถ้ามีข้อความอยู่แล้ว ปล่อยผ่านเงียบๆ แล้วลองใหม่รอบหน้า
      if (_messages.isEmpty) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } finally {
      _polling = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _openPublicProfile(int userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: userId)),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendMessage(widget.eventId, Session.userId, text);
      _ctrl.clear();
      await _poll();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGreen));
    }
    if (_error != null) {
      return Center(
        child: ErrorView(message: _error!, onRetry: _poll),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีข้อความ ทักทายเพื่อนในก๊วนได้เลย',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.senderId == Session.userId;
    final isLocation = m.type == 'LOCATION';

    final body = isLocation
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: mine ? Colors.white : kBlue,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  m.content.isEmpty ? 'แชร์ตำแหน่ง' : m.content,
                  style: TextStyle(color: mine ? Colors.white : kInk),
                ),
              ),
            ],
          )
        : Text(
            m.content,
            style: TextStyle(color: mine ? Colors.white : kInk, height: 1.35),
          );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? kBlue : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: () => _openPublicProfile(m.senderId),
                child: Text(
                  m.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kGreen,
                  ),
                ),
              ),
            ),
          body,
        ],
      ),
    );

    final time = Text(
      m.timeLabel,
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine
            ? [time, const SizedBox(width: 6), bubble]
            : [
                InkWell(
                  onTap: () => _openPublicProfile(m.senderId),
                  customBorder: const CircleBorder(),
                  child: AvatarCircle(
                    url: m.avatarUrl,
                    name: m.senderName,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 8),
                bubble,
                const SizedBox(width: 6),
                time,
              ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'พิมพ์ข้อความ...',
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(backgroundColor: kBlue),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
