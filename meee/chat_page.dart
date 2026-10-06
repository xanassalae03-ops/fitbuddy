import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'models.dart';

class ChatPage extends StatefulWidget {
  final int eventId;
  final String title;
  final Map<String, dynamic> currentUser;

  const ChatPage({super.key, required this.eventId, required this.title, required this.currentUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  Timer? _timer;

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
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final afterId = _messages.isEmpty ? 0 : _messages.last.id;
      final fresh = await ApiService.getChatMessages(widget.eventId, afterId: afterId);
      if (mounted && fresh.isNotEmpty) setState(() => _messages.addAll(fresh));
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ApiService.sendMessage(widget.eventId, userIdOf(widget.currentUser), text);
      _ctrl.clear();
      _poll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: buildAppBar(widget.title),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final mine = m.senderId == userIdOf(widget.currentUser);
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mine ? kGreen : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.content, style: const TextStyle(color: kNavy)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'))),
                IconButton(icon: const Icon(Icons.send, color: kGreenDark), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}