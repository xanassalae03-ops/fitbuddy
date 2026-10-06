import 'package:flutter/material.dart';

import 'constants.dart';
import 'create_event_page.dart';
import 'explore_page.dart';
import 'my_events_page.dart';
import 'profile_page.dart';

/// หน้าหลักหลังล็อกอิน: มี bottom nav 5 ปุ่ม
/// 0 ค้นหา | 1 กิจกรรมของฉัน | 2 สร้างนัด (เปิดหน้าใหม่) | 3 แชท | 4 โปรไฟล์
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _navIndex = 0;

  // เปลี่ยนค่าเพื่อสร้างหน้านั้นใหม่ (โหลดข้อมูลใหม่)
  int _exploreTick = 0;
  int _myTick = 0;

  // nav index -> index ใน IndexedStack
  static const _stackIndexOf = [0, 1, 0, 2, 3];

  Future<void> _openCreate() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateEventPage()));
    if (ok == true && mounted) {
      setState(() {
        _exploreTick++;
        _myTick++;
        _navIndex = 1;
      });
    }
  }

  void _onTap(int i) {
    if (i == 2) {
      _openCreate();
      return;
    }
    setState(() {
      _navIndex = i;
      if (i == 0) _exploreTick++;
      if (i == 1 || i == 3) _myTick++; // เข้าแท็บที่ต้องรีเฟรชข้อมูลเสมอ
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: IndexedStack(
        index: _stackIndexOf[_navIndex],
        children: [
          ExplorePage(refreshToken: _exploreTick),
          MyEventsPage(key: ValueKey('my$_myTick')),
          MyEventsPage(chatMode: true, key: ValueKey('chat$_myTick')),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: kGreen,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'ค้นหากิจกรรม',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'กิจกรรมของฉัน',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              label: 'สร้างนัด',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'แชท',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      ),
    );
  }
}
