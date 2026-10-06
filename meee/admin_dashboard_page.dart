import 'package:flutter/material.dart';
import 'api_service.dart';
import 'constants.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dashboardFuture = ApiService.getAdminDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_rounded, color: kNavy, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Party Exercise Admin',
                  style: TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'DASHBOARD REAL-TIME DB',
                  style: TextStyle(color: kMuted, fontSize: 10, letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: kError)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadData, child: const Text('ลองใหม่')),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final totalParticipants = data['total_participants'] ?? 0;
          final totalUsers = data['total_users'] ?? 0;
          final activeRecent = data['active_recent_users'] ?? 0;
          final monthlyEvents = data['monthly_events'] ?? 0;
          final completedEvents = data['completed_events'] ?? 0;
          final upcomingEvents = data['upcoming_events'] ?? 0;
          final topSport = data['top_sport'] ?? '-';
          final topSportUsers = data['top_sport_users'] ?? 0;

          final List categories = data['categories'] ?? [];
          final List upcomingRadar = data['upcoming_radar'] ?? [];
          final List recentEvents = data['recent_events'] ?? [];

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DASHBOARD OVERVIEW',
                    style: TextStyle(color: kGreenDark, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'สรุปภาพรวมระบบกีฬา (จาก DB)',
                    style: TextStyle(color: kNavy, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _statCard(
                        icon: Icons.group_outlined,
                        title: 'ผู้เข้าร่วมทั้งหมด',
                        value: '$totalParticipants',
                        unit: 'คน',
                        subText: 'อนุมัติเข้าร่วมแล้ว',
                        progress: 1.0,
                      ),
                      _statCard(
                        icon: Icons.directions_run_outlined,
                        title: 'ผู้ใช้งานในระบบ',
                        value: '$totalUsers',
                        unit: 'คน',
                        subText: 'ใหม่ 30 วัน: $activeRecent คน',
                        progress: totalUsers > 0 ? activeRecent / totalUsers : 0,
                      ),
                      _statCard(
                        icon: Icons.flag_outlined,
                        title: 'กิจกรรมเดือนนี้',
                        value: '$monthlyEvents',
                        unit: 'Events',
                        subText: 'จบแล้ว $completedEvents (รอแข่ง $upcomingEvents)',
                        progress: monthlyEvents > 0 ? completedEvents / monthlyEvents : 0,
                      ),
                      _statCard(
                        icon: Icons.sports_soccer_outlined,
                        title: 'ฮิตติดเทรนด์สุด',
                        value: topSport,
                        unit: '',
                        subText: 'รวมผู้เล่น $topSportUsers คน',
                        progress: 1.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildCategoryRatioCard(categories, totalParticipants),
                  const SizedBox(height: 20),

                  _buildStartingSoonSection(upcomingRadar),
                  const SizedBox(height: 20),

                  _buildRecentEventsSection(recentEvents),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String subText,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: kNavy, size: 18),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: kMuted, fontSize: 11)),
          Text('$value $unit', style: const TextStyle(color: kNavy, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE2E8F0),
            color: kGreen,
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(subText, style: const TextStyle(color: kMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildCategoryRatioCard(List categories, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สัดส่วนประเภทกีฬาใน DB', style: TextStyle(color: kNavy, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (var c in categories) ...[
            _categoryRow(c['name'] ?? '', c['count'] ?? 0, total),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _categoryRow(String name, int count, int total) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, color: kNavy)),
            Text('$count คน (${(ratio * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(value: ratio, color: kGreen, backgroundColor: const Color(0xFFF1F5F9), minHeight: 4),
      ],
    );
  }

  Widget _buildStartingSoonSection(List events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('เรดาร์ด่วนกิจกรรมใกล้เริ่ม (DB)', style: TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (events.isEmpty) const Text('ไม่มีกิจกรรมเร็วๆ นี้', style: TextStyle(color: kMuted)),
        for (var e in events)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
                    Text('${e['event_date']} • ${e['location_name']}', style: const TextStyle(color: kMuted, fontSize: 11)),
                  ],
                ),
                Text('${e['current_participants']}/${e['max_participants']} คน', style: const TextStyle(color: kGreenDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentEventsSection(List events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('จัดการอีเวนต์ล่าสุดในระบบ', style: TextStyle(color: kNavy, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var e in events)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: kPanel, child: Icon(Icons.sports, color: kNavy, size: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kNavy)),
                      Text('${e['location_name']}', style: const TextStyle(color: kMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text(e['status'] ?? '', style: const TextStyle(color: kGreenDark, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }
}