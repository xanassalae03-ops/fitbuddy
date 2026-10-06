import 'package:flutter/material.dart';
import 'constants.dart';
import 'create_event_page.dart';
import 'explore_page.dart';
import 'my_events_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late Map<String, dynamic> _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = Map<String, dynamic>.from(widget.user);
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreateEventPage(user: _currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          ExplorePage(user: _currentUser),
          MyEventsPage(user: _currentUser, chatMode: false),
          MyEventsPage(user: _currentUser, chatMode: true),
          ProfilePage(
            user: _currentUser,
            onUserUpdated: (updated) => setState(() => _currentUser = updated),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab > 1 ? _tab + 1 : _tab,
        onTap: (i) {
          if (i == 2) {
            _openCreate();
          } else {
            setState(() => _tab = i > 2 ? i - 1 : i);
          }
        },
        selectedItemColor: kGreenDark,
        unselectedItemColor: kIconMuted,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'ค้นหา'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'กิจกรรม'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: kNavy),
            ),
            label: 'สร้างนัด',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'แชท'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}